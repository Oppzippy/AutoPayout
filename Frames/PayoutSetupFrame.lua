---@class addon
local addon = select(2, ...)

local AceGUI = LibStub("AceGUI-3.0")
local CallbackHandler = LibStub("CallbackHandler-1.0")
local L = addon.L

---@class PayoutSetupFrame
---@field callbacks CallbackHandlerRegistry
---@field frames table
---@field pasteBoxText string
---@field RegisterCallback fun(self: table, eventName: string, method?: string)
---@field UnregisterCallback fun(self: table, eventName: string)
---@field UnregisterAllCallbacks fun(self: table)
local PayoutSetupFramePrototype = {}
addon.PayoutSetupFramePrototype = PayoutSetupFramePrototype

---@return PayoutSetupFrame
function PayoutSetupFramePrototype.Create()
	local frame = setmetatable({}, { __index = PayoutSetupFramePrototype })
	frame.callbacks = CallbackHandler:New(frame)
	frame.frames = {}
	frame.pasteBoxText = ""
	return frame
end

---@return AceGUISimpleGroup
function PayoutSetupFramePrototype:Show()
	return self:CreateFrame()
end

---@return AceGUISimpleGroup
function PayoutSetupFramePrototype:CreateFrame()
	local frame = AceGUI:Create("SimpleGroup")
	---@cast frame AceGUISimpleGroup
	self.frames.frame = frame
	frame:SetCallback("OnRelease", function()
		self.frames = {}
	end)
	frame:SetLayout("Flow")

	self.frames.subjectBox = self:CreateSubjectBox()
	self.frames.subjectBox:SetRelativeWidth(1)
	frame:AddChild(self.frames.subjectBox)

	self.frames.pasteBox = self:CreatePasteBox()
	self.frames.pasteBox:SetRelativeWidth(1)
	frame:AddChild(self.frames.pasteBox)

	self.frames.unitSelection = self:CreateUnitSelection()
	self.frames.unitSelection:SetRelativeWidth(1)
	frame:AddChild(self.frames.unitSelection)

	self.frames.startButton = self:CreateStartButton()
	self:UpdateStartButton()
	self.frames.startButton:SetRelativeWidth(1)
	frame:AddChild(self.frames.startButton)

	return frame
end

---@return AceGUIEditBox
function PayoutSetupFramePrototype:CreateSubjectBox()
	local editBox = AceGUI:Create("EditBox")
	---@cast editBox AceGUIEditBox
	editBox:SetText(self:GetSubject())
	editBox:SetLabel(L.subject)
	editBox:SetMaxLetters(64)
	editBox:SetCallback("OnEnterPressed", function(_, _, text)
		if #text == 0 then
			editBox:SetText(addon.core.db.profile.defaultSubject)
			self.subjectBoxText = nil
		else
			self.subjectBoxText = text
		end
	end)
	return editBox
end

---@return string
function PayoutSetupFramePrototype:GetSubject()
	return self.subjectBoxText or addon.core.db.profile.defaultSubject
end

---@return AceGUIMultiLineEditBox
function PayoutSetupFramePrototype:CreatePasteBox()
	local editBox = AceGUI:Create("MultiLineEditBox")
	---@cast editBox AceGUIMultiLineEditBox
	editBox:SetText(self.pasteBoxText or "")
	editBox:SetLabel(L.payout_csv)
	editBox:SetNumLines(6)
	editBox:SetMaxLetters(0)
	editBox:SetCallback("OnEnterPressed", function(_, _, text)
		self.callbacks:Fire("OnPayoutDataChanged", self, text, self.pasteBoxText)
		self.pasteBoxText = text
		self:UpdateStartButton()
	end)
	return editBox
end

---@return string
function PayoutSetupFramePrototype:GetCSV()
	return self.pasteBoxText or ""
end

do
	---@param dropdown AceGUIDropdown
	---@param copper number
	local function AddDropdownUnit(dropdown, copper)
		dropdown:AddItem(copper, C_CurrencyInfo.GetCoinTextureString(copper))
	end

	---@return AceGUIDropdown
	function PayoutSetupFramePrototype:CreateUnitSelection()
		local dropdown = AceGUI:Create("Dropdown")
		---@cast dropdown AceGUIDropdown
		dropdown:SetLabel(L.unit)
		AddDropdownUnit(dropdown, COPPER_PER_GOLD * 1000)
		AddDropdownUnit(dropdown, COPPER_PER_GOLD)
		AddDropdownUnit(dropdown, COPPER_PER_SILVER)
		AddDropdownUnit(dropdown, 1)
		dropdown:SetValue(self:GetUnit())
		dropdown:SetCallback("OnValueChanged", function(_, _, key)
			self.unit = key
		end)
		return dropdown
	end
end

---@return number
function PayoutSetupFramePrototype:GetUnit()
	return self.unit or addon.core.db.profile.defaultUnit
end

---@return AceGUIButton
function PayoutSetupFramePrototype:CreateStartButton()
	local button = AceGUI:Create("Button")
	---@cast button AceGUIButton
	button:SetText(L.next)
	button:SetCallback("OnClick", function()
		self.callbacks:Fire("OnStartPayout", self)
	end)
	return button
end

function PayoutSetupFramePrototype:UpdateStartButton()
	local success, result = pcall(function() return addon.PayoutQueuePrototype.ParseCSV(self.pasteBoxText) end)
	if success then
		self.frames.startButton:SetDisabled(#result == 0)
		self.callbacks:Fire("OnStatusMessage", "")
	else
		self.frames.startButton:SetDisabled(true)
		self.callbacks:Fire("OnStatusMessage", result and result.message or result)
	end
end

---@return boolean
function PayoutSetupFramePrototype:IsVisible()
	return self.frames.frame ~= nil
end

---@return table
function PayoutSetupFramePrototype:GetPayments()
	local csv = addon.PayoutQueuePrototype.ParseCSV(self.pasteBoxText)
	local payments = {}
	for i, payment in ipairs(csv) do
		payments[i] = {
			player = payment.player,
			copper = payment.copper * self:GetUnit(),
		}
	end
	return payments
end
