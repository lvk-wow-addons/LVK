LVK = {}
LVK["ColorCodes"] = {
    ["r"] = "|cFFFF0000",
    ["R"] = "|cFFFF8080",
    ["g"] = "|cFF00FF00",
    ["G"] = "|cFF80FF80",
    ["b"] = "|cFF0000FF",
    ["B"] = "|cFF8080FF",
    ["w"] = "|cFFFFFFFF",
    ["W"] = "|cFFFFFFFF",
    ["y"] = "|cFFFFFF00",
    ["Y"] = "|cFFFFFF80",
    ["<"] = "|r"
}

LVK["_timers"] = {}
LVK["_timerValue"] = 0
LVK["_timerId"] = 0
LVK["_status"] = {}
LVK["_debug"] = false
LVK["_next"] = {}

function LVK:Debug(message)
    if LVK["_debug"] then
        self:Print("|y|debug: " .. message)
    end
end

function LVK:Error(message)
    self:Print("|r|Error: " .. message)
end

function LVK:OnNext(key, action)
    if LVK["_next"][key] or false then
        LVK["_next"][key] = false
        if type(action) == "function" then
            action()
        else
            LVK:Dump(action, key)
        end
    end
end

function LVK:TriggerNext(key)
    LVK["_next"][key] = true
end

function LVK:Status(key, value)
    if (not LVK["_status"][key]) or (LVK["_status"][key] ~= value) then
        LVK["_status"][key] = value
        LVK:Debug("|y|" .. key .. "|<| = |g|" .. value .. "|<|")
    end
end

function LVK:Colorize(msg, ...)
    if msg == nil then
        return "<nil>"
    end
    if type(msg) ~= "string" then
        msg = tostring(msg)
    end
    local result = ""
    local i = 1
    local oldI = 0
    while i <= #msg do
        if oldI == i then
            break
        end
        oldI = i

        local c = msg:sub(i, i)

        if c == "|" then
            local code = ""

            while i < #msg do
                i = i + 1
                c = msg:sub(i, i)
                if c == "|" then
                    i = i + 1
                    break
                end
                code = code .. c
            end
            result = result .. (LVK.ColorCodes[code] or ("|" .. code .. "|"))
        else
            result = result .. c
            i = i + 1
        end
    end

    if #{...} > 0 then
        result = string.format(result, ...)
    end
    return result
end


function LVK:Print(message, ...)
    DEFAULT_CHAT_FRAME:AddMessage(self:Colorize(message, ...))
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
    self:Print("[|y|" .. addonId .. "|<|] v|g|" .. C_AddOns.GetAddOnMetadata(addonId, "version") .. "|<| loaded")
end

function LVK:PreMacro()
    self:Debug("PreMacro")
    UIErrorsFrame:Hide()
    SetCVar("Sound_EnableErrorSpeech", 0)
end

function LVK:FormatString(str)
    local output = ""
    for i = 1, #str do
        local c = str:sub(i, i)
        if c == "\"" then
            output = output .. "\\" .. c
        elseif c == "\n" then
            output = output .. "\\n"
        elseif c == "\r" then
            output = output .. "\\r"
        elseif c == "\\" then
            output = output .. "\\\\"
        elseif c == "\a" then
            output = output .. "\\a"
        elseif c == "\b" then
            output = output .. "\\b"
        elseif c == "\f" then
            output = output .. "\\f"
        elseif c == "\t" then
            output = output .. "\\t"
        elseif c == "\v" then
            output = output .. "\\v"
        elseif c == '|' then
            output = output .. "||"
        else
            output = output .. c
        end
    end
    return "\"" .. output .. "\""
end

function LVK:DebugDump(obj, name)
    if LVK["_debug"] then
        self:Dump(obj, self:Colorize("|y|DEBUG: |<|" .. (name or "value")))
    end
end

function LVK:GetItemString(itemLink)
    return string.match(itemLink, "item[%-?%d:]+")
end

function LVK:SplitSlash(str)
    local result = { }

    local quote = " "

    local i = 1
    local oldI = 0
    local current = ""
    while i <= #str do
        if oldI == i then
            self:DebugPrint("SplitSlash terminated early, did not advance from position %d in %s", i, self:FormatString(str))
            break
        end
        oldI = i

        local c = str:sub(i, i)
        if quote ~= " " then
            if c == quote then
                quote = " "
                i = i + 1
            else
                current = current .. c
                i = i + 1
            end
        else
            if c == "\"" or c == "\'" then
                quote = c
                i = i + 1
            elseif c == " " then
                if current ~= "" then
                    table.insert(result, current)
                    current = ""
                end
                i = i + 1
            else
                current = current .. c
                i = i + 1
            end
        end
    end
    if current ~= "" then
        table.insert(result, current)
    end

    local index = 1
    while index < #result do
        if string.find(result[index], "|Hitem:") ~= nil then
            local itemLink = result[index]
            index = index + 1
            while index < #result do
                itemLink = itemLink .. " " .. result[index]
                table.remove(result, index)

                if string.find(itemLink, "|h|r") then
                    break
                end
            end
            result[index - 1] = itemLink
        else
            index = index + 1
        end
    end
    return result
end

function LVK:ExecuteSlash(str, frame)
    local parts = self:SplitSlash(str)

    if #parts >= 1 then
        local name = string.upper(parts[1]):sub(1, 1) .. string.lower(parts[1]:sub(2, #parts[1]))

        local functionName = "Slash_" .. name

        local exceptFirst = {unpack(parts)}
        table.remove(exceptFirst, 1)
    
        if frame[functionName] then
            frame[functionName](frame, exceptFirst)
            return true
        end

        if frame["Slash_Default"] then
            frame["Slash_Default"](frame, exceptFirst)
            return true
        end

        if frame["Slash_Help"] then
            self:Print("|r|Invalid command: |<| '|y|%s|<|', use '|y|help|<|' command for help on syntax and usage", str)
        end

        return false
    end
end

function LVK:SetDebug(onOff)
    LVK["_debug"] = onOff
end

function LVK:ShowHelp(tbl, key)
    local help = tbl[key]
    if not help then
        self:Error("No help key '|y|%s|<|'", key)
        return
    end

    if type(help) == "table" then
        for _, v in ipairs(help) do
            self:Print(v)
        end
    else
        self:Print(help)
    end
end

function LVK:Dump(obj, name)
    local already = {}

    local toString = function(value)
        if (type(value) == string) then
            return self:FormatString(value)
        else
            return tostring(value)
        end
    end

    local dump

    local dumpers = {
        ["string"] = function(prefix, str, indent)
            self:Print("%s = %s", prefix, self:FormatString(str))
        end,
        ["number"] = function(prefix, num, indent)
            if num == math.floor(num) then
                self:Print("%s = %d (0x%x)", prefix, num, num)
            else
                self:Print("%s = %f", prefix, num)
            end
        end,
        ["table"] = function(prefix, tbl, indent)
            if already[tbl] then
                self:Print("%s = %s (already dumped)", prefix, toString(tbl))
                return
            end
            already[obj] = true

            self:Print("%s = %s", prefix, toString(tbl))
            self:Print("%s{", indent:sub(1, #indent - 2))
            local any = false
            for key, value in pairs(tbl) do
                dump(value, toString(key), indent .. "  ")
                any = true
            end
            if not any then
                for key, value in ipairs(tbl) do
                    dump(value, toString(key), indent .. "  ")
                end
            end
            self:Print("%s}", indent:sub(1, #indent - 2))
        end,
    }

    dump = function(obj, name, indent)
        if type(name) ~= "string" then
            name = tostring(name)
        end
        local prefix = string.format("%s%s: %s", indent, name, type(obj))

        if obj == nil then
            self:Print("%s = nil", prefix)
            return
        end

        dumper = dumpers[type(obj)]
        if dumper ~= nil then
            dumper(prefix, obj, indent .. "  ")
        else
            if already[obj] then
                self:Print("%s = %s (already dumped)", prefix, toString(obj))
                return
            end
            already[obj] = true
            self:Print("%s = %s", prefix, tostring(obj))
        end
    end

    dump(obj, name or "value", "")
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

LVK:AnnounceAddon("LVK")
RegisterStateDriver(ObjectiveTrackerFrame, "visibility", "[nocombat] show; hide")