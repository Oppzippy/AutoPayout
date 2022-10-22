local luaunit = require("luaunit")
local CSV = require("CSV")

TestCSV = {}

function TestCSV:TestCSV()
	local result = CSV.ToTable("One,Two\nThree,Four")
	luaunit.assertEquals(result[1][1], "One")
	luaunit.assertEquals(result[1][2], "Two")
	luaunit.assertEquals(result[2][1], "Three")
	luaunit.assertEquals(result[2][2], "Four")
end

function TestCSV:TestTSV()
	local result = CSV.ToTable("One\tTwo\nThree\tFour")
	luaunit.assertEquals(result[1][1], "One")
	luaunit.assertEquals(result[1][2], "Two")
	luaunit.assertEquals(result[2][1], "Three")
	luaunit.assertEquals(result[2][2], "Four")
end

function TestCSV:TestFourSpaceTSV()
	local result = CSV.ToTable("One    Two\nThree        Four")
	luaunit.assertEquals(result[1][1], "One")
	luaunit.assertEquals(result[1][2], "Two")
	luaunit.assertEquals(result[2][1], "Three")
	luaunit.assertEquals(result[2][2], "Four")
end

function TestCSV:TestIgnoresEmptyLines()
	local result = CSV.ToTable("One\n\nTwo")
	luaunit.assertEquals(#result, 2)
end

function TestCSV:TestEmptyString()
	local result = CSV.ToTable("")
	luaunit.assertEquals(#result, 0)
end

function TestCSV:TestOneLine()
	local result = CSV.ToTable("test")
	luaunit.assertEquals(result[1][1], "test")
end
