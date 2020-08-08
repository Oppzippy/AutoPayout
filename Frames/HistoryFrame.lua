local _, addon = ...

local AceGUI = LibStub("AceGUI-3.0")
local CallbackHandler = LibStub("CallbackHandler-1.0")
local L = addon.L

local HistoryFramePrototype = {}
HistoryFramePrototype.__index = HistoryFramePrototype
addon.HistoryFramePrototype = HistoryFramePrototype

function HistoryFramePrototype.Create()
	local frame = setmetatable({}, HistoryFramePrototype)
	frame.callbacks = CallbackHandler:New(frame)
	frame.frames = {}
	return frame
end

function HistoryFramePrototype:Show(history)
	self.history = history

	self.frame = self:CreateFrame()
	self:RenderRecords()
end

function HistoryFramePrototype:CreateFrame()
	local frame = AceGUI:Create("Frame")
	self.frames.frame = frame
	frame:SetCallback("OnClose", function(widget)
		self:Hide()
	end)
	frame:SetWidth(500)
	frame:SetHeight(600)
	frame:EnableResize(false)
	frame:SetLayout("Flow")

	frame:SetTitle(L.payout_history)

	self.frames.scrollContainer, self.frames.scrollFrame = self:CreateScrollFrame()
	frame:AddChild(self.frames.scrollContainer)

	return frame
end

function HistoryFramePrototype:CreateScrollFrame()
	local scrollContainer = AceGUI:Create("SimpleGroup")
	scrollContainer:SetFullWidth(true)
	scrollContainer:SetFullHeight(true)
	scrollContainer:SetLayout("Fill")
	local scrollFrame = AceGUI:Create("ScrollFrame")
	scrollFrame:SetLayout("Flow")
	scrollContainer:AddChild(scrollFrame)
	return scrollContainer, scrollFrame
end

function HistoryFramePrototype:RenderRecords()
	self.frames.scrollFrame:ReleaseChildren()
	for _, record in ipairs(self.history) do
		local frame = self:RenderRecord(record)
		frame:SetFullWidth(true)
		self.frames.scrollFrame:AddChild(frame)
	end
end

function HistoryFramePrototype:RenderRecord(record)
	local container = AceGUI:Create("InlineGroup")
	container:SetTitle(date(L.date_time, record.timestamp))
	container:SetLayout("flow")

	local inputBox = self:CreateRecordBox(L.input, record.input)
	local outputBox = self:CreateRecordBox(L.output, record.output or record.input)

	inputBox:SetRelativeWidth(0.5)
	outputBox:SetRelativeWidth(0.5)

	container:AddChild(inputBox)
	container:AddChild(outputBox)

	return container
end

function HistoryFramePrototype:CreateRecordBox(label, text)
	local box = AceGUI:Create("MultiLineEditBox")
	box:SetLabel(label)
	box:SetText(text)
	box:SetNumLines(3)
	box:DisableButton(true)
	box:SetCallback("OnTextChanged", function()
		box:SetText(text)
	end)
	return box
end

function HistoryFramePrototype:Hide()
	if self.frame then
		self.frame:Release()
		self.callbacks:Fire("OnClose")
	end
end
