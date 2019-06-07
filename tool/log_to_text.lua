--[[
Convert LibDebugLogger saved_vars to a text dump of just HomeStationMarker
log lines.
--]]

dofile("data/LibDebugLogger.lua")

WW  = "WritWorthy"
LDB = "LibDebugLogger"
INT = "Initializing..."

function StartsWith(longer, prefix)
   return longer:sub(1, #prefix) == prefix
end

for i,row in ipairs(LibDebugLoggerLog) do
    if row[5] == WW
        or row[5] == "UI"
        then
        print(row[4].." "..row[6])
    elseif row[5] == LDB and StartsWith(row[6], INT) then
        print("")
        print(row[2])
    end
end
