-- Read the SavedVariables file that GuildBankLedger creates  and convert
-- that to a spreadsheet-compabitle CSV (comma-separated value) file.

IN_FILE_PATH  = "../../SavedVariables/GuildBankLedger.lua"
OUT_FILE_PATH = "../../SavedVariables/GuildBankLedger.csv"
dofile(IN_FILE_PATH)
OUT_FILE = assert(io.open(OUT_FILE_PATH, "w"))

-- Lua lacks a split() function. Here's a cheesy hardwired one that works
-- for our specific need.
function split(str)
    local t1 = string.find(str, '\t')
    local t2 = string.find(str, '\t', 1 + t1)
    local t3 = string.find(str, '\t', 1 + t2)
    local t4 = string.find(str, '\t', 1 + t3)
    local t5 = string.find(str, '\t', 1 + t4)
    local t6 = string.find(str, '\t', 1 + t5)
    local t7 = string.find(str, '\t', 1 + t6)

    return   string.sub(str, 1,      t1 - 1)
           , string.sub(str, 1 + t1, t2 - 1)
           , string.sub(str, 1 + t2, t3 - 1)
           , string.sub(str, 1 + t3, t4 - 1)
           , string.sub(str, 1 + t4, t5 - 1)
           , string.sub(str, 1 + t5, t6 - 1)
           , string.sub(str, 1 + t6, t7 - 1)
           , string.sub(str, 1 + t7)
end

-- Parse the ["history'] table
function TableHistory(history)
                        -- Sort by guild name to avoid Lua table's tendency
                        -- to flip keys around randomly. Keep the file stable
                        -- for diffing and human sanity.
    for _, guild_name in pairs(sorted_keys(history)) do
        v = history[guild_name]
                        -- reverse alpha sort ISO 8601 dates will correctly
                        -- put most recent history to top and oldest history
                        -- to bottom of file.
        table.sort(v, function(a,b) return b < a end )
        for _,line in pairs(v) do
            local time_secs, user, trans_type, gold_ct
                , item_ct, item_name, item_link, item_mm = split(line)
            WriteLine( guild_name, time_secs, user, trans_type, gold_ct
                     , item_ct, item_name, item_link, item_mm)
        end
    end
end

-- Return table keys, sorted, as an array
function sorted_keys(tabl)
    keys = {}
    for k in pairs(tabl) do
        table.insert(keys, k)
    end
    table.sort(keys)
    return keys
end

function enquote(s)
    return '"' .. s .. '"'
end

function tonum(s)
    if not s or s == "" or s == "nil" then return "" end
    local n = tonumber(s)
    if not n then return "" end
    return n
end

function tostr(s)
    if not s or s == "" or s == "nil" then return "" end
    return enquote(s)
end

-- Convert "1456709816" to "2016-02-28T17:36:56" ISO 8601 formatted time
-- Assume "local machine time" and ignore any incorrect offsets due to
-- Daylight Saving Time transitions. Ugh.
function iso_date(secs_since_1970)
    t = os.date("*t", secs_since_1970)
    return string.format("%04d-%02d-%02dT%02d:%02d:%02d"
                        , t.year
                        , t.month
                        , t.day
                        , t.hour
                        , t.min
                        , t.sec
                        )
end

function WriteLine( guild_name, time_secs, user, trans_type, gold_ct
                  , item_ct, item_name, item_link, item_mm)
    OUT_FILE:write(
                    enquote (guild_name)
          .. ',' .. iso_date(time_secs)
          .. ',' .. enquote (trans_type)
          .. ',' .. enquote (user)
          .. ',' .. tonum   (gold_ct)
          .. ',' .. tonum   (item_ct)
          .. ',' .. tostr   (item_name)
          .. ',' .. tostr   (item_link)
          .. ',' .. tonum   (item_mm)
          .. '\n'
          )
end

-- Write header line
OUT_FILE:write(
                    enquote ("# guild_name" )
          .. ',' .. enquote ("time_secs" )
          .. ',' .. enquote ("trans_type" )
          .. ',' .. enquote ("user" )
          .. ',' .. enquote ("gold_ct" )
          .. ',' .. enquote ("item_ct" )
          .. ',' .. enquote ("item_name" )
          .. ',' .. enquote ("item_link" )
          .. ',' .. enquote ("item_mm" )
          .. '\n'
          )
-- For each account
for k, v in pairs(GuildBankLedgerVars["Default"]) do
    if (    GuildBankLedgerVars["Default"][k]["$AccountWide"]
        and GuildBankLedgerVars["Default"][k]["$AccountWide"]["history"]) then
        TableHistory(GuildBankLedgerVars["Default"][k]["$AccountWide"]["history"])
    end
end
OUT_FILE:close()

