local PayoutQueuePrototype = {}
PayoutQueuePrototype.__index = PayoutQueuePrototype

HuokanPayout.PayoutQueue = PayoutQueuePrototype

function PayoutQueuePrototype.ParseCSV(csv)
	local map = {}
	local lines = { strsplit("\n", csv) }
	for _, line in ipairs(lines) do
		local player, gold = strsplit(",", line)
		gold = tonumber(gold)
		if player and #player > 0 then
			if gold then
				map[player] = gold
			else
				error({message = HuokanPayout.L.not_assigned_gold_value:format(player)})
			end
		end
	end
	return map
end

function PayoutQueuePrototype.Create(payments)
	local payoutQueue = setmetatable({}, PayoutQueuePrototype)
	payoutQueue.payments = {}
	for player, copper in next, payments do
		payoutQueue.payments[#payoutQueue.payments+1] = {
			player = player,
			copper = copper,
			isPaid = false,
		}
	end
	payoutQueue.index = 1
	return payoutQueue
end

function PayoutQueuePrototype:IteratePayments()
	local i = 1
	return function()
		local payment = self.payments[i]
		if payment then
			i = i + 1
			return payment.player, payment.copper, payment.isPaid
		end
	end
end

function PayoutQueuePrototype:Peek()
	return self.payments[self.index]
end

function PayoutQueuePrototype:Pop()
	local payment = self.payments[self.index]
	self.index = self.index + 1
	return payment
end
