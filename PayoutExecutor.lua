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
	self:RegisterEvent("MAIL_SEND_SUCCESS")
	self:RegisterEvent("MAIL_FAILED")
	self:SendNext()
end

function PayoutExecutorPrototype:Stop()
	self.callbacks:Fire("Stop")
	self:UnregisterEvent("MAIL_SEND_SUCCESS")
	self:UnregisterEvent("MAIL_FAILED")
end

function PayoutExecutorPrototype:SendNext(predictedMoney)
	local next = self.payoutQueue:Peek()
	if not next then self:Stop() return end
	if self:CanSend(next, predictedMoney) then
		C_Timer.After(0, function()
			SetSendMailMoney(next.copper)
			SendMail(next.player, next.subject, "")
		end)
	else
		next.isPaid = false
		self.callbacks:Fire("MailFailed", self, next)
		self.payoutQueue:Pop()
		self:SendNext()
	end
end

function PayoutExecutorPrototype:CanSend(payout, predictedMoney)
	if UnitIsUnit(payout.player, "player") then
		-- Can not send mail to yourself
		addon.core:Debug("You can not send mail to yourself")
		return false
	end
	if payout.copper + 30 > (predictedMoney or GetMoney()) then -- 30c postage fee
		addon.core:Debugf("Not enough gold: %s should get %f", payout.player, payout.copper)
		return false
	end
	return true
end

function PayoutExecutorPrototype:MAIL_SEND_SUCCESS()
	local payout = self.payoutQueue:Pop()
	payout.isPaid = true
	self.callbacks:Fire("MailSent", self, payout)
	addon.core:Debugf("%s sent", payout.player)
	-- GetMoney doesnt update until another message is received from the server
	local predictedMoney = GetMoney() - payout.copper - 30
	self:SendNext(predictedMoney)
end

function PayoutExecutorPrototype:MAIL_FAILED()
	local payout = self.payoutQueue:Pop()
	payout.isPaid = false
	self.callbacks:Fire("MailFailed", self, payout)
	addon.core:Debugf("Mail send to %s failed", payout.player)
	self:Stop()
end
