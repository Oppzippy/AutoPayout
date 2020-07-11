local AceGUI = LibStub("AceGUI-3.0")
local CallbackHandler = LibStub("CallbackHandler-1.0")

local PayoutProgressFramePrototype = {}
PayoutProgressFramePrototype.__index = PayoutProgressFramePrototype
HuokanPayout.PayoutProgressFrame = PayoutProgressFramePrototype

local DEFAULT_IMAGE = "Interface\\RAIDFRAME\\ReadyCheck-Waiting"
local PAID_IMAGE = "Interface\\RAIDFRAME\\ReadyCheck-Ready"
local UNPAID_IMAGE = "Interface\\RAIDFRAME\\ReadyCheck-NotReady"

function PayoutProgressFramePrototype.Create()
	local frame = setmetatable({}, PayoutProgressFramePrototype)
	frame.callbacks = CallbackHandler:New(frame)
	frame.frames = {}
	return frame
end

function PayoutProgressFramePrototype:Show(payoutQueue)
	self.payoutQueue = payoutQueue

	local frames = self.frames
	frames.frame = self:CreateFrame()
	frames.scrollContainer, frames.scrollFrame = self:CreateDetailedProgressList()
	frames.frame:AddChild(frames.scrollContainer)

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

	frame:SetTitle(HuokanPayout.L.payout)

	local frames = self.frames

	frames.startButton = self:CreateStartButton()
	frames.startButton:SetRelativeWidth(0.5)
	frame:AddChild(frames.startButton)

	frames.doneButton = self:CreateDoneButton()
	frames.doneButton:SetRelativeWidth(0.5)
	frame:AddChild(frames.doneButton)

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
	for player, copper, isPaid in self.payoutQueue:IteratePayments() do
		local label = AceGUI:Create("Label")
		label:SetText(string.format("%s - %s", player, GetCoinTextureString(copper)))
		if type(isPaid) == "boolean" then
			label:SetImage(PAID_IMAGE or UNPAID_IMAGE)
		else
			label:SetImage(DEFAULT_IMAGE)
		end
		label:SetFullWidth(true)
		label:SetJustifyV("CENTER")
		self.frames.scrollFrame:AddChild(label)
		self.frames.detailedPayoutListingLabels[player] = label
	end
end

function PayoutProgressFramePrototype:CreateStartButton()
	local button = AceGUI:Create("Button")
	button:SetText(HuokanPayout.L.start)
	button:SetCallback("OnClick", function()
		if not self.isPayoutInProgress then
			self:SetStartButtonState(true)
			self.callbacks:Fire("StartPayout", self)
		else
			self:SetStartButtonState(false)
			self.callbacks:Fire("StopPayout", self)
		end
	end)
	return button
end

function PayoutProgressFramePrototype:SetStartButtonState(isDown)
	self.isPayoutInProgress = isDown
	self.frames.startButton:SetText(isDown and HuokanPayout.L.pause or HuokanPayout.L.start)
	self.frames.frame:SetStatusText(isDown and HuokanPayout.L.payout_in_progress or "")
end

function PayoutProgressFramePrototype:CreateDoneButton()
	local button = AceGUI:Create("Button")
	button:SetText(HuokanPayout.L.done)
	button:SetCallback("OnClick", function()
		self.callbacks:Fire("Done", self)
	end)
	return button
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

function PayoutProgressFramePrototype:MarkPaid(player)
	local label = self.frames.detailedPayoutListingLabels[player]
	if not label then error("Tried to change paid status of nonexistent label") end
	label:SetImage(PAID_IMAGE)
end

function PayoutProgressFramePrototype:MarkError(player)
	local label = self.frames.detailedPayoutListingLabels[player]
	if not label then error("Tried to change paid status of nonexistent label") end
	label:SetImage(UNPAID_IMAGE)
end
