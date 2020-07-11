local EventHandler = {}

HuokanPayout.EventHandler = EventHandler

local frame = CreateFrame("Frame")
local callbacks = {}

frame:SetScript("OnEvent", function(_, event, ...)
	local eventCallbacks = callbacks[event]
	for self, callback in next, eventCallbacks do
		self[callback](self, event, ...)
	end
end)

local function RegisterEvent(self, event, callback)
	assert(type(self[callback]) == "function", "Callback function must be set")
	frame:RegisterEvent(event)
	if not callbacks[event] then callbacks[event] = {} end
	callbacks[event][self] = callback
end

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

local function UnregisterAllEvents(self)
	for event in next, callbacks do
		UnregisterEvent(self, event)
	end
end

function EventHandler.Embed(t)
	function t:RegisterEvent(event, callback)
		callback = callback or event
		RegisterEvent(self, event, callback)
	end

	function t:UnregisterEvent(event)
		UnregisterEvent(self, event)
	end

	function t:UnregisterAllEvents()
		UnregisterAllEvents(self)
	end
end
