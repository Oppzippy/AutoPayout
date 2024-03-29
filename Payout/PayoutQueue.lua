---@class addon
local addon = select(2, ...)
local L = addon.L

---@class PayoutQueue
---@field payouts table
local PayoutQueuePrototype = {}
addon.PayoutQueuePrototype = PayoutQueuePrototype

do
	local function trim(s)
		local trimmed = s:gsub("%s*(.-)%s*", "%1")
		return trimmed
	end

	function PayoutQueuePrototype.ParseCSV(csv)
		local payments = {}
		local rows = addon.CSV.ToTable(csv)
		for _, row in ipairs(rows) do
			local player, copperString = row[1], row[2]
			player = trim(player)
			local copper = tonumber(copperString)
			if #player > 0 then
				if not copper then
					error({ message = L.not_assigned_gold_value:format(player) })
				elseif copper < 0 then
					error({ message = L.can_not_assign_negative_gold:format(player) })
				elseif copper > 0 then
					payments[#payments + 1] = {
						copper = copper,
						player = player,
					}
				end
			end
		end
		return payments
	end
end

---@param payments table
---@param globalSubject string deprecated. use the subject property in individual payments.
---@return PayoutQueue
function PayoutQueuePrototype.Create(payments, globalSubject)
	local payoutQueue = setmetatable({}, { __index = PayoutQueuePrototype })
	payoutQueue.payouts = {}
	payoutQueue.index = 1
	if payments then
		for _, payment in ipairs(payments) do
			if globalSubject then
				payment.subject = globalSubject
			end
			payoutQueue:AddPayment(payment)
		end
	end
	return payoutQueue
end

---@param payment table
function PayoutQueuePrototype:AddPayment(payment)
	local nextIndex = #self.payouts + 1
	self.payouts[nextIndex] = {
		player = payment.player,
		copper = payment.copper,
		subject = payment.subject,
		id = nextIndex,
	}
end

---@return fun(): table?
function PayoutQueuePrototype:IteratePayouts()
	local i = 1
	return function()
		local payment = self.payouts[i]
		if payment then
			i = i + 1
			return payment
		end
	end
end

---@return table?
function PayoutQueuePrototype:Peek()
	return self.payouts[self.index]
end

---@return table
function PayoutQueuePrototype:Pop()
	local payment = self.payouts[self.index]
	self.index = self.index + 1
	return payment
end
