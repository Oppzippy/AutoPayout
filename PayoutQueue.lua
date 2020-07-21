local _, addon = ...
local L = addon.L

local PayoutQueuePrototype = {}
PayoutQueuePrototype.__index = PayoutQueuePrototype

addon.PayoutQueue = PayoutQueuePrototype

local COPPER_CAP = 99999999999 - 30 -- Subtract postage fee

do
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
end

function PayoutQueuePrototype.Create(payments, subject)
	local payoutQueue = setmetatable({}, PayoutQueuePrototype)
	payoutQueue.payouts = {}
	for _, payment in ipairs(payments) do
		payoutQueue:AddPayment(payment, subject)
	end
	payoutQueue.index = 1
	return payoutQueue
end

function PayoutQueuePrototype:AddPayment(payment, subject, id)
	local payments = self:SplitPayment(payment.copper)
	for _, copper in ipairs(payments) do
		local nextIndex = #self.payouts+1
		self.payouts[nextIndex] = {
			player = payment.player,
			copper = copper,
			subject = subject,
			id = nextIndex,
		}
	end
end

function PayoutQueuePrototype:SplitPayment(copper)
	local t = {}
	local count = 0
	while copper > 0 do
		count = count + 1
		local payoutCopper = copper
		if payoutCopper > COPPER_CAP and count < 2 then
			payoutCopper = COPPER_CAP
		end
		copper = copper - payoutCopper
		t[#t+1] = payoutCopper
	end
	return t
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
