local _, addon = ...
addon.COMM_PREFIX = "HuokanPayout"

local AceAddon = LibStub("AceAddon-3.0")
local AceLocale = LibStub("AceLocale-3.0")
local AceDB = LibStub("AceDB-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local LibDeflate = LibStub("LibDeflate")

local L = AceLocale:GetLocale("HuokanPayout")
addon.L = L

local Core = AceAddon:NewAddon("HuokanPayout", "AceConsole-3.0", "AceComm-3.0", "AceSerializer-3.0")
addon.core = Core

function Core:OnInitialize()
	self.db = AceDB:New("HuokanPayoutDB", addon.dbDefaults, true)
	AceConfig:RegisterOptionsTable("HuokanPayout", addon.options)
	AceConfigDialog:AddToBlizOptions("HuokanPayout", L.addon_name)
	self:RegisterChatCommand("payout", "SlashPayout")
	self:ResetState()
	addon.EventHandler.Embed(self)
	self:RegisterEvent("MAIL_SHOW")
	self:RegisterComm(addon.COMM_PREFIX, "OnCommReceived")
end

function Core:OnCommReceived(prefix, text, channel, sender)
	-- TODO if not allowedSender then return end
	local success, packet = self:DeserializePacket(text)
	if not success then
		self:Debugf("Received bad packet: %s\n%s", packet, text)
		return
	end
	if packet.type == "DoNewPayout" then
		if self.payoutQueue then
			local responsePacket = {
				type = "ErrPayoutInProgress",
			}
			self:SendCommMessage(addon.COMM_PREFIX, self:SerializePacket(responsePacket), "WHISPER", sender)
			return
		end
		if self.payoutSetupFrame then
			self.payoutSetupFrame:Hide()
			self.payoutSetupFrame = nil
		end
		self:ShowPayoutProgressFrameRaw(packet.payments, packet.unit)
		self:CreateHistoryRecord(self:PaymentsToCSV(packet.payments))
	end
end

function Core:DistributePaymentsAndSend(payments, players, unit)
	local playerPayments = self:DistributePayments(payments, players)
	self:SendPayments(playerPayments, unit)
end

do
	local function sortPaymentsDesc(a, b)
		return a.copper > b.copper
	end

	local function getCopper(payment)
		return payment.copper
	end

	function Core:DistributePayments(payments, players)
		table.sort(payments, sortPaymentsDesc)
		local partitions = addon.TableUtils.GreedyPartition(payments, #players, getCopper)
		local playerPayments = {}
		for i, player in ipairs(players) do
			playerPayments[player] = partitions[i]
		end

		return playerPayments
	end
end

function Core:SendPayments(playerPayments, unit)
	for player, payments in next, playerPayments do
		local packet = {
			type = "DoNewPayout",
			payments = payments,
			unit = unit,
		}
		self:SendCommMessage(addon.COMM_PREFIX, self:SerializePacket(packet), "WHISPER", player)
	end
end

function Core:SerializePacket(packet)
	local serialized = self:Serialize(packet)
	local compressed = LibDeflate:CompressDeflate(serialized)
	return LibDeflate:EncodeForWoWAddonChannel(compressed)
end

function Core:DeserializePacket(compressed)
	local decoded = LibDeflate:DecodeForWoWAddonChannel(compressed)
	local serialized = LibDeflate:DecompressDeflate(decoded)
	if not serialized then
		return false, "Failed to decompress"
	end
	return self:Deserialize(serialized)
end

function Core:PaymentsToCSV(payments)
	local lines = {}
	for _, payment in ipairs(payments) do
		lines[#lines+1] = string.format("%s,%s", payment.player, payment.copper)
	end
	return table.concat(lines, "\n")
end

function Core:ResetState()
	self:StopPayout()
	self.payoutQueue = nil
	self.historyRecord = nil
	if self.payoutSetupFrame then self.payoutSetupFrame:Hide() end
	if self.payoutProgressFrame then self.payoutProgressFrame:Hide() end
	self:CreatePayoutSetupFrame()
	self.payoutProgressFrame = nil
end

function Core:CreatePayoutSetupFrame()
	self.payoutSetupFrame = addon.PayoutSetupFramePrototype.Create()
	self.payoutSetupFrame.RegisterCallback(self, "OnStartPayout", "OnShowPayoutProgressFrame")
end

function Core:CreatePayoutProgressFrame()
	self.payoutProgressFrame = addon.PayoutProgressFramePrototype.Create()
	self.payoutProgressFrame.RegisterCallback(self, "DoStartPayout", "StartPayout")
	self.payoutProgressFrame.RegisterCallback(self, "OnDone", "OnPayoutProgressFrameDone")
end

function Core:OnPayoutProgressFrameDone()
	if self.historyRecord then
		self.historyRecord.output = self.payoutProgressFrame:GetUnpaidCSV()
	end
	self:ResetState()
end

function Core:WipeOldHistory()
	local maxHistorySize = self.db.profile.maxHistorySize
	local history = self.db.profile.history
	if #history > maxHistorySize then
		for i = maxHistorySize + 1, #history do
			history[i] = nil
		end
	end
end

function Core:Debug(...)
	if self.db.profile.debug then
		self:Print(...)
	end
end

function Core:Debugf(...)
	if self.db.profile.debug then
		self:Printf(...)
	end
end

function Core:MAIL_SHOW()
	if not self.db.profile.autoShow then return end
	if not self.payoutQueue and not self.payoutSetupFrame:IsVisible() then
		self.payoutSetupFrame:Show()
	elseif self.payoutProgressFrame and not self.payoutProgressFrame:IsVisible() then
		self.payoutProgressFrame:Show(self.payoutQueue)
	end
end

function Core:SlashPayout(args)
	if args == "" then
		if not self.payoutQueue then
			if self.payoutSetupFrame:IsVisible() then
				self.payoutSetupFrame:Hide()
			else
				self.payoutSetupFrame:Show()
			end
		else
			if self.payoutProgressFrame:IsVisible() then
				self.payoutProgressFrame:Hide()
			else
				self.payoutProgressFrame:Show(self.payoutQueue)
			end
		end
	elseif args == "history" then
		if not self.historyFrame then
			self.historyFrame = addon.HistoryFramePrototype.Create()
			self.historyFrame:Show(self.db.profile.history)
			self.historyFrame.RegisterCallback(self, "OnClose", "OnHistoryFrameClose")
		else
			self.historyFrame:Hide()
			self.historyFrame = nil
		end
	end
end

function Core:OnHistoryFrameClose()
	self.historyFrame = nil
end

function Core:ShowSetupPayoutFrame()
	self.payoutSetupFrame:Show()
end

function Core:HideSetupPayoutFrame()
	self.PayoutSetupFrame:Hide()
end

function Core:OnShowPayoutProgressFrame(_, frame)
	local payments = self:SplitPayments(frame:GetPayments())
	for _, payment in next, payments do
		payment.subject = frame:GetSubject()
	end
	self:ShowPayoutProgressFrameRaw(payments, frame:GetUnit())
	self:CreateHistoryRecord(frame:GetCSV())
end

function Core:ShowPayoutProgressFrameRaw(payments, unit)
	local success, err = pcall(function()
		self.payoutQueue = addon.PayoutQueuePrototype.Create(payments)
	end)
	if not success then self:Printf("Error parsing payments: %s", err) end
	self.payoutSetupFrame = nil
	self:CreatePayoutProgressFrame()
	self.payoutProgressFrame:SetUnit(unit)
	self.payoutProgressFrame:Show(self.payoutQueue)
	self.payoutProgressFrame.RegisterCallback(self, "DoStopPayout", "StopPayout")
end

function Core:CreateHistoryRecord(input)
	self.historyRecord = {
		timestamp = GetServerTime(),
		input = input,
	}
	table.insert(self.db.profile.history, 1, self.historyRecord)
	self:WipeOldHistory()
end

function Core:SplitPayments(payments)
	local payoutSplitter = addon.PayoutSplitterPrototype.Create(
		self.db.profile.maxPayoutSizeInGold * COPPER_PER_GOLD,
		self.db.profile.maxPayoutSplits
	)
	return payoutSplitter:SplitPayments(payments)
end

function Core:ShowInProgressPayout(_, frame)
	if self.payoutQueue then
		self.payoutProgressFrame:Show(self.payoutQueue)
	else
		error("Tried to resume nil payout queue")
	end
end

function Core:StartPayout()
	if not self.payoutQueue then error("Tried to start payout with no payout queue") end
	if not self.payoutExecutor then
		self.payoutExecutor = addon.PayoutExecutorPrototype.Create(self.payoutQueue)
		self.payoutExecutor.RegisterCallback(self, "OnMailSent")
		self.payoutExecutor.RegisterCallback(self, "OnMailFailed")
		self.payoutExecutor.RegisterCallback(self, "OnStopPayout")
	end
	self.payoutExecutor:Start()
end

function Core:StopPayout()
	if self.payoutExecutor then
		self.payoutExecutor:Stop()
	end
end

function Core:OnStopPayout()
	if self.payoutExecutor then
		self.payoutExecutor = nil
		if self.payoutProgressFrame then
			self.payoutProgressFrame:SetStartButtonState(false)
			self.payoutProgressFrame:UpdateUnpaidCSV()
		end
	end
end

function Core:OnMailSent(_, _, payout)
	self.payoutProgressFrame:MarkPaid(payout)
end

function Core:OnMailFailed(_, _, payout)
	self.payoutProgressFrame:MarkUnpaid(payout)
end
