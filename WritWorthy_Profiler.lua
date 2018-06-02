local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Define.lua

WritWorthy.Profiler = { stats = {} }
local Profiler = WritWorthy.Profiler

local function time_ms()
    return GetGameTimeMilliseconds()
end

function Profiler.GetStats(func_name)
    if not Profiler.stats[func_name] then
        Profiler.stats[func_name] = { call_ct  = 0
                                    , dur_ms   = 0
                                    , start_ms = 0
                                    }
    end
    return Profiler.stats[func_name]
end

function Profiler.Call(func_name)
    if not Profiler.enabled then return end
    local s    = Profiler.GetStats(func_name)
    s.call_ct  = s.call_ct + 1
    s.start_ms = time_ms()
end

function Profiler.End(func_name)
    if not Profiler.enabled then return end
    local s      = Profiler.GetStats(func_name)
    local dur_ms = time_ms() - s.start_ms
    s.dur_ms   = s.dur_ms + dur_ms
    s.start_ms = nil
end

function Profiler.Start()
    Profiler.enabled = true
    WritWorthy.savedVariables.profiler_stats = Profiler.stats
    d("Profiler enabled")
end

function Profiler.Stop()
    Profiler.enabled = false
    d("Profiler disabled")
end

