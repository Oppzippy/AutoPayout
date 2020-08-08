local _, addon = ...
local TableUtils = {}
addon.TableUtils = TableUtils

do
	local function returnArgs(...)
		return ...
	end

	local function getPartitionValues(partition)
		return partition.values
	end

	function TableUtils.GreedyPartition(descendingTable, numPartitions, evaluate)
		evaluate = evaluate or returnArgs
		local partitions = {}
		for i = 1, numPartitions do
			partitions[i] = {
				values = {},
				sum = 0,
			}
		end

		for _, value in ipairs(descendingTable) do
			local smallest
			for _, partition in ipairs(partitions) do
				if not smallest or partition.sum < smallest.sum then
					smallest = partition
				end
			end
			table.insert(smallest.values, value)
			smallest.sum = smallest.sum + evaluate(value)
		end

		return TableUtils.Map(partitions, getPartitionValues)
	end
end

function TableUtils.Map(t, func)
	local newTable = {}
	for i, value in ipairs(t) do
		newTable[i] = func(value)
	end
	return newTable
end
