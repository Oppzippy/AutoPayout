---@class addon
local addon = select(2, ...)

---@class PayoutSplitter
---@field splitAfterCopper number
---@field maxSplits number
local PayoutSplitterPrototype = {}
addon.PayoutSplitterPrototype = PayoutSplitterPrototype

---@param splitAfterCopper number
---@param maxSplits number
---@return PayoutSplitter
function PayoutSplitterPrototype.Create(splitAfterCopper, maxSplits)
	local splitter = setmetatable({}, { __index = PayoutSplitterPrototype })
	splitter.splitAfterCopper = splitAfterCopper
	splitter.maxSplits = maxSplits
	return splitter
end

---@param payments table
---@return table
function PayoutSplitterPrototype:SplitPayments(payments)
	local t = {}
	for _, payment in ipairs(payments) do
		local splitPaymentValues = self:SplitPayment(payment.copper)
		for _, splitPaymentValue in ipairs(splitPaymentValues) do
			local newPayment = self:ClonePayment(payment)
			newPayment.copper = splitPaymentValue
			t[#t + 1] = newPayment
		end
	end
	return t
end

---@param copper number
---@return table
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
		t[#t + 1] = payoutCopper
	end
	return t
end

---@param payment table
---@return table
function PayoutSplitterPrototype:ClonePayment(payment)
	local t = {}
	for k, v in next, payment do
		t[k] = v
	end
	return t
end
