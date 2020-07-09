local AceAddon = LibStub("AceAddon-3.0")
local AceLocale = LibStub("AceLocale-3.0")

HuokanPayout = AceAddon:NewAddon("HuokanPayout", "AceConsole-3.0")

function HuokanPayout:OnInitialize()
	self.L = AceLocale:GetLocale("HuokanPayout")
	self.payoutSetupFrame = HuokanPayout.PayoutSetupFrame.Create()
	self.payoutSetupFrame.RegisterCallback(self, "StartPayout")
	--self.payoutProgressFrame = HuokanPayout:NewPayoutProgressFrame()
	--self.payoutScheduler = HuokanPayout:NewPayoutScheduler()
	self:RegisterChatCommand("payout", "SlashPayout")
end

function HuokanPayout:SlashPayout(args)
	if not self.isPayoutInProgress then
		if args == "" then
			self:ShowSetupPayoutFrame()
		end
	end
end

function HuokanPayout:ShowSetupPayoutFrame()
	self.payoutSetupFrame:Hide()
	self.payoutSetupFrame:Show()
end

function HuokanPayout:ShowPayoutProgressFrame()
	self.payoutProgressFrame:Show()
end

function HuokanPayout:StartPayout(_, frame)
	local payments = frame:GetPayments()
end
