-- This is needed instead of using AceEvent because AceEvent holds references to everything that it is embedded in,
-- so it will prevent those tables from getting garbage collected.

---@class addon
local addon = select(2, ...)

local EventHandler = {}
addon.EventHandler = EventHandler

local frame = CreateFrame("Frame")
local callbacks = {}

frame:SetScript("OnEvent", function(_, event, ...)
	local eventCallbacks = callbacks[event]
	for self, callback in next, eventCallbacks do
		self[callback](self, event, ...)
	end
end)

---@class EventHandler
---@field RegisterEvent fun(self: EventHandler, event: string, callback?: string)
---@field UnregisterEvent fun(self: EventHandler, event: string)
---@field UnregisterAllEvents fun(self: EventHandler)

---@param self table
---@param event string
---@param callback string
local function RegisterEvent(self, event, callback)
	assert(type(self[callback]) == "function", "Callback function must be set")
	frame:RegisterEvent(event)
	if not callbacks[event] then callbacks[event] = {} end
	callbacks[event][self] = callback
end

---@param self table
---@param event string
local function UnregisterEvent(self, event)
	local eventCallbacks = callbacks[event]
	if eventCallbacks and eventCallbacks[self] then
		eventCallbacks[self] = nil
		if not next(eventCallbacks) then
			frame:UnregisterEvent(event)
			callbacks[event] = nil
		end
	end
end

---@param self table
local function UnregisterAllEvents(self)
	for event, _ in next, callbacks do
		UnregisterEvent(self, event)
	end
end

---@param t table
---@param registerEventName? string
---@param unregisterEventName? string
---@param unregisterAllEventsName? string
function EventHandler.Embed(t, registerEventName, unregisterEventName, unregisterAllEventsName)
	registerEventName = registerEventName or "RegisterEvent"
	unregisterEventName = unregisterEventName or "UnregisterEvent"
	unregisterAllEventsName = unregisterAllEventsName or "UnregisterAllEvents"

	t[registerEventName] = function(self, event, callback)
		callback = callback or event
		RegisterEvent(self, event, callback)
	end

	t[unregisterEventName] = function(self, event)
		UnregisterEvent(self, event)
	end

	t[unregisterAllEventsName] = function(self)
		UnregisterAllEvents(self)
	end
end
