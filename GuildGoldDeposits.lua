local LAM2 = LibStub("LibAddonMenu-2.0")

local GuildGoldDeposits = {}
GuildGoldDeposits.name            = "GuildGoldDeposits"
GuildGoldDeposits.version         = "2.3.7.2"
GuildGoldDeposits.savedVarVersion = 2
GuildGoldDeposits.default = {
      enable_guild  = { true, true, true, true, true }
    , history = {}
}
GuildGoldDeposits.max_guild_ct = 5
GuildGoldDeposits.fetching = { false, false, false, false, false }


                        -- fetched_str_list[guild_index] = { list of event strings }
                        -- loaded from the current "Save Now" run.
GuildGoldDeposits.fetched_str_list = {}
GuildGoldDeposits.guild_name = {} -- guild_name[guild_index] = "My Aweseome Guild"

                        -- retry_ct[guild_index] = how many retries after
                        -- distrusting "nah, no more history"
GuildGoldDeposits.retry_ct   = { 0, 0, 0, 0, 0 }
GuildGoldDeposits.max_retry_ct = 3


                        -- how many days to store in SavedVariables
                        -- (not yet implemented)
GuildGoldDeposits.max_day_ct = 30

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
        --slashCommand        = "/gg",
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
        exists = guild_index <= guild_ct
        self:InitGuildSettings(guild_index, exists)
        self:InitGuildControls(guild_index, exists)
    end
end

-- Data portion of init UI
function GuildGoldDeposits:InitGuildSettings(guild_index, exists)
    if exists then
        guildId   = GetGuildId(guild_index)
        guildName = GetGuildName(guildId)
        self.guild_name[guild_index] = guildName
    else
        self.savedVariables.enable_guild[guild_index] = false
    end
end

-- UI portion of init UI
function GuildGoldDeposits:InitGuildControls(guild_index, exists)
    cb = _G[self.ref_cb(guild_index)]
    if exists and cb and cb.label then
        cb.label:SetText(self.guild_name[guild_index])
    end
    if cb then
        cb:SetHidden(not exists)
    end

    desc = _G[self.ref_desc(guild_index)]
    self.ConvertCheckboxToText(desc)
    self:SetStatusNewestSaved(guild_index)
end

-- Coerce a checkbox to act like a text label.
--
-- I cannot get LibAddonMenu-2.0 "description" items to dynamically update
-- their text. SetText() has no effect. But SetText() works on "checkbox"
-- items, so beat those into a text-like UI element.
function GuildGoldDeposits.ConvertCheckboxToText(desc)
    if not desc then return end
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
    --d("status " .. tostring(guild_index) .. ":" .. tostring(msg))
    x = _G[self.ref_desc(guild_index)]
    if not x then return end
    desc = x.label
    desc:SetText("  " .. msg)
end

-- Set status to "Newest: @user 100,000g  11 hours ago"
function GuildGoldDeposits:SetStatusNewestSaved(guild_index)
    event = self:SavedHistoryNewest(guild_index)
    self:SetStatusNewest(guild_index, event)
end

function GuildGoldDeposits:SetStatusNewestFetched(guild_index)
    event = self:FetchedNewest(guild_index)
    self:SetStatusNewest(guild_index, event)
end

function GuildGoldDeposits:SetStatusNewest(guild_index, event)
    if not event then return end

    now_ts = GetTimeStamp()
    ago_secs = GetDiffBetweenTimeStamps(now_ts, event.time)
    ago_str  = FormatTimeSeconds(ago_secs
                    , TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE -- "22 hours"
                    , TIME_FORMAT_PRECISION_SECONDS
                    , TIME_FORMAT_DIRECTION_DESCENDING
                    )

    self:SetStatus(guild_index, "Newest: " .. event.user
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

-- Return the one newest event, if any, from our previous save.
-- Return nil if not.
function GuildGoldDeposits:SavedHistoryNewest(guild_index)
    guildName = GetGuildName(guildId)
    if not self.savedVariables then return nil end
    if not self.savedVariables.history then return nil end
    return self:Newest(self.savedVariables.history[guildName])
end

-- Return the Event of the most recent event string from
-- a list of event strings.
function GuildGoldDeposits:Newest(str_list)
    if not str_list then return nil end
    if not (1 <= #str_list) then return nil end
    newest_event = self:StringToEvent(str_list[1])
    for _,line in ipairs(str_list) do
        e = self:StringToEvent(line)
        if newest_event.time < e.time then
            newest_event = e
        end
    end
    return newest_event
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
    self.fetched_str_list = {}
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
    self.fetching[guild_index] = true
    self:SetStatus(guild_index, "downloading history...")
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
                        -- Avoid infinite noise if a Lua error in here
                        -- causes a repeated callback. Mostly useful when
                        -- debugging, shouldn't be an issue when we're
                        -- not buggy.
    if not self.fetching[guild_index] then return end

                        -- Latch false (until next time user clicks "Save Now")
                        -- so that we know not to re-complete this guild.
                        -- And so we know when all guilds are complete.
    self.fetching[guild_index] = false

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
    if self.fetched_str_list[guild_index] then
        found_ct = #self.fetched_str_list[guild_index]
    end
    self.savedVariables.history[guild_name] = self.fetched_str_list[guild_index]
    self:SetStatusNewestFetched(guild_index)

                        -- I got sick of forgetting to relog, and I _wrote_
                        -- this thing. I can only imagine how many poor
                        -- unsuspecting users will get caught by "Oh, forgot to
                        -- relog!" if I don't add a reminder.
    if not self:StillFetchingAny() then
        ct = self:FetchedEventCt()
        d(self.name .. ": saved " ..tostring(ct).. " deposit record(s)." )
        d(self.name .. ": Log out or Quit to write file.")
    end
end

function GuildGoldDeposits:FetchedEventCt()
    total_ct = 0
    for _,fetched_str_list in pairs(self.fetched_str_list) do
        if fetched_str_list then
            total_ct = total_ct + #fetched_str_list
        end
    end
    return total_ct
end

function GuildGoldDeposits:StillFetchingAny()
    for _,v in pairs(self.fetching) do
        if v then return true end
    end
    return false
end

function GuildGoldDeposits:RecordEvent(guild_index, event)
    if not self.fetched_str_list[guild_index] then
        self.fetched_str_list[guild_index] = {}
    end
    t = self.fetched_str_list[guild_index]
    table.insert(t, event:ToString())
end

function GuildGoldDeposits:FetchedNewest(guild_index)
    return self:Newest(self.fetched_str_list[guild_index])
end

-- Postamble -----------------------------------------------------------------

EVENT_MANAGER:RegisterForEvent( GuildGoldDeposits.name
                              , EVENT_ADD_ON_LOADED
                              , GuildGoldDeposits.OnAddOnLoaded
                              )
