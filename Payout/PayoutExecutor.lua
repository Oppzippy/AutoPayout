local _, addon = ...

local CallbackHandler = LibStub("CallbackHandler-1.0")

local PayoutExecutorPrototype = {}
PayoutExecutorPrototype.__index = PayoutExecutorPrototype
addon.PayoutExecutorPrototype = PayoutExecutorPrototype

function PayoutExecutorPrototype.Create(payoutQueue)
	local payoutExecutor = setmetatable({}, PayoutExecutorPrototype)
	addon.EventHandler.Embed(payoutExecutor)
	payoutExecutor.callbacks = CallbackHandler:New(payoutExecutor)
	payoutExecutor.payoutQueue = payoutQueue
	payoutExecutor.frame = CreateFrame("Frame")
	return payoutExecutor
end

function PayoutExecutorPrototype:Start()
	self.isPayoutInProgress = true
	self:RegisterEvent("MAIL_SEND_SUCCESS")
	self:RegisterEvent("MAIL_FAILED")
	self:SendNext()
end

function PayoutExecutorPrototype:Stop()
	if self.stopTicker then return end

	self:HaltIfNotBusy()
	if self.isPayoutInProgress then
		self.stopTicker = C_Timer.NewTicker(0, function()
			self:HaltIfNotBusy()
		end)
	end
end

function PayoutExecutorPrototype:HaltIfNotBusy()
	if not C_Mail.IsCommandPending() then
		self:Halt()
	end
end

function PayoutExecutorPrototype:Halt()
	self.isPayoutInProgress = false
	self:UnregisterEvent("MAIL_SEND_SUCCESS")
	self:UnregisterEvent("MAIL_FAILED")
	self.callbacks:Fire("OnStopPayout")
	if self.stopTicker then
		self.stopTicker:Cancel()
		self.stopTicker = nil
	end
end

function PayoutExecutorPrototype:SendNext(predictedMoney)
	local next = self.payoutQueue:Peek()
	if not next then self:Halt() return end
	if self:CanSend(next, predictedMoney) then
		C_Timer.After(0, function()
			SetSendMailMoney(next.copper)
			SendMail(next.player, next.subject, "")
		end)
	else
		next.isPaid = false
		self.callbacks:Fire("OnMailFailed", self, next)
		self.payoutQueue:Pop()
		self:SendNext(predictedMoney)
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
	self.callbacks:Fire("OnMailSent", self, payout)
	addon.core:Debugf("%s sent", payout.player)
	-- GetMoney doesnt update until another message is received from the server
	local predictedMoney = GetMoney() - payout.copper - 30
	self:Stop() -- Repeated sending could be against blizzard's addon policy
	if not self.stopTicker then
		self:SendNext(predictedMoney)
	end
end

function PayoutExecutorPrototype:MAIL_FAILED()
	local payout = self.payoutQueue:Pop()
	payout.isPaid = false
	self.callbacks:Fire("OnMailFailed", self, payout)
	addon.core:Debugf("Mail send to %s failed", payout.player)
	if not self.stopTicker then
		self:Halt()
	end
end
