-- Read savedVariables data/WritWorthy.lua and write out lang/en.lua
--
-- The goal is to create an en.lua file whose output is reasonably
-- stable and easy to diff.

IN_FILE_PATH  = "data/WritWorthy.lua"
OUT_FILE_PATH = "lang/en2.lua"
dofile(IN_FILE_PATH)
OUT_FILE = assert(io.open(OUT_FILE_PATH,"w"))


I18N = WritWorthyVars["Default"]["@ziggr"]["$AccountWide"]["I18N"]

function sortedkeys(t)
    local keys = {}
    for k,v in pairs(t) do
        table.insert(keys,k)
    end
    table.sort(keys)
    return keys
end

OUT_FILE:write("local WritWorthy = _G['WritWorthy'] or {} -- defined in WritWorthy_Define.lua\n\n")
OUT_FILE:write("WritWorthy.I18N = WritWorthy.I18N or {}\n")

KEY_FMT = {
    static      = "%-40s"
,   client_si   = "%-30s"
,   fooddrink   = "%6d"
,   gear        = "%6d"
,   mat         = "%6d"
,   motif       = "%6d"
,   set         = "%6d"
,   shorten     = "%-30s"
}

local function sanitize(s)
    s = string.gsub(s,'"','\\"')
    s = string.gsub(s,'\n','\\n')
    return s
end

for _,how_name in ipairs(sortedkeys(I18N)) do
    local key_fmt = KEY_FMT[how_name]
    if not key_fmt then
        print(string.format("unknown how_name:'%s'", how_name))
        key_fmt = "%6d"
    end
    OUT_FILE:write(string.format("\nWritWorthy.I18N['%s'] = {}\n",how_name))

    for _,lang in ipairs(sortedkeys(I18N[how_name])) do
        OUT_FILE:write(string.format( "WritWorthy.I18N['%s']['%s'] = {\n"
                                    , how_name
                                    , lang
                                    ))
        local kv      = I18N[how_name][lang]
        local lines   = {}
        for _,k in ipairs(sortedkeys(kv)) do
            local key_str = string.format(key_fmt, k)
            if type(k) == "string" then
                key_str = string.format(key_fmt, '"'..k..'"')
            end
            local val_str = sanitize(kv[k])
            local line = string.format( '[%s] = "%s"'
                                      , key_str
                                      , val_str
                                      )
            table.insert(lines,line)
        end
        OUT_FILE:write("    ")
        OUT_FILE:write(table.concat(lines,"\n,   "))
        OUT_FILE:write("\n}\n")
    end

end
