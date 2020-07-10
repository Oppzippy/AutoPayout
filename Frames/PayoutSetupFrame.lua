local AceGUI = LibStub("AceGUI-3.0")
local CallbackHandler = LibStub("CallbackHandler-1.0")

local PayoutSetupFramePrototype = {}
PayoutSetupFramePrototype.__index = PayoutSetupFramePrototype
HuokanPayout.PayoutSetupFrame = PayoutSetupFramePrototype

function PayoutSetupFramePrototype.Create()
	local frame = setmetatable({}, PayoutSetupFramePrototype)
	frame.callbacks = CallbackHandler:New(frame)
	frame.unit = 10000 -- 1 gold, TODO custom default unit
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
	self.frame:SetHeight(300)
	self.frame:EnableResize(false)
	self.frame:SetLayout("Flow")

	self.frame:SetTitle(HuokanPayout.L.payout_setup)

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

function PayoutSetupFramePrototype:CreatePasteBox()
	local editBox = AceGUI:Create("MultiLineEditBox")
	editBox:SetText(self.pasteBoxText or "")
	editBox:SetLabel(HuokanPayout.L.payout_csv)
	editBox:SetNumLines(6)
	editBox:SetMaxLetters(0)
	editBox:SetCallback("OnEnterPressed", function(_, _, text)
		self.callbacks:Fire("PayoutDataChanged", self, text, self.pasteBoxText)
		self.pasteBoxText = text
		self:UpdateStartButton()
	end)
	return editBox
end

do
	local function AddDropdownUnit(dropdown, copper)
		dropdown:AddItem(copper, GetCoinTextureString(copper))
	end

	function PayoutSetupFramePrototype:CreateUnitSelection()
		local dropdown = AceGUI:Create("Dropdown")
		dropdown:SetLabel(HuokanPayout.L.unit)
		AddDropdownUnit(dropdown, COPPER_PER_GOLD * 1000)
		AddDropdownUnit(dropdown, COPPER_PER_GOLD)
		AddDropdownUnit(dropdown, COPPER_PER_SILVER)
		AddDropdownUnit(dropdown, 1)
		dropdown:SetValue(self.unit)
		dropdown:SetCallback("OnValueChanged", function(_, _, key)
			self.unit = key
		end)
		return dropdown
	end
end

function PayoutSetupFramePrototype:CreateStartButton()
	local button = AceGUI:Create("Button")
	button:SetText(HuokanPayout.L.start_payout)
	button:SetCallback("OnClick", function()
		self.callbacks:Fire("StartPayout", self)
		self:Hide()
	end)
	return button
end

function PayoutSetupFramePrototype:UpdateStartButton()
	local success, err = pcall(function() HuokanPayout.PayoutQueue.ParseCSV(self.pasteBoxText) end)
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
		self.unitSelection = nil
		self.startButton = nil
	end
end

function PayoutSetupFramePrototype:IsVisible()
	return self.frame ~= nil
end

function PayoutSetupFramePrototype:GetPayments()
	local payments = HuokanPayout.PayoutQueue.ParseCSV(self.pasteBoxText)
	for player, copper in next, payments do
		payments[player] = copper * self.unit
	end
	return payments
end
