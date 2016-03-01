-- Read the SavedVariables file that GuildGoldDeposits creates  and convert
-- that to a spreadsheet-compabitle CSV (comma-separated value) file.

IN_FILE_PATH  = "../../SavedVariables/GuildGoldDeposits.lua"
OUT_FILE_PATH = "../../SavedVariables/GuildGoldDeposits.csv"
dofile(IN_FILE_PATH)
OUT_FILE = assert(io.open(OUT_FILE_PATH, "w"))

-- Lua lacks a split() function. Here's a cheesy hardwired one that works
-- for our specific need.
function split(str)
    t1 = string.find(str, '\t')
    t2 = string.find(str, '\t', 1 + t1)
    return   string.sub(str, 1,      t1 - 1)
           , string.sub(str, 1 + t1, t2 - 1)
           , string.sub(str, 1 + t2)
end

-- Parse the ["history'] table
function TableHistory(history)
    for k,v in pairs(history) do
        guild_name = k
        for _,line in pairs(v) do
            time_secs, amount, user = split(line)
            WriteLine(guild_name, time_secs, amount, user)
        end
    end
end

function enquote(s)
    return '"' .. s .. '"'
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

function WriteLine(guild_name, time_secs, amount, user)
    OUT_FILE:write(          enquote(guild_name)
          .. ',' .. iso_date(time_secs)
          .. ',' .. amount
          .. ',' .. enquote(user)
          .. '\n'
          )
end


-- For each account
for k, v in pairs(GuildGoldDepositsVars["Default"]) do
    if (    GuildGoldDepositsVars["Default"][k]["$AccountWide"]
        and GuildGoldDepositsVars["Default"][k]["$AccountWide"]["history"]) then
        TableHistory(GuildGoldDepositsVars["Default"][k]["$AccountWide"]["history"])
    end
end
OUT_FILE:close()

