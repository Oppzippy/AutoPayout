---@type string
local addonName = ...
---@class addon
local addon = select(2, ...)

local AceAddon = LibStub("AceAddon-3.0")
local AceLocale = LibStub("AceLocale-3.0")
local AceDB = LibStub("AceDB-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceGUI = LibStub("AceGUI-3.0")

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

function Core:Show()
	local frame = AceGUI:Create("Frame")
	---@cast frame AceGUIFrame
	self.frame = frame
	frame:SetCallback("OnHide", function()
		frame:Release()
		self.frame = nil
	end)
	frame:SetTitle(L.addon_name)
	frame:SetLayout("Fill")

	local tabGroup = AceGUI:Create("TabGroup")
	---@cast tabGroup AceGUITabGroup
	tabGroup:SetLayout("Fill")
	self.tabGroup = tabGroup
	frame:AddChild(tabGroup)

	tabGroup:SetCallback("OnGroupSelected", function(_, _, tab)
		tabGroup:ReleaseChildren()
		self:DisplayTab(tab)
	end)

	tabGroup:SetTabs({
		{
			text = L.payout_setup,
			value = "payout-setup",
		},
		{
			text = L.payout_history,
			value = "payout-history",
		},
	})

	tabGroup:SelectTab("payout-setup")
end

---@param tab "payout-setup" | "payout-history"
function Core:DisplayTab(tab)
	self.tabGroup:ReleaseChildren()
	if tab == "payout-setup" then
		if not self.payoutQueue then
			local frame = self.payoutSetupFrame:Show()
			self.tabGroup:AddChild(frame)
			frame:DoLayout()
		else
			local frame = self.payoutProgressFrame:Show(self.payoutQueue)
			self.tabGroup:AddChild(frame)
			frame:DoLayout()
		end
	elseif tab == "payout-history" then
		self.historyFrame = addon.HistoryFramePrototype.Create()
		local frame = self.historyFrame:Show(self.db.profile.history)
		self.tabGroup:AddChild(frame)
		frame:DoLayout()
		self.historyFrame.RegisterCallback(self, "OnClose", "OnHistoryFrameClose")
	end
end

function Core:ResetState()
	if self.payoutExecutor then
		self.payoutExecutor:Destroy()
		self.payoutExecutor = nil
	end
	self.payoutQueue = nil
	self:CreatePayoutSetupFrame()
	self.payoutProgressFrame = nil
end

function Core:CreatePayoutSetupFrame()
	self.payoutSetupFrame = addon.PayoutSetupFramePrototype.Create()
	self.payoutSetupFrame.RegisterCallback(self, "OnStartPayout", "OnShowPayoutProgressFrame")
	self.payoutSetupFrame.RegisterCallback(self, "OnStatusMessage")
end

function Core:CreatePayoutProgressFrame()
	self.payoutProgressFrame = addon.PayoutProgressFramePrototype.Create()
	self.payoutProgressFrame.RegisterCallback(self, "DoStartPayout", "StartPayout")
	self.payoutProgressFrame.RegisterCallback(self, "OnDone", "OnPayoutProgressFrameDone")
	self.payoutProgressFrame.RegisterCallback(self, "OnStatusMessage")
end

function Core:OnStatusMessage(_, text)
	if self.frame then
		self.frame:SetStatusText(text)
	end
end

function Core:OnPayoutProgressFrameDone()
	if self.payoutExecutor then
		self.payoutExecutor:Halt()
	end
	-- Make sure any pending mail gets sent before resetting everything so they are included in history
	if not self.doneTicker then
		self.doneTicker = C_Timer.NewTicker(0, function()
			if not C_Mail.IsCommandPending() then
				-- The entry was created already and inserted at the front of the table
				self.db.profile.history[1].output = self.payoutProgressFrame:GetUnpaidCSV()
				self:ResetState()

				self:DisplayTab("payout-setup")
				self.doneTicker:Cancel()
				self.doneTicker = nil
			end
		end)
	end
end

function Core:WipeOldHistory()
	local maxHistorySize = self.db.profile.maxHistorySize
	local history = self.db.profile.history
	for i = maxHistorySize + 1, #history do
		history[i] = nil
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
		self:Show()
	end
end

function Core:OnHistoryFrameClose()
	self.historyFrame = nil
end

---@param _ any
---@param frame PayoutSetupFrame
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

	self:DisplayTab("payout-setup") -- Refresh display

	local csv = frame:GetCSV()
	local historyRecord = {
		timestamp = GetServerTime(),
		unit = frame:GetUnit(),
		sender = {
			name = UnitName("player"),
			realm = GetRealmName(),
		},
		input = csv,
		output = csv,
	}
	self:WipeOldHistory()
	table.insert(self.db.profile.history, 1, historyRecord)
end

function Core:SplitPayments(payments)
	local payoutSplitter = addon.PayoutSplitterPrototype.Create(
		self.db.profile.maxPayoutSizeInGold * COPPER_PER_GOLD,
		self.db.profile.maxPayoutSplits
	)
	return payoutSplitter:SplitPayments(payments)
end

function Core:StartPayout()
	-- don't allow restarting the payout when we're trying to stop it
	if self.doneTicker then return end
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
	-- The entry was created already and inserted at the front of the table
	self.payoutProgressFrame:UpdateUnpaidCSV()
	self.db.profile.history[1].output = self.payoutProgressFrame:GetUnpaidCSV()
end

function Core:OnMailFailed(_, _, payout)
	self.payoutProgressFrame:MarkUnpaid(payout)
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
