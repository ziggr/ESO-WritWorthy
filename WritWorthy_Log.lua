-- Record writ item links, inputs, and decisions.
--
-- Operate as a fixed-length queue of the N most recent writs.

local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Define.lua

WritWorthy.Log = {}

local Log = WritWorthy.Log

-- Event ---------------------------------------------------------------------
--
-- Group multiple log lines under a single umbreslla "event".
-- This reduces the number of LibDebugLogger records, by a LOT.
-- It also makes it much easier to read the log, see were each
-- writ's parse happened, and so on.

function Log:StartNewEvent(event_name, ...)
    if self.log_event then
        self:EndEvent()
    end
    local s = string.format(event_name or "--", ...)
    self.log_event = { s }
end

function Log:EndEvent()
    local s = table.concat(self.log_event, "\n.  ")
    self.log_event = nil
    Log.Verbose(s)
end

-- Append one value to the current event.
--
-- Single-arg overload just writes that value to the log.
-- Double-arg overload includes a name, so that you can write things
-- like "motif:" <motif data>
--
-- Values, if scalar, are written as is. If tables, the table is
-- expanded and written, usually as a single long line of key:value pairs.
--
function Log:Add(arg1, arg2)
    local name  = arg1
    local value = arg2
    if not value then
        name = ""
        value = arg1
    end

    if not self.log_event then
        self:StartNewEvent()
    end
    table.insert(self.log_event, Log:Flatten(name, value))
end

function Log:Flatten(name, value)
    local prefix = ""
    if name and name ~= "" then
        prefix = name..": "
    end

    if type(value) ~= "table" then
        return prefix..tostring(value)
    end

    local max_line_len = 0
    local lines        = {}
    local sorted_keys  = {}
    for k,v in pairs(value) do
        table.insert(sorted_keys, k)
    end
    table.sort(sorted_keys)
    for _,k in ipairs(sorted_keys) do
        local v    = value[k]
        local line = string.format("%s:%s",tostring(k), tostring(v))
        max_line_len = math.max(max_line_len, #line)
        table.insert(lines, line)
    end
                        -- Short enough to squeeze onto a single line?
                        -- Please do. The log is already way too long.
    if #lines < 10 and max_line_len < 80 then
        return prefix..table.concat(lines, "  ")
    end
                        -- Too long for one line. Return as lines.
    return prefix..table.concat(lines,"\n")
end

-- LibDebugLogger ------------------------------------------------------------

-- If Sirinsidiator's LibDebugLogger is installed, then return a logger from
-- that. If not, return a NOP replacement.

local NOP = {}
function NOP:Verbose(...) end
function NOP:Debug(...) end
function NOP:Info(...) end
function NOP:Warn(...) end
function NOP:Error(...) end

WritWorthy.log_to_chat            = false
WritWorthy.log_to_chat_warn_error = false

function WritWorthy.Logger()
    local self = WritWorthy
    if not self.logger then
        if LibDebugLogger then
            self.logger = LibDebugLogger.Create(self.name)
        end
        if not self.logger then
            self.logger = NOP
            WritWorthy.log_to_chat_warn_error  = true
        end
    end
    return self.logger
end

function WritWorthy.LogOne(color, ...)
    if WritWorthy.log_to_chat then
        d("|c"..color..WritWorthy.name..": "..string.format(...).."|r")
    end
end

function WritWorthy.LogOneWarnError(color, ...)
    if WritWorthy.log_to_chat or WritWorthy.log_to_chat_warn_error then
        d("|c"..color..WritWorthy.name..": "..string.format(...).."|r")
    end
end

function Log.Verbose(...)
    WritWorthy.LogOne("444444",...)
    WritWorthy.Logger():Verbose(...)
end

function Log.Debug(...)
    WritWorthy.LogOne("666666",...)
    WritWorthy.Logger():Debug(...)
end

function Log.Info(...)
    WritWorthy.LogOne("999999",...)
    WritWorthy.Logger():Info(...)
end

function Log.Warn(...)
    WritWorthy.LogOneWarnError("FF8800",...)
    WritWorthy.Logger():Warn(...)
end

function Log.Error(...)
    WritWorthy.LogOneWarnError("FF6666",...)
    WritWorthy.Logger():Error(...)
end
