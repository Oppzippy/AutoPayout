local _, addon = ...

local PayoutSplitterPrototype = {}
PayoutSplitterPrototype.__index = PayoutSplitterPrototype
addon.PayoutSplitter = PayoutSplitterPrototype

function PayoutSplitterPrototype.Create(splitAfterCopper, maxSplits)
	local splitter = setmetatable({}, PayoutSplitterPrototype)
	splitter.splitAfterCopper = splitAfterCopper
	splitter.maxSplits = maxSplits
	return splitter
end

function PayoutSplitterPrototype:SplitPayments(payments)
	local t = {}
	for _, payment in ipairs(payments) do
		local splitPaymentValues = self:SplitPayment(payment.copper)
		for _, splitPaymentValue in ipairs(splitPaymentValues) do
			local newPayment = self:ClonePayment(payment)
			newPayment.copper = splitPaymentValue
			t[#t+1] = newPayment
		end
	end
	return t
end

function PayoutSplitterPrototype:SplitPayment(copper)
	local t = {}
	local count = 0
	while copper > 0 do
		count = count + 1
		local payoutCopper = copper
		if payoutCopper > self.splitAfterCopper and count <= self.maxSplits then
			payoutCopper = self.splitAfterCopper
		end
		copper = copper - payoutCopper
		t[#t+1] = payoutCopper
	end
	return t
end

function PayoutSplitterPrototype:ClonePayment(payment)
	local t = {}
	for k, v in next, payment do
		t[k] = v
	end
	return t
end
