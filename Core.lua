---@type string
local addonName = ...
---@class addon
local addon = select(2, ...)

local AceAddon = LibStub("AceAddon-3.0")
local AceLocale = LibStub("AceLocale-3.0")
local AceDB = LibStub("AceDB-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local L = AceLocale:GetLocale(addonName)
addon.L = L

---@class Core: AceAddon, AceConsole-3.0, EventHandler
local Core = AceAddon:NewAddon(addonName, "AceConsole-3.0")
addon.core = Core

---@param recipient string
---@param subject string
---@param body string
hooksecurefunc("SendMail", function(recipient, subject, body)
	if Core.payoutExecutor then
		local nextMail = Core.payoutExecutor:GetNextMail()
		if not nextMail or recipient ~= nextMail.player or subject ~= nextMail.subject or body ~= "" then
			Core.payoutExecutor:Destroy()
			Core.payoutExecutor = nil
		end
	end
end)

function Core:OnInitialize()
	self.db = AceDB:New("AutoPayoutDB", addon.dbDefaults, true)
	AceConfig:RegisterOptionsTable(addonName, addon.options)
	AceConfigDialog:AddToBlizOptions(addonName, L.addon_name)
	self:RegisterChatCommand("payout", "SlashPayout")
	self:ResetState()
	addon.EventHandler.Embed(self)
	self:RegisterEvent("MAIL_SHOW")
end

function Core:ResetState()
	if self.payoutExecutor then
		self.payoutExecutor:Destroy()
		self.payoutExecutor = nil
	end
	self.payoutQueue = nil
	self.historyRecord = nil
	if self.payoutSetupFrame then self.payoutSetupFrame:Hide() end
	if self.payoutProgressFrame then self.payoutProgressFrame:Hide() end
	self:CreatePayoutSetupFrame()
	self.payoutProgressFrame = nil
end

function Core:CreatePayoutSetupFrame()
	self.payoutSetupFrame = addon.PayoutSetupFramePrototype.Create()
	self.payoutSetupFrame.RegisterCallback(self, "OnStartPayout", "OnShowPayoutProgressFrame")
end

function Core:CreatePayoutProgressFrame()
	self.payoutProgressFrame = addon.PayoutProgressFramePrototype.Create()
	self.payoutProgressFrame.RegisterCallback(self, "DoStartPayout", "StartPayout")
	self.payoutProgressFrame.RegisterCallback(self, "OnDone", "OnPayoutProgressFrameDone")
end

function Core:OnPayoutProgressFrameDone()
	self.historyRecord.output = self.payoutProgressFrame:GetUnpaidCSV()
	table.insert(self.db.profile.history, 1, self.historyRecord)
	self:WipeOldHistory()
	self:ResetState()
end

function Core:WipeOldHistory()
	local maxHistorySize = self.db.profile.maxHistorySize
	local history = self.db.profile.history
	if #history > maxHistorySize then
		for i = maxHistorySize + 1, #history do
			history[i] = nil
		end
	end
end

function Core:Debug(...)
	if self.db.profile.debug then
		self:Print(...)
	end
end

function Core:Debugf(...)
	if self.db.profile.debug then
		self:Printf(...)
	end
end

function Core:MAIL_SHOW()
	if not self.db.profile.autoShow then return end
	if not self.payoutQueue and not self.payoutSetupFrame:IsVisible() then
		self.payoutSetupFrame:Show()
	elseif self.payoutProgressFrame and not self.payoutProgressFrame:IsVisible() then
		self.payoutProgressFrame:Show(self.payoutQueue)
	end
end

---@param args string
function Core:SlashPayout(args)
	if args == "" then
		if not self.payoutQueue then
			if self.payoutSetupFrame:IsVisible() then
				self.payoutSetupFrame:Hide()
			else
				self.payoutSetupFrame:Show()
			end
		else
			if self.payoutProgressFrame:IsVisible() then
				self.payoutProgressFrame:Hide()
			else
				self.payoutProgressFrame:Show(self.payoutQueue)
			end
		end
	elseif args == "history" then
		if not self.historyFrame then
			self.historyFrame = addon.HistoryFramePrototype.Create()
			self.historyFrame:Show(self.db.profile.history)
			self.historyFrame.RegisterCallback(self, "OnClose", "OnHistoryFrameClose")
		else
			self.historyFrame:Hide()
			self.historyFrame = nil
		end
	end
end

function Core:OnHistoryFrameClose()
	self.historyFrame = nil
end

function Core:ShowSetupPayoutFrame()
	self.payoutSetupFrame:Show()
end

function Core:HideSetupPayoutFrame()
	self.payoutSetupFrame:Hide()
end

function Core:OnShowPayoutProgressFrame(_, frame)
	local payments = self:SplitPayments(frame:GetPayments())
	local success, err = pcall(function()
		self.payoutQueue = addon.PayoutQueuePrototype.Create(payments, frame:GetSubject())
	end)
	if not success then self:Printf("Error parsing payments: %s", err) end
	self.payoutSetupFrame = nil
	self:CreatePayoutProgressFrame()
	self.payoutProgressFrame:SetUnit(frame:GetUnit())
	self.payoutProgressFrame:Show(self.payoutQueue)
	self.payoutProgressFrame.RegisterCallback(self, "DoStopPayout", "StopPayout")

	self.historyRecord = {
		timestamp = GetServerTime(),
		unit = frame:GetUnit(),
		sender = {
			name = UnitName("player"),
			realm = GetRealmName(),
		},
		input = frame:GetCSV(),
	}
end

function Core:SplitPayments(payments)
	local payoutSplitter = addon.PayoutSplitterPrototype.Create(
		self.db.profile.maxPayoutSizeInGold * COPPER_PER_GOLD,
		self.db.profile.maxPayoutSplits
	)
	return payoutSplitter:SplitPayments(payments)
end

function Core:ShowInProgressPayout(_, frame)
	if self.payoutQueue then
		self.payoutProgressFrame:Show(self.payoutQueue)
	else
		error("Tried to resume nil payout queue")
	end
end

function Core:StartPayout()
	if not self.payoutQueue then error("Tried to start payout with no payout queue") end
	if not self.payoutExecutor then
		self.payoutExecutor = addon.PayoutExecutorPrototype.Create(self.payoutQueue)
		self.payoutExecutor.RegisterCallback(self, "OnMailSent")
		self.payoutExecutor.RegisterCallback(self, "OnMailFailed")
		self.payoutExecutor.RegisterCallback(self, "OnStopPayout")
	end
	self.payoutExecutor:Start()
end

function Core:StopPayout()
	if self.payoutExecutor then
		self.payoutExecutor:Stop()
	end
end

function Core:OnStopPayout()
	if self.payoutProgressFrame then
		self.payoutProgressFrame:SetStartButtonState(false)
		self.payoutProgressFrame:UpdateUnpaidCSV()
	end
end

function Core:OnMailSent(_, _, payout)
	self.payoutProgressFrame:MarkPaid(payout)
end

function Core:OnMailFailed(_, _, payout)
	self.payoutProgressFrame:MarkUnpaid(payout)
end
