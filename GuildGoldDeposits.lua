local LAM2 = LibStub("LibAddonMenu-2.0")

local GuildGoldDeposits = {}
GuildGoldDeposits.name = "GuildGoldDeposits"
GuildGoldDeposits.version = 224.1
GuildGoldDeposits.default = {
      enable_guild  = { true, true, true, true, true }
}
GuildGoldDeposits.max_guild_ct = 5
GuildGoldDeposits.event_list = {} -- event_list[guild_index] = { list of event strings }
GuildGoldDeposits.guild_name = {} -- guild_name[guild_index] = "My Aweseome Guild"

                                  -- retry_ct[guild_index] = how many retries after
                                  -- distrusting "nah, no more history"
GuildGoldDeposits.retry_ct   = { 0, 0, 0, 0, 0 }
GuildGoldDeposits.max_retry_ct = 3
GuildGoldDeposits.max_day_ct = 30 -- how many days to store in SavedVariables

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
                            , self.version
                            , nil
                            , self.default
                            )
    self:CreateSettingsWindow()
    EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)
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

-- Delayed initialization of options panel: don't waste time fetching
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

-- Displaying Status ---------------------------------------------------------

-- Update the per-guild text label with what's going on with that guild data.
function GuildGoldDeposits:SetStatus(guild_index, msg)
    desc = _G[self.ref_desc(guild_index)].label
    desc:SetText("  " .. msg)
end

-- Set status to "Newest: @user 100,000g"
function GuildGoldDeposits:SetStatusNewest(guild_index)
    line = self:HistoryNewest(guild_index)
    if not line then return end
    event_ts, amt, user = self:split(line)
    now_ts = GetTimeStamp()
    ago_secs = GetDiffBetweenTimeStamps(now_ts, event_ts)
    ago_str  = FormatTimeSeconds(ago_secs
                    , TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE        -- "22 hours"
                    , TIME_FORMAT_PRECISION_SECONDS
                    , TIME_FORMAT_DIRECTION_DESCENDING
                    )

    self:SetStatus(guild_index, "Newest deposit: " .. user
                     .. " " .. amt .. "g  " .. ago_str .. " ago")
end

-- Parsing/Formatting SavedVariables history ---------------------------------

-- Lua lacks a split() function. Here's a cheesy hardwired one that works
-- for our specific need.
function GuildGoldDeposits:split(str)
    t1 = string.find(str, '\t')
    t2 = string.find(str, '\t', 1 + t1)
    return   string.sub(str, 1,      t1 - 1)
           , string.sub(str, 1 + t1, t2 - 1)
           , string.sub(str, 1 + t2)
end

-- Return the one newest history line, if any. Return nil if not.
function GuildGoldDeposits:HistoryNewest(guild_index)
    guildName = GetGuildName(guildId)
    if not self.savedVariables then return nil end
    if not self.savedVariables.history then return nil end
    history = self.savedVariables.history[guildName]
    if not history then return nil end
    if not (1 <= #history) then return nil end
    return history[1]
end

-- Saving Guild Data ---------------------------------------------------------

function GuildGoldDeposits:SaveNow()
    self.savedVariables.history = {}
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
    guildId = GetGuildId(guild_index)
    guild_name = self.guild_name[guild_index]
    event_ct = GetNumGuildEvents(guildId, GUILD_HISTORY_BANK)
    --self:SetStatus(guild_index, "scanning events: " .. event_ct .. " ...")
    for i = 1, event_ct do
        t, s, u, a = GetGuildEventInfo(guildId, GUILD_HISTORY_BANK, i)
        if t == GUILD_EVENT_BANKGOLD_ADDED then
            event = { type = t
                    , time = GetTimeStamp() - s
                    , user = u
                    , amount = a
                    }
            self:RecordEvent(guild_index, event)
        end
    end
    found_ct = 0
    if self.event_list[guild_index] then
        found_ct = #self.event_list[guild_index]
    end
    self:SetStatus(guild_index, "scanned events: " .. event_ct
                   .. "  gold deposits: " .. found_ct)
    self.savedVariables.history[guild_name] = self.event_list[guild_index]
end

function GuildGoldDeposits:RecordEvent(guild_index, event)
    if not self.event_list[guild_index] then
        self.event_list[guild_index] = {}
    end
    t = self.event_list[guild_index]
    table.insert(t, self:EventToString(event))
end

-- Convert an event to a compact string that a line-parser can easily consume.
function GuildGoldDeposits:EventToString(event)
                        -- tab-delimited fields
                        -- date     seconds since the epoch
                        -- amount
                        -- user     unquoted, can contain all sorts of
                        --          noise but unlikely to contian a
                        --          tab character.
    return string.format("%d\t%d\t%s", event.time, event.amount, event.user)
end

-- Postamble -----------------------------------------------------------------

EVENT_MANAGER:RegisterForEvent( GuildGoldDeposits.name
                              , EVENT_ADD_ON_LOADED
                              , GuildGoldDeposits.OnAddOnLoaded
                              )
