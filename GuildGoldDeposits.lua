local LAM2 = LibStub("LibAddonMenu-2.0")

local GuildGoldDeposits = {}
GuildGoldDeposits.name = "GuildGoldDeposits"
GuildGoldDeposits.version = 1
GuildGoldDeposits.default = {
      enable_guild  = { true, true, true, true, true }
    , duration_days = 7
}

function GuildGoldDeposits.OnAddOnLoaded(event, addonName)
    if addonName ~= GuildGoldDeposits.name then return end
    if not GuildGoldDeposits.version then return end
    if not GuildGoldDeposits.default then return end
    GuildGoldDeposits:Initialize()
end

function GuildGoldDeposits:SaveNow()
    d("GGD:Saving!")
    d("sv.days " .. self.savedVariables.duration_days)
    for i = 1, 5 do
        d("sv.eg[" .. i .. "] = "
          .. tostring(self.savedVariables.enable_guild[i]))
    end
end

function GuildGoldDeposits:Initialize()
    self.savedVariables = ZO_SavedVars:New(
                              "GuildGoldDepositsVars"
                            , self.version
                            , nil
                            , self.default
                            )
    -- self.savedVariables.duration_days = 8
    self:CreateSettingsWindow()
    EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)
end

function SaveNow()
    d("Saving!")
    GuildGoldDeposits:SaveNow()
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
        registerForDefaults = true,
    }
    local cntrlOptionsPanel = LAM2:RegisterAddonPanel( self.name
                                                     , panelData
                                                     )
    local optionsData = {
        { type      = "button"
        , name      = "Save Data Now"
        , tooltip   = "Save guild gold deposit data to file now."
        , func      = function() d("hi") SaveNow() end
        , width     = "full" --or "half" (optional
        , reference = "GuildGoldDesposits_save" --(optional) unique global reference to contro
        },
        { type      = "header"
        , name      = "Duration"
        },
        { type      = "slider"
        , name      = "Days to save"
        , tooltip   = "How many days' data to save?"
        , min       = 1
        , max       = 21
        , step      = 1
        , getFunc   = function() return self.savedVariables.duration_days end
        , setFunc   = function(value) self.savedVariables.duration_days = value end
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
            --, getFunc   = function() return true end
            , getFunc   = function() return self.savedVariables.enable_guild[i] end
            , setFunc   = function(e) self.savedVariables.enable_guild[i] = e end
            , reference = "GuildGoldDeposits_cbg" .. i
            })
    end

    LAM2:RegisterOptionControls("GuildGoldDeposits", optionsData)
end


EVENT_MANAGER:RegisterForEvent( GuildGoldDeposits.name
                              , EVENT_ADD_ON_LOADED
                              , GuildGoldDeposits.OnAddOnLoaded
                              )
