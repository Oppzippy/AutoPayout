local PayoutExecutorPrototype = {}
PayoutExecutorPrototype.__index = PayoutExecutorPrototype

function PayoutExecutorPrototype.Create(payoutQueue)
	local payoutExecutor = setmetatable({}, PayoutExecutorPrototype)
	HuokanPayout.EventHandler.Embed(payoutExecutor)
	payoutExecutor.payoutQueue = payoutQueue
	payoutExecutor.frame = CreateFrame("Frame")
	return payoutExecutor
end

function PayoutExecutorPrototype:Destroy()
	self:UnregisterAllEvents()
end

function PayoutExecutorPrototype:Start()
	self:RegisterEvent("MAIL_SEND_SUCCESS")
	self:RegisterEvent("MAIL_FAILED")
end

function PayoutExecutorPrototype:Stop()
	self:UnregisterEvent("MAIL_SEND_SUCCESS")
	self:UnregisterEvent("MAIL_FAILED")
end

function PayoutExecutorPrototype:SendNext()
	local next = self.payoutQueue:Peek()
	if not next then self:Stop() return end
	SetSendMailMoney(next.copper)
	SendMail(next.player, "TODO custom subject", "")
end

function PayoutExecutorPrototype:MAIL_SEND_SUCCESS()
end

function PayoutExecutorPrototype:MAIL_FAILED()

end
