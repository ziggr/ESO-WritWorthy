local LAM2 = LibStub("LibAddonMenu-2.0")

GuildGoldDeposits = {}

GuildGoldDeposits.name = "GuildGoldDeposits"
GuildGoldDeposits.version = 1

GuildGoldDeposits.Default = {
    enable_guild  = { false, false, false, false, false },
    duration_days = 7
}

function GuildGoldDeposits.OnAddOnLoaded(event, addonName)
    if addonName ~= GuildGoldDeposits.name then return end
    GuildGoldDeposits:Initialize()
end

function GuildGoldDeposits:Initialize()
    GuildGoldDeposits.savedVariables = ZO_SavedVars:New(
                                                  "GuildGoldDepositsVars"
                                                , GuildGoldDeposits.version
                                                , nil
                                                , GuildGoldDeposits.Default
                                                )
    GuildGoldDeposits.CreateSettingsWindow()
    EVENT_MANAGER:UnregisterForEvent(GuildGoldDeposits.name, EVENT_ADD_ON_LOADED)
end

function GuildGoldDeposits.CreateSettingsWindow()
    local panelData = {
        type                = "panel",
        name                = "Guild Gold Deposits",
        displayName         = "Guild Gold Deposits",
        author              = "ziggr",
        version             = GuildGoldDeposits.version,
        --slashCommand      = "/stambar",
        registerForRefresh  = true,
        registerForDefaults = true,
    }
    local cntrlOptionsPanel = LAM2:RegisterAddonPanel( "GuildGoldDeposits"
                                                     , panelData
                                                     )
    local optionsData = {
        { type      = "header"
        , name      = "Duration"
        },
        { type      = "slider"
        , name      = "Days to save"
        , tooltip   = "How many days' data to save?"
        , min       = 1
        , max       = 21
        , step      = 1
        , getFunc   = function() return 1 end
        , setFunc   = function(value) end
        , reference = "GuildGoldDeposits_dur"
        },
        { type      = "header"
        , name      = "Guilds"
        },
    }

    for i = 1, 5 do
        table.insert(optionsData,
            { type      = "checkbox"
            , name      = "(guild " .. i .. ")"
            , tooltip   = "Save data for guild " .. i .. "?"
            , getFunc   = function() return true end
            , setFunc   = function(e) end
            , reference = "GuildGoldDeposits_cbg" .. i
            })
    end



    LAM2:RegisterOptionControls("GuildGoldDeposits", optionsData)
end



EVENT_MANAGER:RegisterForEvent( GuildGoldDeposits.name
                              , EVENT_ADD_ON_LOADED
                              , GuildGoldDeposits.OnAddOnLoaded
                              )
