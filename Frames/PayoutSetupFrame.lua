local _, addon = ...

local AceGUI = LibStub("AceGUI-3.0")
local CallbackHandler = LibStub("CallbackHandler-1.0")
local L = addon.L

local PayoutSetupFramePrototype = {}
PayoutSetupFramePrototype.__index = PayoutSetupFramePrototype
addon.PayoutSetupFramePrototype = PayoutSetupFramePrototype

function PayoutSetupFramePrototype.Create()
	local frame = setmetatable({}, PayoutSetupFramePrototype)
	frame.callbacks = CallbackHandler:New(frame)
	return frame
end

function PayoutSetupFramePrototype:Show()
	self:CreateFrame()
end

function PayoutSetupFramePrototype:CreateFrame()
	self.frame = AceGUI:Create("Frame")
	self.frame:SetCallback("OnClose", function(widget)
		self:Hide()
	end)
	self.frame:SetWidth(500)
	self.frame:SetHeight(325)
	self.frame:EnableResize(false)
	self.frame:SetLayout("Flow")

	self.frame:SetTitle(L.payout_setup)

	self.subjectBox = self:CreateSubjectBox()
	self.subjectBox:SetRelativeWidth(1)
	self.frame:AddChild(self.subjectBox)

	self.pasteBox = self:CreatePasteBox()
	self.pasteBox:SetRelativeWidth(1)
	self.frame:AddChild(self.pasteBox)

	self.unitSelection = self:CreateUnitSelection()
	self.unitSelection:SetRelativeWidth(1)
	self.frame:AddChild(self.unitSelection)

	self.startButton = self:CreateStartButton()
	self:UpdateStartButton()
	self.startButton:SetRelativeWidth(1)
	self.frame:AddChild(self.startButton)
end

function PayoutSetupFramePrototype:CreateSubjectBox()
	local editBox = AceGUI:Create("EditBox")
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

function PayoutSetupFramePrototype:GetSubject()
	return self.subjectBoxText or addon.core.db.profile.defaultSubject
end

function PayoutSetupFramePrototype:CreatePasteBox()
	local editBox = AceGUI:Create("MultiLineEditBox")
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

function PayoutSetupFramePrototype:GetCSV()
	return self.pasteBoxText or ""
end

do
	local function AddDropdownUnit(dropdown, copper)
		dropdown:AddItem(copper, GetCoinTextureString(copper))
	end

	function PayoutSetupFramePrototype:CreateUnitSelection()
		local dropdown = AceGUI:Create("Dropdown")
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

function PayoutSetupFramePrototype:GetUnit()
	return self.unit or addon.core.db.profile.defaultUnit
end

function PayoutSetupFramePrototype:CreateStartButton()
	local button = AceGUI:Create("Button")
	button:SetText(L.next)
	button:SetCallback("OnClick", function()
		self.callbacks:Fire("OnStartPayout", self)
		self:Hide()
	end)
	return button
end

function PayoutSetupFramePrototype:UpdateStartButton()
	local success, err = pcall(function() addon.PayoutQueue.ParseCSV(self.pasteBoxText) end)
	self.startButton:SetDisabled(not success)
	if not success then
		self.frame:SetStatusText(err.message)
	else
		self.frame:SetStatusText("")
	end
end

function PayoutSetupFramePrototype:Hide()
	if self.frame then
		self.frame:Release()
		self.frame = nil
		self.pasteBox = nil
		self.subjectBox = nil
		self.unitSelection = nil
		self.startButton = nil
	end
end

function PayoutSetupFramePrototype:IsVisible()
	return self.frame ~= nil
end

function PayoutSetupFramePrototype:GetPayments()
	local csv = addon.PayoutQueue.ParseCSV(self.pasteBoxText)
	local payments = {}
	for i, payment in ipairs(csv) do
		payments[i] = {
			player = payment.player,
			copper = payment.copper * self:GetUnit(),
		}
	end
	return payments
end
