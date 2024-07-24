---@class addon
local addon = select(2, ...)
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
		autoShow = {
			order = 1,
			width = "full",
			name = L.automatically_show,
			type = "toggle",
		},
		defaultSubject = {
			order = 2,
			width = "full",
			name = L.default_subject,
			type = "input",
		},
		defaultUnit = {
			order = 3,
			width = "full",
			name = L.default_unit,
			type = "select",
			values = {
				[1] = C_CurrencyInfo.GetCoinTextureString(1),
				[COPPER_PER_SILVER] = C_CurrencyInfo.GetCoinTextureString(COPPER_PER_SILVER),
				[COPPER_PER_GOLD] = C_CurrencyInfo.GetCoinTextureString(COPPER_PER_GOLD),
				[COPPER_PER_GOLD * 1000] = C_CurrencyInfo.GetCoinTextureString(COPPER_PER_GOLD * 1000),
			},
		},
		maxHistorySize = {
			order = 4,
			width = "full",
			name = L.max_history_size,
			type = "range",
			min = 0,
			softMin = 1,
			max = 500,
			softMax = 100,
			step = 1,
			bigStep = 1,
		},
		maxPayoutSizeInGold = {
			order = 5,
			width = 1.75,
			name = L.max_payout_size_in_gold,
			desc = L.max_payout_size_in_gold_desc,
			type = "range",
			min = 0.0001,
			softMin = 1000,
			max = 9999999.9969, -- Gold cap minus postage fee
			softMax = 9999999.9969, -- Gold cap minus postage fee
			step = 0.0001,
			bigStep = 1,
		},
		maxPayoutSplits = {
			order = 6,
			width = 1.75,
			name = L.max_payout_splits,
			desc = L.max_payout_splits_desc,
			type = "range",
			min = 0,
			softMin = 0,
			max = 1000,
			softMax = 9,
			step = 1,
			bigStep = 1,
		},
	},
}

addon.dbDefaults = {
	profile = {
		defaultSubject = "Payout",
		defaultUnit = COPPER_PER_GOLD,
		debug = false,
		history = {},
		maxHistorySize = 20,
		maxPayoutSizeInGold = 1000000,
		maxPayoutSplits = 9,
		autoShow = false,
	}
}
