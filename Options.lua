local _, addon = ...
local L = addon.L

addon.options = {
	type = "group",
	get = function(info)
		local key = info[#info]
		return addon.core.db.profile[key]
	end,
	set = function(info, val)
		local key = info[#info]
		addon.core.db.profile[key] = val
	end,
	args = {
		defaultSubject = {
			name = L.default_subject,
			type = "input",
			width = "full",
		},
		defaultUnit = {
			name = L.default_unit,
			type = "select",
			width = "full",
			values = {
				[1] = GetCoinTextureString(1),
				[COPPER_PER_SILVER] = GetCoinTextureString(COPPER_PER_SILVER),
				[COPPER_PER_GOLD] = GetCoinTextureString(COPPER_PER_GOLD),
				[COPPER_PER_GOLD*1000] = GetCoinTextureString(COPPER_PER_GOLD * 1000),
			},
		},
	},
}

addon.dbDefaults = {
	profile = {
		defaultSubject = "Payout",
		defaultUnit = COPPER_PER_GOLD,
		debug = false,
	}
}
