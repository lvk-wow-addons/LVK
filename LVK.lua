LVK = {}
LVK["_colors"] = {
    ["r"] = "|cFFFF4040",
    ["g"] = "|cFF40FF40",
    ["b"] = "|cFF4040FF",
    ["w"] = "|cFFFFFFFF",
    ["y"] = "|cFFFFFF40",
    ["<"] = "|r"
}

LVK["_timers"] = {}
LVK["_timerValue"] = 0
LVK["_timerId"] = 0

function LVK:Debug(message)
    -- self:Print("|ydebug: " .. message)
end

function LVK:Error(message)
    self:Print("|rError: " .. message)
end

function LVK:Print(message)
    local result = ""

    local index = 1
    while index <= #message do
        local c = message:sub(index, index)
        index = index + 1

        if c == '|' then
            c = message:sub(index, index)
            index = index + 1

            local replacement = self._colors[c]
            if replacement then
                result = result .. replacement
            else
                result = result .. "|" .. c .. "?"
            end
        else
            result = result .. c
        end
    end

    DEFAULT_CHAT_FRAME:AddMessage(result)
end

function LVK:GetItemLink(item)
    return string.match(item, "|H(item[%-?%d:]+)|h")
end

function LVK:GetItemId(item)
    if not item then
        return nil
    end
    return tonumber(string.match(item, "item:(%d+)"))
end

function LVK:AnnounceAddon(addonId)
    self:Print("[|y" .. addonId .. "|<] v|g" .. GetAddOnMetadata(addonId, "version") .. "|< loaded")
end

function LVK:PreMacro()
    self:Debug("PreMacro")
    UIErrorsFrame:Hide()
    SetCVar("Sound_EnableErrorSpeech", 0)
end

function LVK:PostMacro()
    self:Debug("PostMacro")
    SetCVar("Sound_EnableErrorSpeech", 1)
    UIErrorsFrame:Clear()
    UIErrorsFrame:Show()
end

function LVK:AdvanceTimer(sinceLastUpdate)
    self._timerValue = self._timerValue + sinceLastUpdate
    while #self._timers > 0 and self._timerValue >= self._timers[1].n do
        local timer = self._timers[1]
        table.remove(self._timers, 1)

        local timeToNext = timer.f()
        if timeToNext and timeToNext > 0 then
            timer.n = timer.n + timeToNext
            table.insert(self._timers, timer)
            table.sort(self._timers, function(a, b) return a.n < b.n end)
        else
            self:Debug("timer with id " .. timer.id .. " removed, returned " .. (timeToNext or "nil"))
        end
    end
end

function LVK:AddTimer(fn, timeToFirst)
    self._timerId = self._timerId + 1
    local timer = {
        ["n"] = self._timerValue + timeToFirst,
        ["f"] = fn,
        ["id"] = self._timerId
    }
    table.insert(self._timers, timer)
    table.sort(self._timers, function(a, b) return a.n < b.n end)

    return timer.id
end

function LVK:RemoveTimer(timerId)
    for k, v in pairs(self._timers) do
        if v.id == timerId then
            table.remove(self._timers, k)
            return
        end
    end
end

function LVK:Retry(fn, timeToFirst, timeBetween)
    return LVK:AddTimer(function()
        if fn() then
            return -1
        else
            return timeBetween
        end
    end, timeToFirst)
end

function LVK:Repeat(fn, times, timeToFirst, timeBetween)
    local count = 0
    return LVK:AddTimer(function()
        count = count + 1
        if count > times then
            return -1
        else
            fn()
            return timeBetween
        end
    end, timeToFirst)
end

function LVK:Delay(fn, amount)
    return LVK:AddTimer(function()
        fn()
    end, amount)
end

function LVK:SplitLines(text)
    local lines = {}
    for line in text:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    return lines
end

function LVK:AssembleLines(lines)
    local result = ""
    for k, v in ipairs(lines) do
        if result ~= "" then
            result = result .. "\n"
        end
        result = result .. v
    end
    return result
end

function LVK:Test()
    AutoMacros:InventoryChanged()
end
