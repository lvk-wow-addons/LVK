LVK._eventHandlerId = 1

function LVK:EventHandler()
    local result = {
        _events = {},
        _frame = nil,
    }

    result.OnEvent = function(self, event, ...)
        local events = result._events[event]
        if events then
            for i = 1, #events do
                events[i](...)
            end
        end
    end

    result.RegisterEvent = function(events, handler)
        if result._frame == nil then
            result._frame = CreateFrame("FRAME", "LVK_Frame_" .. LVK._eventHandlerId)
            LVK._eventHandlerId = LVK._eventHandlerId + 1

            result._frame:SetScript("OnEvent", result.OnEvent)
        end

        if type(events) == "string" then
            events = { events }
        end

        for i = 1, #events do
            local event = events[i]

            if not result._events[event] then
                result._frame:RegisterEvent(event)
                result._events[event] = {}
            end
            table.insert(result._events[event], handler)
        end
    end

    result.UnregisterEvent = function(events)
        if type(events) == "string" then
            events = { events }
        end

        for i = 1, #events do
            local event = events[i]

            if result._events[event] then
                result._frame:UnregisterEvent(event)
                result._events[event] = nil
            end
        end
    end

    return result
end