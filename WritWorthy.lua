-- WritWorthy: Is this Maaster Writ worth doing?
--
-- In a master writ's tooltip, include the material cost for that writ
-- as both a gold total, and a gold per writ voucher reward.

local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Util.lua
local LAM2 = LibStub("LibAddonMenu-2.0")

WritWorthy.name            = "WritWorthy"
WritWorthy.version         = "2.7.3"
WritWorthy.savedVarVersion = 1
WritWorthy.default = {
    enable_mat_list_chat = false
}

local Util = WritWorthy.Util
local Fail = WritWorthy.Util.Fail

WritWorthy.ICON_TO_PARSER = {
    ["/esoui/art/icons/master_writ_blacksmithing.dds"] = WritWorthy.Smithing.Parser
,   ["/esoui/art/icons/master_writ_clothier.dds"     ] = WritWorthy.Smithing.Parser
,   ["/esoui/art/icons/master_writ_woodworking.dds"  ] = WritWorthy.Smithing.Parser
,   ["/esoui/art/icons/master_writ_alchemy.dds"      ] = WritWorthy.Alchemy.Parser
,   ["/esoui/art/icons/master_writ_enchanting.dds"   ] = WritWorthy.Enchanting.Parser
,   ["/esoui/art/icons/master_writ_provisioning.dds" ] = WritWorthy.Provisioning.Parser
}

-- Factory to return a parser who knows how to read this particular
-- master writ type.
--
-- Returns one
--  Smithing.Parser (BS/CL/WW)
--  Enchanting.Parser
--  Provisioning.Parser
--  Alchemy.Parser
--
function WritWorthy.CreateParser(item_link)
    local icon, _, _, _, item_style = GetItemLinkInfo(item_link)
    local parser_class = WritWorthy.ICON_TO_PARSER[icon]
    if not parser_class then return nil end
    return parser_class:New()
end

-- Convert a Master Writ item_link into the list of materials that
-- writ consumes.
function WritWorthy.ToMatList(item_link)
    local parser = WritWorthy.CreateParser(item_link)
    if not parser then return nil end
    if not parser:ParseItemLink(item_link) then
        return Fail("WritWorthy: could not parse.")
    end
    local mat_list = parser:ToMatList()
    return mat_list
end

-- Convert a Master Writ item_link into the integer number of
-- writ vouchers it returns.
function WritWorthy.ToVoucherCount(item_link)
    local reward_text = GenerateMasterWritRewardText(item_link)
    local fields      = Util.ToWritFields(item_link)
    local vc          = Util.round(fields.writ_reward / 10000)
    return vc
end

-- Convert a writ link to a string with both the link and base text
-- that we can store and anyalyze later.
function WritWorthy.ToLinkBaseText(item_link)
    if not item_link then return nil end
                        -- strip "Consume to start quest:\n" preamble
    local base_text = GenerateMasterWritBaseText(item_link)
    local writ_text = GenerateMasterWritRewardText(item_link)
    -- d("b:"..tostring(base_text))
    local req_text  = base_text:gsub(".*\n","")
    -- d("r:"..tostring(req_text))
    return item_link .. "\t" .. req_text .."\t".. writ_text
end

-- Return the text we should add to a tooltip.
function WritWorthy.TooltipText(mat_list, purchase_gold, voucher_ct)
    if (not voucher_ct) or (voucher_ct < 1) or (not mat_list) then return nil end

    local mat_gold       = WritWorthy.MatRow.ListTotal(mat_list)
    local mat_text       = "Mat total: " .. Util.ToMoney(mat_gold) .. "g"
    local total_gold     = nil
    local purchase_text  = nil
    if purchase_gold then
        total_gold = mat_gold + purchase_gold
        purchase_text = "Purchase: " .. Util.ToMoney(purchase_gold) .. "g"
    else
        total_gold = mat_gold
    end
    local per_voucher_gold = total_gold / voucher_ct
    local per_voucher_text = "Per voucher: "
                .. Util.ToMoney(per_voucher_gold) .. "g"
    if not purchase_gold then
        return mat_text .. "  " .. per_voucher_text
    end
    return mat_text .. "  " .. purchase_text .. "\n" .. per_voucher_text
end

-- Add text to a tooltip.
--
-- control:       the tooltip, responds to :AddLine(text)
-- link:          the item whose tip ZOScode is showing.
-- purchase_gold: if set, this is a tooltip for a guild store listing.
--                Include this cost in the gold-per-voucher calculation.
--                (optional, nil ok)
--
function WritWorthy.TooltipInsertOurText(control, item_link, purchase_gold)
    -- Only fire for master writs.
    if ITEMTYPE_MASTER_WRIT ~= GetItemLinkItemType(item_link) then return end

    local mat_list   = WritWorthy.ToMatList(item_link)
    local voucher_ct = WritWorthy.ToVoucherCount(item_link)
    local text = WritWorthy.TooltipText(mat_list, purchase_gold, voucher_ct)
    if not text then return end
    control:AddLine(text)
    if WritWorthy.savedVariables.enable_mat_list_chat then
        WritWorthy.MatRow.ListDump(mat_list)
    end
end

-- Tooltip Intercept ---------------------------------------------------------

-- Monkey-patch ZOS' ItemTooltip with our own after-overrides. Lets ZOS code
-- create and show the original tooltip, and then we come in and insert our
-- own stuff.
--
-- Based on CraftStore's CS.TooltipHandler().
--
function WritWorthy.TooltipInterceptInstall()
    local tt=ItemTooltip.SetBagItem
    ItemTooltip.SetBagItem=function(control,bagId,slotIndex,...)
        tt(control,bagId,slotIndex,...)
        WritWorthy.TooltipInsertOurText(control,GetItemLink(bagId,slotIndex))
    end
    local tt=ItemTooltip.SetLootItem
    ItemTooltip.SetLootItem=function(control,lootId,...)
        tt(control,lootId,...)
        WritWorthy.TooltipInsertOurText(control,GetLootItemLink(lootId))
    end
    local tt=PopupTooltip.SetLink
    PopupTooltip.SetLink=function(control,link,...)
        tt(control,link,...)
        WritWorthy.TooltipInsertOurText(control,link)
    end
    local tt=ItemTooltip.SetTradingHouseItem
    ItemTooltip.SetTradingHouseItem=function(control,tradingHouseIndex,...)
        tt(control,tradingHouseIndex,...)
        local _,_,_,_,_,_,purchase_gold = GetTradingHouseSearchResultItemInfo(tradingHouseIndex)
        WritWorthy.TooltipInsertOurText(control
                , GetTradingHouseSearchResultItemLink(tradingHouseIndex)
                , purchase_gold
                )
    end
end

-- UI ------------------------------------------------------------------------

function WritWorthy:CreateSettingsWindow()
    local panelData = {
        type                = "panel",
        name                = "WritWorthy",
        displayName         = "WritWorthy",
        author              = "ziggr",
        version             = self.version,
        --slashCommand        = "/gg",
        registerForRefresh  = false,
        registerForDefaults = false,
    }
    local cntrlOptionsPanel = LAM2:RegisterAddonPanel( self.name
                                                     , panelData
                                                     )
    local optionsData = {
        { type      = "checkbox"
        , name      = "Show material list in chat"
        , tooltip   = "Write several lines of materials to chat each"
                      .." time a Master Writ tooltip appears."
        , getFunc   = function()
                        return self.savedVariables.enable_mat_list_chat
                      end
        , setFunc   = function(e)
                        self.savedVariables.enable_mat_list_chat = e
                      end
        },
    }

    LAM2:RegisterOptionControls("WritWorthy", optionsData)
end

-- Init ----------------------------------------------------------------------

function WritWorthy.OnAddOnLoaded(event, addonName)
    if addonName ~= WritWorthy.name then return end
    if not WritWorthy.version then return end
    WritWorthy:Initialize()
end

function WritWorthy:Initialize()
    self.savedVariables = ZO_SavedVars:NewAccountWide(
                              "WritWorthyVars"
                            , self.savedVarVersion
                            , nil
                            , self.default
                            )
    WritWorthy.TooltipInterceptInstall()
    self:CreateSettingsWindow()
    --EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)
end

-- Postamble -----------------------------------------------------------------

EVENT_MANAGER:RegisterForEvent( WritWorthy.name
                              , EVENT_ADD_ON_LOADED
                              , WritWorthy.OnAddOnLoaded
                              )

