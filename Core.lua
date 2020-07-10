local AceAddon = LibStub("AceAddon-3.0")
local AceLocale = LibStub("AceLocale-3.0")

HuokanPayout = AceAddon:NewAddon("HuokanPayout", "AceConsole-3.0")

function HuokanPayout:OnInitialize()
	self.L = AceLocale:GetLocale("HuokanPayout")
	self.payoutSetupFrame = HuokanPayout.PayoutSetupFrame.Create()
	self.payoutSetupFrame.RegisterCallback(self, "StartPayout")
	self.payoutProgressFrame = HuokanPayout.PayoutProgressFrame.Create()
	--self.payoutScheduler = HuokanPayout:NewPayoutScheduler()
	self:RegisterChatCommand("payout", "SlashPayout")
end

function HuokanPayout:SlashPayout(args)
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

function HuokanPayout:ShowSetupPayoutFrame()
	self.payoutSetupFrame:Show()
end

function HuokanPayout:HideSetupPayoutFrame()
	self.PayoutSetupFrame:Hide()
end

function HuokanPayout:ShowPayoutProgressFrame()
	self.payoutProgressFrame:Show()
end

function HuokanPayout:StartPayout(_, frame)
	local payments = frame:GetPayments()
	local success, err = pcall(function()
		self.payoutQueue = HuokanPayout.PayoutQueue.Create(payments)
	end)
	if not success then self:Printf("Error parsing payments: %s", err) end
	self.payoutProgressFrame:Show(self.payoutQueue)
end

function HuokanPayout:ShowInProgressPayout(_, frame)
	if self.payoutQueue then
		self.payoutProgressFrame:Show(self.payoutQueue)
	else
		error("Tried to resume nil payout queue")
	end
end
