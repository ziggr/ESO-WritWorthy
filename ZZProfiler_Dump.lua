IN_FILE_PATH  = "../../SavedVariables/WritWorthy.lua"
dofile(IN_FILE_PATH)

local profiler_stats = WritWorthyVars["Default"]["@ziggr"]["$AccountWide"]["profiler_stats"]

local flat = {}

for func_name, s in pairs(profiler_stats) do
    local row = { func_name = func_name
                , call_ct = s.call_ct
                , dur_ms  = s.dur_ms
                }
    table.insert(flat, row)
end

table.sort(flat, function(a,b) return a.dur_ms > b.dur_ms end )

print("# dur_ms\tcall_ct\tfunc")
for _, row in ipairs(flat) do
    print(string.format("%4d\t%4d\t%s"
                       , row.dur_ms
                       , row.call_ct
                       , row.func_name
                       ))
end
