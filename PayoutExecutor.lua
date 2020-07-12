local _, addon = ...

local CallbackHandler = LibStub("CallbackHandler-1.0")

local PayoutExecutorPrototype = {}
PayoutExecutorPrototype.__index = PayoutExecutorPrototype
addon.PayoutExecutor = PayoutExecutorPrototype

function PayoutExecutorPrototype.Create(payoutQueue)
	local payoutExecutor = setmetatable({}, PayoutExecutorPrototype)
	addon.EventHandler.Embed(payoutExecutor)
	payoutExecutor.callbacks = CallbackHandler:New(payoutExecutor)
	payoutExecutor.payoutQueue = payoutQueue
	payoutExecutor.frame = CreateFrame("Frame")
	return payoutExecutor
end

function PayoutExecutorPrototype:Destroy()
	self:UnregisterAllEvents()
end

function PayoutExecutorPrototype:Start()
	self:RegisterEvent("MAIL_SHOW")
	self:RegisterEvent("MAIL_SEND_SUCCESS")
	self:RegisterEvent("MAIL_FAILED")
	self:SendNext()
end

function PayoutExecutorPrototype:Stop()
	self.callbacks:Fire("Stop")
	self:UnregisterEvent("MAIL_SHOW")
	self:UnregisterEvent("MAIL_SEND_SUCCESS")
	self:UnregisterEvent("MAIL_FAILED")
end

function PayoutExecutorPrototype:SendNext()
	local next = self.payoutQueue:Peek()
	if not next then self:Stop() return end
	C_Timer.After(0, function()
		SetSendMailMoney(next.copper)
		SendMail(next.player, next.subject, "")
	end)
end

function PayoutExecutorPrototype:MAIL_SHOW()
	-- TODO this doesn't work. Maybe a different event or a longer delay?
	self:SendNext()
end

function PayoutExecutorPrototype:MAIL_SEND_SUCCESS()
	local payout = self.payoutQueue:Pop()
	payout.isPaid = true
	self.callbacks:Fire("MailSent", self, payout)
	addon.core:Debugf("%s sent", payout.player)
	self:SendNext()
end

function PayoutExecutorPrototype:MAIL_FAILED()
	local payout = self.payoutQueue:Pop()
	self.callbacks:Fire("MailFailed", self, payout)
	addon.core:Debugf("Mail send to %s failed", payout.player)
end
