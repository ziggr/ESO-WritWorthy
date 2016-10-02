local LAM2 = LibStub("LibAddonMenu-2.0")

local NetWorth = {}
NetWorth.name            = "NetWorth"
NetWorth.version         = "2.5.1"
NetWorth.savedVarVersion = 2
NetWorth.default = {
      enable_guild  = { true, true, true, true, true }
    , history = {}
}
NetWorth.max_guild_ct = 5
NetWorth.fetching = { false, false, false, false, false }


                        -- fetched_str_list[guild_index] = { list of event strings }
                        -- loaded from the current "Save Now" run.
NetWorth.fetched_str_list = {}
NetWorth.guild_name = {} -- guild_name[guild_index] = "My Aweseome Guild"

                        -- retry_ct[guild_index] = how many retries after
                        -- distrusting "nah, no more history"
NetWorth.retry_ct   = { 0, 0, 0, 0, 0 }
NetWorth.max_retry_ct = 3

NetWorth.ET_DEPOSIT_GOLD  = "dep_gold"
NetWorth.ET_DEPOSIT_ITEM  = "dep_item"
NetWorth.ET_WITHDRAW_GOLD = "wd_gold"
NetWorth.ET_WITHDRAW_ITEM = "wd_item"

-- Event ---------------------------------------------------------------------
-- One row in our savedVariables history
--
-- Knows how to convert to/from string
-- Knows how to convert from GetGuildEventInfo().
-- Named fields instead of table indices.
--
local Event = {}

-- If this is a deposit or withdrawal that we understand, return an Event with
-- its data. If not, return nil.
function Event:FromInfo(event_type, since_secs, p1, p2, p3, p4, p5, p6)
    local o = { time       = GetTimeStamp() - since_secs
              , user       = nil
              , gold_ct    = nil
              , trans_type = nil
              , item_ct    = nil
              , item_name  = nil
              , item_link  = nil
              , item_mm    = nil
              }

    if event_type == GUILD_EVENT_BANKGOLD_ADDED then
        o.user       = p1
        o.gold_ct    = p2
        o.trans_type = NetWorth.ET_DEPOSIT_GOLD

    elseif event_type == GUILD_EVENT_BANKGOLD_REMOVED then
        o.user       = p1
        o.gold_ct    = p2
        o.trans_type = NetWorth.ET_WITHDRAW_GOLD

    elseif event_type == GUILD_EVENT_BANKITEM_ADDED then
        o.user       = p1
        o.trans_type = NetWorth.ET_DEPOSIT_ITEM
        o.item_ct    = p2
        o.item_link  = p3
        o.item_mm    = Event.MMPrice(o.item_link)
        o.item_name  = GetItemLinkName(o.item_link)

    elseif event_type == GUILD_EVENT_BANKITEM_REMOVED then
        o.user       = p1
        o.trans_type = NetWorth.ET_WITHDRAW_ITEM
        o.item_ct    = p2
        o.item_link  = p3
        o.item_mm    = Event.MMPrice(o.item_link)
        o.item_name  = GetItemLinkName(o.item_link)

    else
       return nil
    end

    setmetatable(o, self)
    self.__index = self
    return o
end

function Event:HeaderList()
    local o = { "time"          -- [1]
              , "user"          -- [2]
              , "type"          -- [3]
              , "gold_ct"       -- [4]
              , "item_ct"       -- [5]
              , "item_name"     -- [6]
              , "item_link"     -- [7]
              , "item_mm"       -- [8]
              }
    return o
end

function Event.tonum(str)
    if str == "nil" or str == "" then
        return nil
    else
        return tonumber(str)
    end
end

function Event.tostr(str)
    if str == "nil" or str == "" then
        return nil
    else
        return tostring(str)
    end
end

function Event:FromString(str)
    local s1, s2, s3, s4, s5, s6, s7, s8 = NetWorth:split(str)
    local t = tonumber(s1)
    if not (t and s2 and s3) then
        return nil
    end
    local o = { time       = t
              , user       = s2
              , trans_type = s3
              , gold_ct    = Event.tonum(s4)
              , item_ct    = Event.tonum(s5)
              , item_name  = Event.tostr(s6)
              , item_link  = Event.tostr(s7)
              , item_mm    = Event.tonum(s8)
              }

    setmetatable(o, self)
    self.__index = self
    return o
end

function Event:ToString()
                        -- tab-delimited fields
                        -- See HeaderList for order.
                        --
                        -- Values are unquoted, can contain all sorts of
                        -- noise but unlikely to contian a
                        -- tab character.
                        --
                        -- using tostring() here so that this function can work
                        -- when debugging nil event elements.
    return             tostring(self.time       )
            .. '\t' .. tostring(self.user       )
            .. '\t' .. tostring(self.trans_type )
            .. '\t' .. tostring(self.gold_ct    )
            .. '\t' .. tostring(self.item_ct    )
            .. '\t' .. tostring(self.item_name  )
            .. '\t' .. tostring(self.item_link  )
            .. '\t' .. tostring(self.item_mm    )
end

function Event:ToDisplayText()
    if self.trans_type == NetWorth.ET_DEPOSIT_GOLD
    or self.trans_type == NetWorth.ET_WITHDRAW_GOLD then
        return tostring(self.time)
                .. " " .. self.user
                .. " " .. self.trans_type
                .. " " .. self.gold_ct
                .. "g"

    elseif self.trans_type == NetWorth.ET_DEPOSIT_ITEM
    or     self.trans_type == NetWorth.ET_WITHDRAW_ITEM then
        return tostring(self.time)
                .. " "  .. self.user
                .. " "  .. self.trans_type
                .. " "  .. self.item_ct
                .. "x " .. self.item_link

    else
        return "Event:time=" .. tostring(self.time)
                .. " user=" .. tostring(self.user)
                .. " type=" .. tostring(self.trans_type)
    end
end

function Event.MMPrice(link)
    if not MasterMerchant then return nil end
    if not link then return nil end
    mm = MasterMerchant:itemStats(link, false)
    if not mm then return nil end
    --d("MM for link: "..tostring(link).." "..tostring(mm.avgPrice))
    return mm.avgPrice
end

-- Init ----------------------------------------------------------------------

function NetWorth.OnAddOnLoaded(event, addonName)
    if addonName ~= NetWorth.name then return end
    if not NetWorth.version then return end
    if not NetWorth.default then return end
    NetWorth:Initialize()
end

function NetWorth:Initialize()
    self.savedVariables = ZO_SavedVars:NewAccountWide(
                              "NetWorthVars"
                            , self.savedVarVersion
                            , nil
                            , self.default
                            )
    self:CreateSettingsWindow()
    --EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)
end

-- UI ------------------------------------------------------------------------

function NetWorth.ref_cb(guild_index)
    return "NetWorth_cbg" .. guild_index
end

function NetWorth.ref_desc(guild_index)
    return "NetWorth_desc" .. guild_index
end

function NetWorth:CreateSettingsWindow()
    local panelData = {
        type                = "panel",
        name                = "Guild Bank Ledger",
        displayName         = "Guild Bank Ledger",
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
        , tooltip   = "Save guild bank transaction data to file now."
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

    LAM2:RegisterOptionControls("NetWorth", optionsData)
    CALLBACK_MANAGER:RegisterCallback("LAM-PanelControlsCreated"
            , self.OnPanelControlsCreated)
end

-- Delay initialization of options panel: don't waste time fetching
-- guild names until a human actually opens our panel.
function NetWorth.OnPanelControlsCreated(panel)
    self = NetWorth
    local guild_ct = GetNumGuilds()
    for guild_index = 1,self.max_guild_ct do
        exists = guild_index <= guild_ct
        self:InitGuildSettings(guild_index, exists)
        self:InitGuildControls(guild_index, exists)
    end
end

-- Data portion of init UI
function NetWorth:InitGuildSettings(guild_index, exists)
    if exists then
        local guildId   = GetGuildId(guild_index)
        local guildName = GetGuildName(guildId)
        self.guild_name[guild_index] = guildName
    else
        self.savedVariables.enable_guild[guild_index] = false
    end
end

-- UI portion of init UI
function NetWorth:InitGuildControls(guild_index, exists)
    local cb = _G[self.ref_cb(guild_index)]
    if exists and cb and cb.label then
        cb.label:SetText(self.guild_name[guild_index])
    end
    if cb then
        cb:SetHidden(not exists)
    end

    local desc = _G[self.ref_desc(guild_index)]
    self.ConvertCheckboxToText(desc)
    self:SetStatusNewestSaved(guild_index)
end

-- Coerce a checkbox to act like a text label.
--
-- I cannot get LibAddonMenu-2.0 "description" items to dynamically update
-- their text. SetText() has no effect. But SetText() works on "checkbox"
-- items, so beat those into a text-like UI element.
function NetWorth.ConvertCheckboxToText(desc)
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
function NetWorth:SetStatus(guild_index, msg)
    --d("status " .. tostring(guild_index) .. ":" .. tostring(msg))
    local x = _G[self.ref_desc(guild_index)]
    if not x then return end
    desc = x.label
    desc:SetText("  " .. msg)
end

-- Set status to "Newest: @user 100,000g  11 hours ago"
function NetWorth:SetStatusNewestSaved(guild_index)
    local event = self:SavedHistoryNewest(guild_index)
    self:SetStatusNewest(guild_index, event)
end

function NetWorth:SetStatusNewestFetched(guild_index)
    local event = self:FetchedNewest(guild_index)
    self:SetStatusNewest(guild_index, event)
end

function NetWorth:SetStatusNewest(guild_index, event)
    if not event then return end

    local now_ts   = GetTimeStamp()
    local ago_secs = GetDiffBetweenTimeStamps(now_ts, event.time)
    local ago_str  = FormatTimeSeconds(ago_secs
                    , TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE -- "22 hours"
                    , TIME_FORMAT_PRECISION_SECONDS
                    , TIME_FORMAT_DIRECTION_DESCENDING
                    )

    self:SetStatus(guild_index, "Newest: " .. event.user
                     .. " " .. ago_str .. " ago")
end

-- Parse/Format SavedVariables history ----------------------------------------

-- Lua lacks a split() function. Here's a cheesy hardwired one that works
-- for our specific need.
function NetWorth:split(str)
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

-- Return the one newest event, if any, from our previous save.
-- Return nil if not.
function NetWorth:SavedHistoryNewest(guild_index)
    local guildName = GetGuildName(guildId)
    if not self.savedVariables then return nil end
    if not self.savedVariables.history then return nil end
    return self:Newest(self.savedVariables.history[guildName])
end

-- Return the Event of the most recent event string from
-- a list of event strings.
function NetWorth:Newest(str_list)
    if not str_list then return nil end
    if not (1 <= #str_list) then return nil end
    local newest_event = Event:FromString(str_list[1])
    for _,line in ipairs(str_list) do
        local e = Event:FromString(line)
        if e then
            if (not newest_event) or newest_event.time < e.time then
                newest_event = e
            end
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

function NetWorth:SaveNow()
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
function NetWorth:SkipGuildIndex(guild_index)
    self:SetStatus(guild_index, "skipped")
end

-- Download one guild's history
function NetWorth:SaveGuildIndex(guild_index)
    local guildId = GetGuildId(guild_index)
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
function NetWorth:ServerDataPoll(guild_index)
    local guildId = GetGuildId(guild_index)
    local more = DoesGuildHistoryCategoryHaveMoreEvents(guildId, GUILD_HISTORY_BANK)
    local event_ct = GetNumGuildEvents(guildId, GUILD_HISTORY_BANK)
    self:SetStatus(guild_index, "fetching events: " .. event_ct .. " ...")
    local can_retry =    (not self.retry_ct[guild_index])
                or (self.retry_ct[guild_index] < self.max_retry_ct)
    if more or can_retry then
        RequestGuildHistoryCategoryOlder(guildId, GUILD_HISTORY_BANK)
        local delay_ms = 0.5 * 1000
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
function NetWorth:ServerDataComplete(guild_index)
                        -- Avoid infinite noise if a Lua error in here
                        -- causes a repeated callback. Mostly useful when
                        -- debugging, shouldn't be an issue when we're
                        -- not buggy.
    if not self.fetching[guild_index] then return end

                        -- Latch false (until next time user clicks "Save Now")
                        -- so that we know not to re-complete this guild.
                        -- And so we know when all guilds are complete.
    self.fetching[guild_index] = false

    local guildId    = GetGuildId(guild_index)
    local guild_name = self.guild_name[guild_index]
    local event_ct   = GetNumGuildEvents(guildId, GUILD_HISTORY_BANK)
    self:SetStatus(guild_index, "scanning events: " .. event_ct .. " ...")
    for i = 1, event_ct do
        local event_type, secs_ago, p1, p2, p3, p4, p5, p6
            = GetGuildEventInfo(guildId, GUILD_HISTORY_BANK, i)
        local event = Event:FromInfo( event_type, secs_ago
                                    , p1, p2, p3, p4, p5, p6)
        if event then
            -- d("record  : " .. event:ToDisplayText())
            self:RecordEvent(guild_index, event)
        end
    end
    local found_ct = 0
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
        local ct = self:FetchedEventCt()
        d(self.name .. ": saved " ..tostring(ct).. " guild bank record(s)." )
        d(self.name .. ": Log out or Quit to write file.")
    end
end

function NetWorth:FetchedEventCt()
    local total_ct = 0
    for _,fetched_str_list in pairs(self.fetched_str_list) do
        if fetched_str_list then
            total_ct = total_ct + #fetched_str_list
        end
    end
    return total_ct
end

function NetWorth:StillFetchingAny()
    for _,v in pairs(self.fetching) do
        if v then return true end
    end
    return false
end

function NetWorth:RecordEvent(guild_index, event)
    if not self.fetched_str_list[guild_index] then
        self.fetched_str_list[guild_index] = {}
    end
    local t = self.fetched_str_list[guild_index]
    table.insert(t, event:ToString())
end

function NetWorth:FetchedNewest(guild_index)
    return self:Newest(self.fetched_str_list[guild_index])
end

-- Postamble -----------------------------------------------------------------

EVENT_MANAGER:RegisterForEvent( NetWorth.name
                              , EVENT_ADD_ON_LOADED
                              , NetWorth.OnAddOnLoaded
                              )
