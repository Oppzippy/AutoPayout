std = "lua51"
max_line_length = false
exclude_files = {
	"**/Libs",
}
ignore = {
	"212", -- Unused argument
}
globals = {
	"LibStub",
	"HuokanPayout",
	"GetCoinTextureString",
	"strsplit",
	"COPPER_PER_GOLD",
	"COPPER_PER_SILVER",
	"CreateFrame",
	"SendMail",
	"SetSendMailMoney",
}
