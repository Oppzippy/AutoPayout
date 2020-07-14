local _, addon = ...

local AceGUI = LibStub("AceGUI-3.0")
local CallbackHandler = LibStub("CallbackHandler-1.0")
local L = addon.L

local PayoutProgressFramePrototype = {}
PayoutProgressFramePrototype.__index = PayoutProgressFramePrototype
addon.PayoutProgressFrame = PayoutProgressFramePrototype

local DEFAULT_IMAGE = "Interface\\RAIDFRAME\\ReadyCheck-Waiting"
local PAID_IMAGE = "Interface\\RAIDFRAME\\ReadyCheck-Ready"
local UNPAID_IMAGE = "Interface\\RAIDFRAME\\ReadyCheck-NotReady"

function PayoutProgressFramePrototype.Create()
	local frame = setmetatable({}, PayoutProgressFramePrototype)
	frame.callbacks = CallbackHandler:New(frame)
	frame.frames = {}
	return frame
end

function PayoutProgressFramePrototype:GetUnit()
	return self.unit or addon.core.db.profile.defaultUnit
end

function PayoutProgressFramePrototype:SetUnit(unit)
	self.unit = unit
end

function PayoutProgressFramePrototype:Show(payoutQueue)
	self.payoutQueue = payoutQueue

	self.frames.frame = self:CreateFrame()

	self:UpdateProgressList()
end

function PayoutProgressFramePrototype:CreateFrame()
	local frame = AceGUI:Create("Frame")
	frame:SetCallback("OnClose", function(widget)
		self:Hide()
	end)
	frame:SetWidth(500)
	frame:SetHeight(600)
	frame:EnableResize(false)
	frame:SetLayout("Flow")

	frame:SetTitle(L.payout)

	local frames = self.frames

	frames.startButton = self:CreateStartButton()
	frames.startButton:SetRelativeWidth(0.5)
	frame:AddChild(frames.startButton)

	frames.doneButton = self:CreateDoneButton()
	frames.doneButton:SetRelativeWidth(0.5)
	frame:AddChild(frames.doneButton)

	frames.scrollContainer, frames.scrollFrame = self:CreateDetailedProgressList()
	frame:AddChild(frames.scrollContainer)

	frames.csvBox = self:CreateCSVBox()
	frame:AddChild(frames.csvBox)

	return frame
end

function PayoutProgressFramePrototype:CreateDetailedProgressList()
	local scrollContainer = AceGUI:Create("SimpleGroup")
	scrollContainer:SetFullWidth(true)
	scrollContainer:SetHeight(300)
	scrollContainer:SetLayout("Fill")
	local scrollFrame = AceGUI:Create("ScrollFrame")
	scrollFrame:SetLayout("Flow")
	scrollContainer:AddChild(scrollFrame)
	return scrollContainer, scrollFrame
end

function PayoutProgressFramePrototype:UpdateProgressList()
	self.frames.scrollFrame:ReleaseChildren()
	self.frames.detailedPayoutListingLabels = {}
	for payout in self.payoutQueue:IteratePayouts() do
		local label = AceGUI:Create("Label")
		label:SetText(string.format("%s - %s", payout.player, GetCoinTextureString(payout.copper)))
		if type(payout.isPaid) == "boolean" then
			label:SetImage(payout.isPaid and PAID_IMAGE or UNPAID_IMAGE)
		else
			label:SetImage(DEFAULT_IMAGE)
		end
		label:SetFullWidth(true)
		label:SetJustifyV("CENTER")
		self.frames.scrollFrame:AddChild(label)
		self.frames.detailedPayoutListingLabels[payout.id] = label
	end
end

function PayoutProgressFramePrototype:CreateStartButton()
	local button = AceGUI:Create("Button")
	button:SetText(L.start)
	button:SetCallback("OnClick", function()
		if not self.isPayoutInProgress then
			if MailFrame:IsVisible() then
				self:SetStartButtonState(true)
				self.callbacks:Fire("StartPayout", self)
			else
				addon.core:Print(L.error_must_be_at_mailbox)
			end
		else
			self:SetStartButtonState(false)
			self.callbacks:Fire("StopPayout", self)
		end
	end)
	return button
end

function PayoutProgressFramePrototype:SetStartButtonState(isDown)
	self.isPayoutInProgress = isDown
	self.frames.startButton:SetText(isDown and L.pause or L.start)
	self.frames.frame:SetStatusText(isDown and L.payout_in_progress or "")
end

function PayoutProgressFramePrototype:CreateDoneButton()
	local button = AceGUI:Create("Button")
	button:SetText(L.done)
	button:SetCallback("OnClick", function()
		self.callbacks:Fire("Done", self)
	end)
	return button
end

function PayoutProgressFramePrototype:CreateCSVBox()
	local editBox = AceGUI:Create("MultiLineEditBox")
	editBox:SetLabel(L.unsent_mail)
	editBox:SetText(self.csv or "")
	editBox:SetFullWidth(true)
	editBox:SetFullHeight(true)
	editBox:SetCallback("OnTextChanged", function()
		editBox:SetText(self.csv or "")
	end)
	return editBox
end

function PayoutProgressFramePrototype:UpdateCSV()
	local t = self:GetUnpaidTable()
	self.csv = addon.CSV.ToCSV(t)
	self.frames.csvBox:SetText(self.csv)
end

function PayoutProgressFramePrototype:GetUnpaidTable()
	local t = {}
	for payout in self.payoutQueue:IteratePayouts() do
		if not payout.isPaid then
			t[#t+1] = { payout.player, payout.copper / self.unit }
		end
	end
	return t
end

function PayoutProgressFramePrototype:Hide()
	if self.frames.frame then
		AceGUI:Release(self.frames.frame)
		self.frames = {}
	end
end

function PayoutProgressFramePrototype:IsVisible()
	return self.frames.frame ~= nil
end

function PayoutProgressFramePrototype:MarkPaid(payout)
	local label = self.frames.detailedPayoutListingLabels[payout.id]
	if not label then error("Tried to change paid status of nonexistent label") end
	label:SetImage(PAID_IMAGE)
end

function PayoutProgressFramePrototype:MarkUnpaid(payout)
	local label = self.frames.detailedPayoutListingLabels[payout.id]
	if not label then error("Tried to change paid status of nonexistent label") end
	label:SetImage(UNPAID_IMAGE)
end
