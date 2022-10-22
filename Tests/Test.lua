local luaunit = require("luaunit")

require("Tests.CSV")

os.exit(luaunit.LuaUnit.run())
