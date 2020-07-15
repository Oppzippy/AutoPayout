local _, addon = ...

local CSV = {}
addon.CSV = CSV

function CSV.ToCSV(t)
	local csv = {}
	for i, line in ipairs(t) do
		csv[i] = table.concat(line, ",")
	end
	return table.concat(csv, "\n")
end

function CSV.ToTable(csv)
	local t = {}
	local lines = { strsplit("\n", csv) }
	for i, line in ipairs(lines) do
		t[i] = { strsplit(",", line) }
	end
	return t
end
