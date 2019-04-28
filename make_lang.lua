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
OUT_FILE:write("WritWorthy.I18N = {}\n")

KEY_FMT = {
    static = "%-20.20s"
,   mat    = "%6d"
,   gear   = "%6d"
,   set    = "%6d"
}
for _,how_name in ipairs(sortedkeys(I18N)) do
    local key_fmt = KEY_FMT[how_name]
    OUT_FILE:write(string.format("\nWritWorthy.I18N['%s'] = {}\n",how_name))

    for _,lang in ipairs(sortedkeys(I18N[how_name])) do
        OUT_FILE:write(string.format( "WritWorthy.I18N['%s']['%s'] = {\n"
                                    , how_name
                                    , lang
                                    ))
        local kv      = I18N[how_name][lang]
        local lines   = {}
        for _,k in ipairs(sortedkeys(kv)) do
            if type(k) == "string" then k = string.format('"%s"', k) end
            local key_str = string.format(key_fmt, k)
            local val_str = kv[k]
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
