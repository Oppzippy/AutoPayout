local _, addon = ...
local L = addon.L

local PayoutQueuePrototype = {}
PayoutQueuePrototype.__index = PayoutQueuePrototype

addon.PayoutQueue = PayoutQueuePrototype

local function FormatPlayerName(name)
	return name:sub(1, 1):upper() .. name:sub(2):lower()
end

function PayoutQueuePrototype.ParseCSV(csv)
	local map = {}
	local lines = { strsplit("\n", csv) }
	for _, line in ipairs(lines) do
		local player, gold = strsplit(",", line)
		player = FormatPlayerName(player)
		gold = tonumber(gold)
		if #player > 0 then
			if gold then
				map[player] = gold
			else
				error({message = L.not_assigned_gold_value:format(player)})
			end
		end
	end
	return map
end

function PayoutQueuePrototype.Create(payments, subject)
	local payoutQueue = setmetatable({}, PayoutQueuePrototype)
	payoutQueue.payments = {}
	for player, copper in next, payments do
		payoutQueue.payments[#payoutQueue.payments+1] = {
			player = player,
			copper = copper,
			subject = subject,
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
