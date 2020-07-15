local _, addon = ...
local L = addon.L

local PayoutQueuePrototype = {}
PayoutQueuePrototype.__index = PayoutQueuePrototype

addon.PayoutQueue = PayoutQueuePrototype

local function trim(s)
	local trimmed = s:gsub("%s*(.-)%s*", "%1")
	return trimmed
end

function PayoutQueuePrototype.ParseCSV(csv)
	local payments = {}
	local lines = { strsplit("\n", csv) }
	for _, line in ipairs(lines) do
		local player, copper = strsplit(",", line)
		player = trim(player)
		copper = tonumber(trim(copper))
		if #player > 0 then
			if not copper then
				error({message = L.not_assigned_gold_value:format(player)})
			elseif copper < 0 then
				error({message = L.can_not_assign_negative_gold:format(player)})
			elseif copper > 0 then
				payments[#payments+1] = {
					copper = copper,
					player = player,
				}
			end
		end
	end
	return payments
end

function PayoutQueuePrototype.Create(payments, subject)
	local payoutQueue = setmetatable({}, PayoutQueuePrototype)
	payoutQueue.payouts = {}
	for i, payment in ipairs(payments) do
		payoutQueue.payouts[i] = {
			player = payment.player,
			copper = payment.copper,
			subject = subject,
			id = i,
		}
	end
	payoutQueue.index = 1
	return payoutQueue
end

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

function PayoutQueuePrototype:Peek()
	return self.payouts[self.index]
end

function PayoutQueuePrototype:Pop()
	local payment = self.payouts[self.index]
	self.index = self.index + 1
	return payment
end
