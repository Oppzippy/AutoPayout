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
