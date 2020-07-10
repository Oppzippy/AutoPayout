local AceGUI = LibStub("AceGUI-3.0")
local CallbackHandler = LibStub("CallbackHandler-1.0")

local PayoutProgressFramePrototype = {}
PayoutProgressFramePrototype.__index = PayoutProgressFramePrototype
HuokanPayout.PayoutProgressFrame = PayoutProgressFramePrototype

local PAID_IMAGE = "Interface\\RAIDFRAME\\ReadyCheck-Ready"
local UNPAID_IMAGE = "Interface\\RAIDFRAME\\ReadyCheck-NotReady"

function PayoutProgressFramePrototype.Create()
	local frame = setmetatable({}, PayoutProgressFramePrototype)
	frame.callbacks = CallbackHandler:New(frame)
	return frame
end

function PayoutProgressFramePrototype:Show(payoutQueue)
	self.payoutQueue = payoutQueue

	self.frame = self:CreateFrame()
	self.scrollContainer, self.scrollFrame = self:CreateDetailedProgressList()
	self.frame:AddChild(self.scrollContainer)

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
	self.scrollFrame:ReleaseChildren()
	self.detailedPayoutListingLabels = {}
	for player, copper, isPaid in self.payoutQueue:IteratePayments() do
		local label = AceGUI:Create("Label")
		label:SetText(string.format("%s - %s", player, GetCoinTextureString(copper)))
		label:SetImage(isPaid and PAID_IMAGE or UNPAID_IMAGE)
		label:SetFullWidth(true)
		label:SetJustifyV("CENTER")
		self.scrollFrame:AddChild(label)
		self.detailedPayoutListingLabels[player] = label
	end
end

function PayoutProgressFramePrototype:Hide()
	if self.frame then
		AceGUI:Release(self.frame)
		self.frame = nil
		self.scrollContainer = nil
		self.scrollFrame = nil
		self.detailedPayoutListingLabels = nil
		self.payoutQueue = nil
	end
end

function PayoutProgressFramePrototype:IsVisible()
	return self.frame ~= nil
end

function PayoutProgressFramePrototype:MarkPaid(player)
	local label = self.detailedPayoutListingLabels[player]
	if not label then error("Tried to change paid status of nonexistent label") end
	label:SetImage(PAID_IMAGE)
end
