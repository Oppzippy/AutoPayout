---@class addon
local addon = select(2, ...)

local AceGUI = LibStub("AceGUI-3.0")
local CallbackHandler = LibStub("CallbackHandler-1.0")
local L = addon.L

---@class PayoutProgressFrame
---@field callbacks CallbackHandlerRegistry
---@field frames table
---@field RegisterCallback fun(self: table, eventName: string, method?: string)
---@field UnregisterCallback fun(self: table, eventName: string)
---@field UnregisterAllCallbacks fun(self: table)
local PayoutProgressFramePrototype = {}
addon.PayoutProgressFramePrototype = PayoutProgressFramePrototype

local DEFAULT_IMAGE = "Interface\\RAIDFRAME\\ReadyCheck-Waiting"
local PAID_IMAGE = "Interface\\RAIDFRAME\\ReadyCheck-Ready"
local UNPAID_IMAGE = "Interface\\RAIDFRAME\\ReadyCheck-NotReady"

---@return PayoutProgressFrame
function PayoutProgressFramePrototype.Create()
	local frame = setmetatable({}, { __index = PayoutProgressFramePrototype })
	frame.callbacks = CallbackHandler:New(frame)
	frame.frames = {}
	return frame
end

---@return number
function PayoutProgressFramePrototype:GetUnit()
	return self.unit or addon.core.db.profile.defaultUnit
end

---@param unit number
function PayoutProgressFramePrototype:SetUnit(unit)
	self.unit = unit
end

---@param payoutQueue table
---@return AceGUISimpleGroup
function PayoutProgressFramePrototype:Show(payoutQueue)
	self.payoutQueue = payoutQueue

	self.frames.frame = self:CreateFrame()

	self:UpdateProgressList()
	self:UpdateUnpaidCSV()

	return self.frames.frame
end

---@return AceGUISimpleGroup
function PayoutProgressFramePrototype:CreateFrame()
	local frame = AceGUI:Create("SimpleGroup")
	---@cast frame AceGUISimpleGroup
	frame:SetCallback("OnRelease", function()
		self.frames = {}
	end)
	frame:SetLayout("Flow")

	local frames = self.frames

	frames.startButton = self:CreateStartButton()
	frames.startButton:SetRelativeWidth(0.5)
	frame:AddChild(frames.startButton)

	frames.doneButton = self:CreateDoneButton()
	frames.doneButton:SetRelativeWidth(0.5)
	frame:AddChild(frames.doneButton)

	-- None of the default AceGUI provide the option to have two frames scale in height together,
	-- so pause the layout and use SetPoint manually
	local pausedLayoutGroup = AceGUI:Create("SimpleGroup")
	---@cast pausedLayoutGroup AceGUISimpleGroup
	pausedLayoutGroup:SetFullWidth(true)
	pausedLayoutGroup:SetFullHeight(true)
	pausedLayoutGroup:PauseLayout()
	frame:AddChild(pausedLayoutGroup)

	frames.scrollContainer, frames.scrollFrame = self:CreateDetailedProgressList()
	pausedLayoutGroup:AddChild(frames.scrollContainer)

	---@diagnostic disable-next-line: undefined-field
	frames.scrollContainer:SetPoint("TOPLEFT", pausedLayoutGroup.frame, "TOPLEFT", 0, 0)
	---@diagnostic disable-next-line: undefined-field
	frames.scrollContainer:SetPoint("BOTTOMRIGHT", pausedLayoutGroup.frame, "RIGHT")

	frames.csvBox = self:CreateCSVBox()
	pausedLayoutGroup:AddChild(frames.csvBox)

	---@diagnostic disable-next-line: undefined-field
	frames.csvBox:SetPoint("TOPLEFT", frames.scrollContainer.frame, "BOTTOMLEFT", 0, 0)
	---@diagnostic disable-next-line: undefined-field
	frames.csvBox:SetPoint("BOTTOMRIGHT", pausedLayoutGroup.frame, "BOTTOMRIGHT", 0, 0)
	return frame
end

---@return AceGUISimpleGroup
---@return AceGUIScrollFrame
function PayoutProgressFramePrototype:CreateDetailedProgressList()
	local scrollContainer = AceGUI:Create("SimpleGroup")
	---@cast scrollContainer AceGUISimpleGroup
	scrollContainer:SetFullWidth(true)
	scrollContainer:SetHeight(300)
	scrollContainer:SetLayout("Fill")
	local scrollFrame = AceGUI:Create("ScrollFrame")
	---@cast scrollFrame AceGUIScrollFrame
	scrollFrame:SetLayout("Flow")
	scrollContainer:AddChild(scrollFrame)
	return scrollContainer, scrollFrame
end

function PayoutProgressFramePrototype:UpdateProgressList()
	self.frames.scrollFrame:ReleaseChildren()
	self.frames.detailedPayoutListingLabels = {}
	for payout in self.payoutQueue:IteratePayouts() do
		local label = AceGUI:Create("Label")
		---@cast label AceGUILabel
		label:SetText(string.format("%s - %s", payout.player, GetCoinTextureString(payout.copper)))
		if type(payout.isPaid) == "boolean" then
			label:SetImage(payout.isPaid and PAID_IMAGE or UNPAID_IMAGE)
		else
			label:SetImage(DEFAULT_IMAGE)
		end
		label:SetFullWidth(true)
		label:SetJustifyV("MIDDLE")
		self.frames.scrollFrame:AddChild(label)
		self.frames.detailedPayoutListingLabels[payout.id] = label
	end
end

---@return AceGUIButton
function PayoutProgressFramePrototype:CreateStartButton()
	local button = AceGUI:Create("Button")
	---@cast button AceGUIButton
	button:SetText(L.start)
	button:SetCallback("OnClick", function()
		if not self.isPayoutInProgress then
			if MailFrame:IsVisible() then
				self:SetStartButtonState(true)
				self.callbacks:Fire("DoStartPayout", self)
			else
				addon.core:Print(L.must_be_at_mailbox)
			end
		else
			self:SetStartButtonState(false)
			self.callbacks:Fire("DoStopPayout", self)
		end
	end)
	return button
end

---@param isDown boolean
function PayoutProgressFramePrototype:SetStartButtonState(isDown)
	self.isPayoutInProgress = isDown
	if self.frames.frame then
		self.frames.startButton:SetText(isDown and L.pause or L.start)
		self.callbacks:Fire("OnStatusMessage", isDown and L.payout_in_progress or "")
	end
end

---@return AceGUIButton
function PayoutProgressFramePrototype:CreateDoneButton()
	local button = AceGUI:Create("Button")
	---@cast button AceGUIButton
	button:SetText(L.done)
	button:SetCallback("OnClick", function()
		self.callbacks:Fire("OnDone", self)
	end)
	return button
end

---@return AceGUIMultiLineEditBox
function PayoutProgressFramePrototype:CreateCSVBox()
	local editBox = AceGUI:Create("MultiLineEditBox")
	---@cast editBox AceGUIMultiLineEditBox
	editBox:SetLabel(L.unsent_mail)
	editBox:SetText(self.csv or "")
	editBox:SetFullWidth(true)
	editBox:SetFullHeight(true)
	editBox:DisableButton(true)
	editBox:SetCallback("OnTextChanged", function()
		editBox:SetText(self.csv or "")
	end)
	return editBox
end

function PayoutProgressFramePrototype:UpdateUnpaidCSV()
	local t = self:GetUnpaidTable()
	self.csv = addon.CSV.ToCSV(t)
	self.frames.csvBox:SetText(self.csv)
end

---@return string
function PayoutProgressFramePrototype:GetUnpaidCSV()
	return self.csv
end

---@return table
function PayoutProgressFramePrototype:GetUnpaidTable()
	local t = {}
	for payout in self.payoutQueue:IteratePayouts() do
		if not payout.isPaid then
			t[#t + 1] = { payout.player, payout.copper / self.unit }
		end
	end
	return t
end

---@return boolean
function PayoutProgressFramePrototype:IsVisible()
	return self.frames.frame ~= nil
end

function PayoutProgressFramePrototype:MarkPaid(payout)
	if self.frames.frame then
		local label = self.frames.detailedPayoutListingLabels[payout.id]
		if not label then error("Tried to change paid status of nonexistent label") end
		label:SetImage(PAID_IMAGE)
	end
end

function PayoutProgressFramePrototype:MarkUnpaid(payout)
	local label = self.frames.detailedPayoutListingLabels[payout.id]
	if not label then error("Tried to change paid status of nonexistent label") end
	label:SetImage(UNPAID_IMAGE)
end
