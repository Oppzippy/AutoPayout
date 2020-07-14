local _, addon = ...

local AceAddon = LibStub("AceAddon-3.0")
local AceLocale = LibStub("AceLocale-3.0")
local AceDB = LibStub("AceDB-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local L = AceLocale:GetLocale("HuokanPayout")
addon.L = L

local Core = AceAddon:NewAddon("HuokanPayout", "AceConsole-3.0")
addon.core = Core

function Core:OnInitialize()
	self.db = AceDB:New("HuokanPayoutDB", addon.dbDefaults, true)
	AceConfig:RegisterOptionsTable("HuokanPayout", addon.options)
	AceConfigDialog:AddToBlizOptions("HuokanPayout", L.addon_name)
	self:RegisterChatCommand("payout", "SlashPayout")
	self:ResetState()
end

function Core:ResetState()
	self:StopPayout()
	self.payoutQueue = nil
	if self.payoutSetupFrame then self.payoutSetupFrame:Hide() end
	if self.payoutProgressFrame then self.payoutProgressFrame:Hide() end

	self.payoutSetupFrame = addon.PayoutSetupFrame.Create()
	self.payoutSetupFrame.RegisterCallback(self, "StartPayout", "ShowPayoutProgressFrame")

	self.payoutProgressFrame = addon.PayoutProgressFrame.Create()
	self.payoutProgressFrame.RegisterCallback(self, "StartPayout")
	self.payoutProgressFrame.RegisterCallback(self, "Done", "ResetState")
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
	end
end

function Core:ShowSetupPayoutFrame()
	self.payoutSetupFrame:Show()
end

function Core:HideSetupPayoutFrame()
	self.PayoutSetupFrame:Hide()
end

function Core:ShowPayoutProgressFrame(_, frame)
	local payments = frame:GetPayments()
	local success, err = pcall(function()
		self.payoutQueue = addon.PayoutQueue.Create(payments, frame:GetSubject())
	end)
	if not success then self:Printf("Error parsing payments: %s", err) end
	self.payoutProgressFrame:Show(self.payoutQueue)
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
		self.payoutExecutor = addon.PayoutExecutor.Create(self.payoutQueue)
		self.payoutExecutor.RegisterCallback(self, "MailSent")
		self.payoutExecutor.RegisterCallback(self, "MailFailed")
		self.payoutExecutor.RegisterCallback(self, "Stop", "StopPayout")
	end
	self.payoutExecutor:Start()
end

function Core:StopPayout()
	if self.payoutExecutor then
		self.payoutExecutor:Destroy()
		self.payoutExecutor = nil
		self.payoutProgressFrame:SetStartButtonState(false)
	end
end

function Core:MailSent(_, _, payout)
	self.payoutProgressFrame:MarkPaid(payout.player)
end

function Core:MailFailed(_, _, payout)
	self.payoutProgressFrame:MarkUnpaid(payout.player)
end
