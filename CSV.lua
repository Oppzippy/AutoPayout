local _, addon = ...

local CSV = {}

function CSV.ToCSV(t)
	local csv = {}
	for i, line in ipairs(t) do
		csv[i] = table.concat(line, ",")
	end
	return table.concat(csv, "\n")
end

---@param csv string
---@return string[][]
function CSV.ToTable(csv)
	local t = {}
	for line in csv:gmatch("[^\r\n]+") do
		local row = {}
		t[#t + 1] = row

		-- Convert four+ spaces TSV to CSV
		line = line:gsub("    [ ]*", ",")

		for cell in line:gmatch("[^,\t]+") do
			row[#row + 1] = cell
		end
	end
	return t
end

if addon then
	addon.CSV = CSV
end
return CSV
