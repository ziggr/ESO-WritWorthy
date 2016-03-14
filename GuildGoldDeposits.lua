local LAM2 = LibStub("LibAddonMenu-2.0")

local GuildGoldDeposits = {}
GuildGoldDeposits.name            = "GuildGoldDeposits"
GuildGoldDeposits.version         = "2.3.5.1"
GuildGoldDeposits.savedVarVersion = 2
GuildGoldDeposits.default = {
      enable_guild  = { true, true, true, true, true }
    , history = {}
}
GuildGoldDeposits.max_guild_ct = 5

                        -- event_list[guild_index] = { list of event strings }
                        -- loaded from the current "Save Now" run.
                        -- Eventually these become the front part of
                        -- savedVariables.guild_history[guildName]
GuildGoldDeposits.event_list = {}
GuildGoldDeposits.guild_name = {} -- guild_name[guild_index] = "My Aweseome Guild"

                        -- retry_ct[guild_index] = how many retries after
                        -- distrusting "nah, no more history"
GuildGoldDeposits.retry_ct   = { 0, 0, 0, 0, 0 }
GuildGoldDeposits.max_retry_ct = 3


                        -- how many days to store in SavedVariables
                        -- (not yet implemented)
GuildGoldDeposits.max_day_ct = 30

                        -- Latches true when responding to the very first
                        -- "Save Data Now" event so that we don't spin forever.
GuildGoldDeposits.debug_brakes = false

local TIMESTAMPS_CLOSE_SECS = 10

-- Indices into the 3-element "event" split.
local I_TIMESTAMP = 1
local I_AMOUNT    = 2
local I_USER      = 3

-- Event ---------------------------------------------------------------------
-- One row in our savedVariables history
--
-- Knows how to convert to/from string
-- Knows how to convert from GetGuildEventInfo().
-- Named fields instead of table indices.
--
local Event = {}

-- If this is a gold deposit, return a row. If not, return nil.
function Event:FromInfo(event_type, since_secs, user, amount)
    if event_type ~= GUILD_EVENT_BANKGOLD_ADDED then return nil end
    o = { time   = GetTimeStamp() - since_secs
        , user   = user
        , amount = amount
        }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Event:FromString(str)
    ts, amt, user = GuildGoldDeposits:split(str)
    o = { time   = ts
        , amount = amt
        , user   = user
        }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Event:ToString()
                        -- tab-delimited fields
                        -- date     seconds since the epoch
                        -- amount
                        -- user     unquoted, can contain all sorts of
                        --          noise but unlikely to contian a
                        --          tab character.
                        --
                        -- using tostring() here so that this function can work
                        -- when debugging nil event elements.
    return tostring(self.time)
            .. '\t' .. tostring(self.amount)
            .. '\t' .. tostring(self.user)
end

-- Do these events "match"?
--
-- User and amount must be exact.
-- Time must be within N seconds.
function Event.Match(a, b)
    -- d("em f=" .. a:ToString())
    -- d("em s=" .. b:ToString())
                        -- ### Eventually this needs to short-circuit
                        -- ### Leaving it inefficient for now nur zum Debuggen.
    m1 =  math.abs(a.time - b.time) < TIMESTAMPS_CLOSE_SECS
    m2 = a.amount == b.amount
    m3 = a.user   == b.user
    -- d("em m=" .. tostring(m1) .. " " .. tostring(m2) .. " " .. tostring(m3))
    return m1 and m2 and m3
end

-- Init ----------------------------------------------------------------------

function GuildGoldDeposits.OnAddOnLoaded(event, addonName)
    if addonName ~= GuildGoldDeposits.name then return end
    if not GuildGoldDeposits.version then return end
    if not GuildGoldDeposits.default then return end
    GuildGoldDeposits:Initialize()
end

function GuildGoldDeposits:Initialize()
    self.savedVariables = ZO_SavedVars:NewAccountWide(
                              "GuildGoldDepositsVars"
                            , self.savedVarVersion
                            , nil
                            , self.default
                            )
    self:CreateSettingsWindow()
    --EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)
end

-- Return false only once.
-- Avoids infinite invocations.
function GuildGoldDeposits:BrakesOn()
    return false
    -- if self.debug_brakes then
    --     return true
    -- else
    --     self.debug_brakes = true
    --     return false
    -- end
end

-- UI ------------------------------------------------------------------------

function GuildGoldDeposits.ref_cb(guild_index)
    return "GuildGoldDeposits_cbg" .. guild_index
end

function GuildGoldDeposits.ref_desc(guild_index)
    return "GuildGoldDeposits_desc" .. guild_index
end

function GuildGoldDeposits:CreateSettingsWindow()
    local panelData = {
        type                = "panel",
        name                = "Guild Gold Deposits",
        displayName         = "Guild Gold Deposits",
        author              = "ziggr",
        version             = self.version,
        slashCommand        = "/gg",
        registerForRefresh  = true,
        registerForDefaults = false,
    }
    local cntrlOptionsPanel = LAM2:RegisterAddonPanel( self.name
                                                     , panelData
                                                     )
    local optionsData = {
        { type      = "button"
        , name      = "Save Data Now"
        , tooltip   = "Save guild gold deposit data to file now."
        , func      = function() self:SaveNow() end
        },
        { type      = "header"
        , name      = "Guilds"
        },
    }

    for guild_index = 1, self.max_guild_ct do
        table.insert(optionsData,
            { type      = "checkbox"
            , name      = "(guild " .. guild_index .. ")"
            , tooltip   = "Save data for guild " .. guild_index .. "?"
            , getFunc   = function()
                            return self.savedVariables.enable_guild[guild_index]
                          end
            , setFunc   = function(e)
                            self.savedVariables.enable_guild[guild_index] = e
                          end
            , reference = self.ref_cb(guild_index)
            })
                        -- HACK: for some reason, I cannot get "description"
                        -- items to dynamically update their text. Color and
                        -- hidden, yes, but text? Nope, it never changes. So
                        -- instead of a desc for static text, I'm going to use
                        -- a "checkbox" with the on/off field hidden. Total
                        -- hack. Sorry.
        table.insert(optionsData,
            { type      = "checkbox"
            , name      = "(desc " .. guild_index .. ")"
            , reference = self.ref_desc(guild_index)
            , getFunc   = function() return false end
            , setFunc   = function() end
            })
    end

    LAM2:RegisterOptionControls("GuildGoldDeposits", optionsData)
    CALLBACK_MANAGER:RegisterCallback("LAM-PanelControlsCreated"
            , self.OnPanelControlsCreated)
end

-- Delay initialization of options panel: don't waste time fetching
-- guild names until a human actually opens our panel.
function GuildGoldDeposits.OnPanelControlsCreated(panel)
    self = GuildGoldDeposits
    guild_ct = GetNumGuilds()
    for guild_index = 1,self.max_guild_ct do
        cb = _G[self.ref_cb(guild_index)]
        if guild_index <= guild_ct then
            guildId   = GetGuildId(guild_index)
            guildName = GetGuildName(guildId)
            cb.label:SetText(guildName)
            cb:SetHidden(false)
            self.guild_name[guild_index] = guildName
        else
                        -- If no guild #N, hide and disable it.
            cb:SetHidden(true)
            self.savedVariables.enable_guild[guild_index] = false
        end

        desc = _G[self.ref_desc(guild_index)]
        self.ConvertCheckboxToText(desc)
        self:SetStatusNewest(guild_index)
    end
end

-- Coerce a checkbox to act like a text label.
--
-- I cannot get LibAddonMenu-2.0 "description" items to dynamically update
-- their text. SetText() has no effect. But SetText() works on "checkbox"
-- items, so beat those into a text-like UI element.
function GuildGoldDeposits.ConvertCheckboxToText(cb)
    desc:SetHandler("OnMouseEnter", nil)
    desc:SetHandler("OnMouseExit",  nil)
    desc:SetHandler("OnMouseUp",    nil)
    desc.label:SetFont("ZoFontGame")
    desc.label:SetText("-")
    desc.checkbox:SetHidden(true)
end

-- Display Status ------------------------------------------------------------

-- Update the per-guild text label with what's going on with that guild data.
function GuildGoldDeposits:SetStatus(guild_index, msg)
    desc = _G[self.ref_desc(guild_index)].label
    desc:SetText("  " .. msg)
    d("status " .. tostring(guild_index) .. ":" .. tostring(msg))
end

-- Set status to "Newest: @user 100,000g  11 hours ago"
function GuildGoldDeposits:SetStatusNewest(guild_index)
    line = self:SavedHistoryNewest(guild_index)
    if not line then return end
    event = self:StringToEvent(line)
    now_ts = GetTimeStamp()
    ago_secs = GetDiffBetweenTimeStamps(now_ts, event.time)
    ago_str  = FormatTimeSeconds(ago_secs
                    , TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE -- "22 hours"
                    , TIME_FORMAT_PRECISION_SECONDS
                    , TIME_FORMAT_DIRECTION_DESCENDING
                    )

    self:SetStatus(guild_index, "Newest deposit: " .. event.user
                     .. " " .. event.amount .. "g  " .. ago_str .. " ago")
end

-- Parse/Format SavedVariables history ----------------------------------------

-- Lua lacks a split() function. Here's a cheesy hardwired one that works
-- for our specific need.
function GuildGoldDeposits:split(str)
    t1 = string.find(str, '\t')
    t2 = string.find(str, '\t', 1 + t1)
    return   string.sub(str, 1,      t1 - 1)
           , string.sub(str, 1 + t1, t2 - 1)
           , string.sub(str, 1 + t2)
end

-- Convert an event to a compact string that a line-parser can easily consume.
function GuildGoldDeposits:EventToString(event)
                        -- tab-delimited fields
                        -- date     seconds since the epoch
                        -- amount
                        -- user     unquoted, can contain all sorts of
                        --          noise but unlikely to contian a
                        --          tab character.
                        --
                        -- using tostring() here so that this function can work
                        -- when debugging nil event elements.
    return tostring(event.time)
            .. '\t' .. tostring(event.amount)
            .. '\t' .. tostring(event.user)
end

function GuildGoldDeposits:StringToEvent(str)
    ts, amt, user = self:split(str)
    return { time   = ts
           , amount = amt
           , user   = user
           }
end

-- Return the one newest history line, if any, from our previous save.
-- Return nil if not.
function GuildGoldDeposits:SavedHistoryNewest(guild_index)
    guildName = GetGuildName(guildId)
    if not self.savedVariables then return nil end
    if not self.savedVariables.history then return nil end
    history = self.savedVariables.history[guildName]
    if not history then return nil end
    if not (1 <= #history) then return nil end
    return history[1]
end

-- Fetch Guild Data from the server ------------------------------------------
--
-- Fetch _all_ events for each guild. Server holds no more than 10 days, no
-- more than 500 events.
--
-- Defer per-event iteration until fetch is complete. This might help reduce
-- the clock skew caused by the items using relative time, but relative
-- to _what_?

function GuildGoldDeposits:SaveNow()
    self.event_list = {}
    for guild_index = 1, self.max_guild_ct do
        if self.savedVariables.enable_guild[guild_index] then
            self:SaveGuildIndex(guild_index)
        else
            self:SkipGuildIndex(guild_index)
        end
    end
end

-- User doesn't want this guild. Respond with "okay, skipping"
function GuildGoldDeposits:SkipGuildIndex(guild_index)
    self:SetStatus(guild_index, "skipped")
end

-- Download one guild's history
function GuildGoldDeposits:SaveGuildIndex(guild_index)
    guildId = GetGuildId(guild_index)
    self:SetStatus(guild_index, "downloading history...")
    event_ct = 0
    found_ct = 0
    loop_ct = 0
    loop_max = 100
    RequestGuildHistoryCategoryNewest(guildId, GUILD_HISTORY_BANK)

                        -- Start an asynchronous callback chain to slowly
                        -- poll ESO servers for all history. Chain will
                        -- callback itself until done, then callback
                        -- into the actual processing of that data.
    self:ServerDataPoll(guild_index)
end

-- Async poll to fetch ALL guild bank history data from the ESO server
-- Calls ServerDataComplete() once all data is loaded.
function GuildGoldDeposits:ServerDataPoll(guild_index)
    guildId = GetGuildId(guild_index)
    more = DoesGuildHistoryCategoryHaveMoreEvents(guildId, GUILD_HISTORY_BANK)
    event_ct = GetNumGuildEvents(guildId, GUILD_HISTORY_BANK)
    self:SetStatus(guild_index, "fetching events: " .. event_ct .. " ...")
    can_retry =    (not self.retry_ct[guild_index])
                or (self.retry_ct[guild_index] < self.max_retry_ct)
    if more or can_retry then
        RequestGuildHistoryCategoryOlder(guildId, GUILD_HISTORY_BANK)
        delay_ms = 0.5 * 1000
        zo_callLater(function() self:ServerDataPoll(guild_index) end, delay_ms)
        if not more then
            self.retry_ct[guild_index] = 1 + self.retry_ct[guild_index]
        end
    else
        self:ServerDataComplete(guild_index)
    end
end

-- Now that all data from the ESO server is loaded into the ESO client,
-- extract gold deposits and write to savedVars.
function GuildGoldDeposits:ServerDataComplete(guild_index)
    if self:BrakesOn() then return end

    guildId = GetGuildId(guild_index)
    guild_name = self.guild_name[guild_index]
    event_ct = GetNumGuildEvents(guildId, GUILD_HISTORY_BANK)
    --self:SetStatus(guild_index, "scanning events: " .. event_ct .. " ...")
    for i = 1, event_ct do
        t, s, u, a = GetGuildEventInfo(guildId, GUILD_HISTORY_BANK, i)
        event = Event:FromInfo(t, s, u, a)
        if event then
            self:RecordEvent(guild_index, event)
        end
    end
    found_ct = 0
    if self.event_list[guild_index] then
        found_ct = #self.event_list[guild_index]
    end
    self:SetStatus(guild_index, "scanned events: " .. event_ct
                   .. "  gold deposits: " .. found_ct)
    saved_history = {}
    if not self.savedVariables.history then
        self.savedVariables.history = {}
    end
    if self.savedVariables.history[guild_name] then
        saved_history = self.savedVariables.history[guild_name]
        if 0 < #saved_history and not saved_history[1] then
            d("sdc ### Just loaded the badness")
        end
    end
    r = self:MergeHistories( self.event_list[guild_index]
                           , saved_history
                           , guild_index )
    self.savedVariables.history[guild_name] = r
    d("sdc "..tostring(guild_index).."[\""..tostring(guild_name).."\"]"
      .." = "..tostring(#r) .. " events")
end

function GuildGoldDeposits:RecordEvent(guild_index, event)
    if not self.event_list[guild_index] then
        self.event_list[guild_index] = {}
    end
    t = self.event_list[guild_index]
    table.insert(t, event:ToString())
end

-- Merging saved and fetched history -----------------------------------------

-- Return a new list composed of all of "fetched", and the latter portion of
-- "saved" that comes after "fetched", but not older than max_day_ct
function GuildGoldDeposits:MergeHistories(fetched, saved, guild_index)
    -- Where in "saved" does "fetch" end?

                        -- No saved events? Just use whatever we fecthed.
                        -- If we fetched nothing at all, retain saved
                        -- unchanged. If nothing saved, return fetch unchanged.
                        -- Don't even bother to strip older events. Something's
                        -- probably gone wrong (or the guild has gone very,
                        -- very, quiet).
    if 0 == #fetched  then
        self:SetStatus(guild_index, "no new events")
        if 0 < #saved and not saved[1] then
            d("mh ### just returned the badness")
        end
        return saved
    end
    if 0 == #saved then
        self:SetStatus(guild_index, #fetched .. " all new event(s)")
        return fetched
    end

                        -- Create a short list of the most recent saved events.
                        -- We'll scan fetched for these events to match up the
                        -- two lists.
    first_rows = self:FirstRows(saved, 5)
    s_events = {}
    for i,s_row in ipairs(first_rows) do
        s_event = Event:FromString(s_row)
        table.insert(s_events, s_event)
        --d("mh f_event["..#f_events.."]: " .. f_event:ToString())
    end

    f_i_found = self:Find(s_events, fetched)
    if not f_i_found then
        f_i_found = 1
        self:SetStatus(guild_index, #fetched .. " new event(s), might have dropped some")
    else
        self:SetStatus(guild_index, (f_i_found - 1) .. " new event(s)")
    end
    for f_i = 1,f_i_found - 1 do
        table.insert(saved, f_i, fetched[i])
    end
    return saved
end

-- Return the index into saved that matches f_events.
-- Return nil if not found.
function GuildGoldDeposits:Find(f_events, saved)
    if (0 == #f_events) or (0 == #saved) then return nil end
    for i = 1,#saved do
        if self:PatternMatch(i, f_events, saved) then
            return i - #f_events + 1
        end
    end
    return nil
end

-- If saved[s_i] and its precursors match f_events, return true.
-- If not, return false.
function GuildGoldDeposits:PatternMatch(s_i, f_events, saved)
    s_event = {}
    for i = 0, math.min(s_i, #f_events) - 1 do
        s_ii    = s_i - i
        f_ii    = #f_events - i
        s_row   = saved[s_ii]
        s_event = Event:FromString(saved[s_i - i])
        f_event = f_events[f_ii]
        match   = Event.Match(f_event, s_event)
        -- d("pm " ..tostring(match)
        --     .. " s_i:" .. s_i
        --     .." i:"..i
        --     .." f_ii:"..f_ii.." "..f_event:ToString()
        --     .." s_ii:"..s_ii.." "..s_row
        --     )
        if not match then return false end
    end
    return true
end

-- Return the first "ct" rows from "list".
-- Or fewer if list doesn't have that many rows.
function GuildGoldDeposits:FirstRows(list, ct)
    r = {}
    for i = 1, math.min(ct, #list) do
        table.insert(r, list[i])
    end
    return r
end

-- Postamble -----------------------------------------------------------------

EVENT_MANAGER:RegisterForEvent( GuildGoldDeposits.name
                              , EVENT_ADD_ON_LOADED
                              , GuildGoldDeposits.OnAddOnLoaded
                              )
