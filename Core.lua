local AceAddon = LibStub("AceAddon-3.0")
local AceLocale = LibStub("AceLocale-3.0")

HuokanPayout = AceAddon:NewAddon("HuokanPayout", "AceConsole-3.0")

function HuokanPayout:OnInitialize()
	self.L = AceLocale:GetLocale("HuokanPayout")
	self:ResetState()
	self:RegisterChatCommand("payout", "SlashPayout")
end

function HuokanPayout:ResetState()
	self:StopPayout()
	self.payoutQueue = nil
	if self.payoutSetupFrame then self.payoutSetupFrame:Hide() end
	if self.payoutProgressFrame then self.payoutProgressFrame:Hide() end

	self.payoutSetupFrame = HuokanPayout.PayoutSetupFrame.Create()
	self.payoutSetupFrame.RegisterCallback(self, "StartPayout", "ShowPayoutProgressFrame")

	self.payoutProgressFrame = HuokanPayout.PayoutProgressFrame.Create()
	self.payoutProgressFrame.RegisterCallback(self, "StartPayout")
	self.payoutProgressFrame.RegisterCallback(self, "Done", "ResetState")
end

function HuokanPayout:Debug(...)
	-- TODO add developer mode toggle
	self:Print(...)
end

function HuokanPayout:Debugf(...)
	self:Printf(...)
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

function HuokanPayout:ShowPayoutProgressFrame(_, frame)
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

function HuokanPayout:StartPayout()
	if not self.payoutQueue then error("Tried to start payout with no payout queue") end
	if not self.payoutExecutor then
		self.payoutExecutor = HuokanPayout.PayoutExecutor.Create(self.payoutQueue)
		self.payoutExecutor.RegisterCallback(self, "MailSent")
		self.payoutExecutor.RegisterCallback(self, "Stop", "StopPayout")
	end
	self.payoutExecutor:Start()
end

function HuokanPayout:StopPayout()
	if self.payoutExecutor then
		self.payoutExecutor:Destroy()
		self.payoutExecutor = nil
		self.payoutProgressFrame:SetStartButtonState(false)
	end
end

function HuokanPayout:MailSent(_, _, payout)
	self.payoutProgressFrame:MarkPaid(payout.player)
end
