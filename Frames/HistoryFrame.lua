---@class addon
local addon = select(2, ...)

local AceGUI = LibStub("AceGUI-3.0")
local CallbackHandler = LibStub("CallbackHandler-1.0")
local L = addon.L

---@class HistoryFrame
---@field callbacks CallbackHandlerRegistry
---@field frames table
---@field RegisterCallback fun(self: table, eventName: string, method?: string)
---@field UnregisterCallback fun(self: table, eventName: string)
---@field UnregisterAllCallbacks fun(self: table)
local HistoryFramePrototype = {}
addon.HistoryFramePrototype = HistoryFramePrototype

---@return HistoryFrame
function HistoryFramePrototype.Create()
	local frame = setmetatable({}, { __index = HistoryFramePrototype })
	frame.callbacks = CallbackHandler:New(frame)
	frame.frames = {}
	return frame
end

---@param history table
---@return AceGUISimpleGroup
function HistoryFramePrototype:Show(history)
	self.history = history

	self.frame = self:CreateFrame()
	self:RenderRecords()
	return self.frame
end

function HistoryFramePrototype:CreateFrame()
	local frame = AceGUI:Create("SimpleGroup")
	---@cast frame AceGUISimpleGroup
	self.frames.frame = frame
	frame:SetCallback("OnRelease", function()
		self.callbacks:Fire("OnClose")
		self.frames = {}
	end)
	frame:SetLayout("Flow")

	self.frames.scrollContainer, self.frames.scrollFrame = self:CreateScrollFrame()
	frame:AddChild(self.frames.scrollContainer)

	return frame
end

---@return AceGUISimpleGroup
---@return AceGUIScrollFrame
function HistoryFramePrototype:CreateScrollFrame()
	local scrollContainer = AceGUI:Create("SimpleGroup")
	---@cast scrollContainer AceGUISimpleGroup
	scrollContainer:SetFullWidth(true)
	scrollContainer:SetFullHeight(true)
	scrollContainer:SetLayout("Fill")
	local scrollFrame = AceGUI:Create("ScrollFrame")
	---@cast scrollFrame AceGUIScrollFrame
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

---@param record table
---@return AceGUIInlineGroup
function HistoryFramePrototype:RenderRecord(record)
	local container = AceGUI:Create("InlineGroup")
	---@cast container AceGUIInlineGroup
	---@diagnostic disable-next-line: param-type-mismatch
	container:SetTitle(date(L.date_time, record.timestamp))
	container:SetLayout("Flow")

	local inputBox = self:CreateRecordBox(L.input, record.input)
	local outputBox = self:CreateRecordBox(L.output, record.output)

	inputBox:SetRelativeWidth(0.5)
	outputBox:SetRelativeWidth(0.5)

	container:AddChild(inputBox)
	container:AddChild(outputBox)

	return container
end

---@param label string
---@param text? string
---@return AceGUIMultiLineEditBox
function HistoryFramePrototype:CreateRecordBox(label, text)
	local box = AceGUI:Create("MultiLineEditBox")
	---@cast box AceGUIMultiLineEditBox
	box:SetLabel(label)
	box:SetText(text or "")
	box:SetNumLines(3)
	box:DisableButton(true)
	box:SetCallback("OnTextChanged", function()
		box:SetText(text or "")
	end)
	return box
end
