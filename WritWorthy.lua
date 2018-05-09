-- WritWorthy: Is this Maaster Writ worth doing?
--
-- In a master writ's tooltip, include the material cost for that writ
-- as both a gold total, and a gold per writ voucher reward.

local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Define.lua
local LAM2 = LibStub("LibAddonMenu-2.0")

WritWorthy.name            = "WritWorthy"
WritWorthy.version         = "4.0.6"
WritWorthy.savedVarVersion = 1

-- Constants for savedVariables.enable_mat_list_chat
-- Appear as user-visible text in dropdown and also used as programmatic keys
-- which is usually a bad idea but I'm suboptimally lazy today.
WritWorthy.MAT_LIST_CHAT_OFF          = "Off"
WritWorthy.MAT_LIST_CHAT_ALL          = "All"
WritWorthy.MAT_LIST_CHAT_ALCHEMY_ONLY = "Alchemy Only"
WritWorthy.default = {
    enable_mat_list_chat = WritWorthy.MAT_LIST_CHAT_OFF

                        -- UI topleft, used by WritWorthyInventoryList.
,   position = { 50, 50 }
}
                        -- Default savedChariables: per-character saved data.
                        -- Initially just data about that character's inventory.
WritWorthy.defaultChar = {

                        -- key = Id64ToString() of a writ that the user has
                        -- asked to enquque for later crafting.
                        -- val = "queued" or "completed"
                        -- Yes we keep the "completed" rows around to
                        -- provide some UI feedback.
    writ_unique_id = {}

}

local Util = WritWorthy.Util
local Fail = WritWorthy.Util.Fail
local Log  = WritWorthy.Log

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
    Log:StartNewEvent()
    Log:Add(GenerateMasterWritBaseText(item_link))
    Log:Add(item_link)
    return parser_class:New()
end

-- Convert a Master Writ item_link into the list of materials that
-- writ consumes, and the list of required trait or recipe knowledge
-- necessary to craft the item.
function WritWorthy.ToMatKnowList(item_link)
    local parser = WritWorthy.CreateParser(item_link)
    if not parser then return nil end
    Log:Add(parser.class)
    if not parser:ParseItemLink(item_link) then
        return Fail("WritWorthy: could not parse.")
    end
    local mat_list = parser:ToMatList()
    local know_list = nil
    if parser.ToKnowList then
        know_list = parser:ToKnowList()
    end
    return mat_list, know_list, parser
end

-- Convert a Master Writ item_link into an integer gold cost
-- for required materials.
----
function WritWorthy.ToMatCost(item_link)
                        -- Temporarily suspend all "dump matlist to chat"
                        -- to avoid scroll blindness
    local save_mat_list_chat = WritWorthy.savedVariables.enable_mat_list_chat

    local mat_list = WritWorthy.ToMatKnowList(item_link)
    local mat_total = WritWorthy.MatRow.ListTotal(mat_list)
                        -- Restore mat list to chat setting now that we're
                        -- done with chat-flooding scan.
    WritWorthy.savedVariables.enable_mat_list_chat = save_mat_list_chat

    return Util.round(mat_total)
end
-- Convert a Master Writ item_link into the integer number of
-- writ vouchers it returns.
function WritWorthy.ToVoucherCount(item_link)
    -- local reward_text = GenerateMasterWritRewardText(item_link)
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
function WritWorthy.MatTooltipText(mat_list, purchase_gold, voucher_ct)
                        -- No vouchers? No per-voucher cost.
    if (not voucher_ct) or (voucher_ct < 1) then return nil end

                        -- No cost? No per-voucher cost.
    if (not mat_list) and (not purchase_gold) then return nil end

                        -- Accumulators for totals and text
    local tooltip_elements   = {}
    local total_gold         = 0

    if mat_list then
        local mat_gold   = WritWorthy.MatRow.ListTotal(mat_list)
        if mat_gold then
            total_gold   = total_gold + mat_gold
        end
        local s = "Mat total: " .. Util.ToMoney(mat_gold) .. "g"
        if not mat_gold then
            s = "|c"..WritWorthy.Util.COLOR_RED..s.."|r"
        end
        table.insert( tooltip_elements, s)
    end

    if purchase_gold then
        total_gold       = total_gold + purchase_gold
        table.insert( tooltip_elements
                    , "Purchase: " .. Util.ToMoney(purchase_gold) .. "g" )
    end

    local per_voucher_gold = total_gold / voucher_ct
    table.insert( tooltip_elements
                , "Per voucher: " .. Util.ToMoney(per_voucher_gold) .. "g" )

                        -- Avoid line breaks in the middle of an element
                        -- Insert our own line break between elements 2 and 3.
    if 3 <= #tooltip_elements then
        return          tooltip_elements[1]
             .. "  " .. tooltip_elements[2]
             .. "\n" .. tooltip_elements[3]
     else
        return table.concat(tooltip_elements, " ")
     end
end

-- Return big red indicators for any required knowledge that you lack.
function WritWorthy.KnowTooltipText(know_list)
    if not know_list then return nil end
    local elements = {}
    for i, know in ipairs(know_list) do
        local s = know:TooltipText()
        if s then
            table.insert(elements, s)
        end
    end
    return table.concat(elements, "\n")
end

local function can_dump_matlist(enable, parser)
    if enable == WritWorthy.MAT_LIST_CHAT_ALL then
        return true
    elseif enable == WritWorthy.MAT_LIST_CHAT_ALCHEMY_ONLY
        and parser
        and parser.class == WritWorthy.Alchemy.Parser.class then
        return true
    end
    return false
end

-- Add text to a tooltip.
--
-- control:       the tooltip, responds to :AddLine(text)
-- link:          the item whose tip ZOScode is showing.
-- purchase_gold: if set, this is a tooltip for a guild store listing.
--                Include this cost in the gold-per-voucher calculation.
--                (optional, nil ok)
--
function WritWorthy.TooltipInsertOurText(control, item_link, purchase_gold, unique_id)
    -- Only fire for master writs.
    if ITEMTYPE_MASTER_WRIT ~= GetItemLinkItemType(item_link) then return end

    local mat_list, know_list, parser   = WritWorthy.ToMatKnowList(item_link)
    local voucher_ct = WritWorthy.ToVoucherCount(item_link)
    local mat_text = WritWorthy.MatTooltipText(mat_list, purchase_gold, voucher_ct)
    if not mat_text then return end
    if WritWorthy.savedVariables.enable_mat_price_tooltip ~= false then
        control:AddLine(mat_text)
    end
    if can_dump_matlist(WritWorthy.savedVariables.enable_mat_list_chat, parser) then
        WritWorthy.MatRow.ListDump(mat_list)
        --WritWorthy.KnowDump(know_list)
    end
    local know_text = WritWorthy.KnowTooltipText(know_list)
    if know_text then
        control:AddLine(know_text)
    end
                        -- Can we append WritWorthy queued/completed status?
                        -- We can if this writ is in our backpack and thus
                        -- has a unique_id.
                        --
                        -- The unique_id for bag position usually comes in
                        -- from ZOS inventory UI, but we can also inject it
                        -- from the WritWorthyInventoryList UI
    if not unique_id then
        unique_id = control.WritWorthy_UniqueId
    end
    if      unique_id
        and WritWorthyInventoryList.singleton then
        local inventory_data = WritWorthyInventoryList.singleton:UniqueIDToInventoryData(unique_id)
        if inventory_data then
            local text = nil
            local color = nil
            if inventory_data.ui_is_queued then
                text = "WritWorthy: queued for crafting"
                color = WritWorthyInventoryList.COLOR_TEXT_QUEUED
            elseif inventory_data.ui_is_completed then
                text = "WritWorthy: crafting completed"
                color = WritWorthyInventoryList.COLOR_TEXT_COMPLETED
            end
            if color and text then
                control:AddLine(Util.color(color, text))
            end
        end
    end
end

-- Write a list of required knowledge to chat.
function WritWorthy.KnowDump(know_list)
    if not know_list then
        -- d("know_list:"..tostring(know_list))
        return
    end
    local elements = {}
    for i, know in ipairs(know_list) do
        d(know:DebugText())
    end
    return table.concat(elements, "\n")
end

-- Scan inventory, return list of { link="xxx", parser=ParserXXX }
-- one element for each master writ found.
function WritWorthy:ScanInventoryForMasterWrits()
    local result_list = {}
    local bag_list = {BAG_BACKPACK}
    if self.savedVariables.enable_banked_vouchers then
        bag_list = {BAG_BACKPACK, BAG_BANK, BAG_SUBSCRIBER_BANK }
    end
    for _,bag_id in ipairs(bag_list) do
        local slot_ct = GetBagSize(bag_id)

                        -- Temporarily suspend all "dump matlist to chat"
                        -- to avoid scroll blindness
        local save_mat_list_chat = self.savedVariables.enable_mat_list_chat
        for slot_index = 0, slot_ct do
            local item_link = GetItemLink(bag_id, slot_index, LINK_STYLE_DEFAULT)
            local parser    = WritWorthy.CreateParser(item_link)
            if not (parser and parser:ParseItemLink(item_link)) then
                parser = nil
            end
            if parser then
                local unique_id = WritWorthy.UniqueID(bag_id, slot_index)
                local llc_req   = {}
                if parser.ToDolRequest then
                    llc_req = parser:ToDolRequest(unique_id)
                end
                local inventory_data =
                    { item_link           = item_link
                    , parser              = parser
                    , unique_id           = unique_id
                    , llc_func            = llc_req["function"]
                    , llc_args            = llc_req.args
                    }
                table.insert(result_list, inventory_data)
            end
        end
    end
                        -- Restore mat list to chat setting now that we're
                        -- done with chat-flooding scan.
    self.savedVariables.enable_mat_list_chat = save_mat_list_chat
    return result_list
end

function WritWorthy.UniqueID(bag_id, slot_index)
                        -- GetItemUniqueId(bag_id, slot_index) returns an id64
                        -- that cannot be rendered directly in savedVariables
                        -- or tostring(). Call ZOS function Id64ToString() to
                        -- turn it into something usable and saveable and
                        -- restorable. Do all our unique_id thinking in
                        -- strings, not id64.
    local id64 = GetItemUniqueId(bag_id, slot_index)
    local unique_id = Id64ToString(id64)
    return unique_id
end

-- Inventory UI: Save/Restore UI Position --------------------------------------------------

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
        WritWorthy.TooltipInsertOurText(control,GetItemLink(bagId,slotIndex)
                                , nil -- purchase_gold
                                , WritWorthy.UniqueID(bagId, slotIndex))
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
    local lam_addon_id = "WritWorthy_LAM"
    local panelData = {
        type                = "panel",
        name                = self.name,
        displayName         = self.name,
        author              = "ziggr",
        version             = self.version,
        --slashCommand        = "/gg",
        registerForRefresh  = false,
        registerForDefaults = false,
    }
    local cntrlOptionsPanel = LAM2:RegisterAddonPanel( lam_addon_id
                                                     , panelData
                                                     )
    local optionsData = {
        { type      = "checkbox"
        , name      = "Show material price in tooltip"
        , tooltip   = "Insert text into tooltip with the cost of all the"
                      .." materials that crafting this writ would consume."
        , getFunc   = function()
                        return self.savedVariables.enable_mat_price_tooltip ~= false
                      end
        , setFunc   = function(e)
                        self.savedVariables.enable_mat_price_tooltip = e
                      end
        },

        { type      = "dropdown"
        , name      = "Show material list in chat"
        , tooltip   = "Write several lines of materials to chat each"
                      .." time a Master Writ tooltip appears."
        , choices   = { WritWorthy.MAT_LIST_CHAT_OFF
                      , WritWorthy.MAT_LIST_CHAT_ALCHEMY_ONLY
                      , WritWorthy.MAT_LIST_CHAT_ALL
                      }
        , getFunc   = function()
                        return self.savedVariables.enable_mat_list_chat
                      end
        , setFunc   = function(e)
                        self.savedVariables.enable_mat_list_chat = e
                      end
        },

        { type      = "checkbox"
        , name      = "M.M. Fallback: hardcoded prices if no M.M. data"
        , tooltip   = "If M.M. has no price average for some materials:"
                      .."\n* use 15g for basic style materials such as Molybdenum"
                      .."\n* use 5g for common trait materials such as Quartz."
        , getFunc   = function()
                        return self.savedVariables.enable_mm_fallback
                      end
        , setFunc   = function(e)
                        self.savedVariables.enable_mm_fallback = e
                      end
        },

        { type      = "checkbox"
        , name      = "Station colors in window"
        , tooltip   = "Use different colors for blacksmithing, clothing, and"
                      .." woodworking items in the WritWorthy window."
        , getFunc   = function()
                        return self.savedVariables.enable_station_colors
                      end
        , setFunc   = function(e)
                        self.savedVariables.enable_station_colors = e
                      end
        },

        { type      = "checkbox"
        , name      = "Include writs from bank in auto-crafting window"
        , tooltip   = "Scan bank and include those writs in the list of"
                        .." writs available to automatically craft."
                        .."\n|cFF3333BE CAREFUL if you craft on multiple"
                        .." characters! WritWorthy will not warn you if you"
                        .." craft the same banked writ on multiple"
                        .." characters.|r"
        , getFunc   = function()
                        return self.savedVariables.enable_banked_vouchers
                      end
        , setFunc   = function(e)
                        self.savedVariables.enable_banked_vouchers = e
                      end
        },
    }

    LAM2:RegisterOptionControls(lam_addon_id, optionsData)
end

-- SlashCommand --------------------------------------------------------------

function WritWorthy.Forget()
                        -- Forget everything this one character has already
                        -- crafted.
                        --
                        -- Helpful when testing on PTS and you want to keep
                        -- trying to craft the same few writs over and over.
    WritWorthy.savedChariables.writ_unique_id = {}
end

function WritWorthy.SlashCommand(arg1)
    if arg1:lower() == "discover" then
        d("|c999999WritWorthy: scanning writ fields...|r")
        WritWorthy.Smithing.Discover()
    elseif arg1:lower() == "forget" then
        d("|c999999WritWorthy: forgetting everything this character already crafted...|r")
        WritWorthy.Forget()
    elseif arg1:lower() == "count" then
        local mwlist = WritWorthy:ScanInventoryForMasterWrits()
        local mw_ct = #mwlist
        local voucher_ct = 0
        for _,mw in ipairs(mwlist) do
            local vc  = WritWorthy.ToVoucherCount(mw.item_link)
            voucher_ct = voucher_ct + vc
        end
        d(string.format( "|c999999WritWorthy: %d writs, %d vouchers|r"
                       , mw_ct
                       , Util.ToMoney(voucher_ct)
                       ))
        WritWorthy.Forget()
    else
        WritWorthyUI_ToggleUI()
    end
end

-- Init ----------------------------------------------------------------------

function WritWorthy.OnAddOnLoaded(event, addonName)
    if addonName == WritWorthy.name then
        if not WritWorthy.version then return end
        WritWorthy:Initialize()
        WritWorthy.InitAGSIntegration()
    -- elseif addonName == "AwesomeGuildStore" then
    --     WritWorthy.InitAGSIntegration()
    end
end

function WritWorthy:Initialize()
                        -- Account-wide for most things
    self.savedVariables = ZO_SavedVars:NewAccountWide(
                              "WritWorthyVars"
                            , self.savedVarVersion
                            , nil
                            , self.default
                            )
    if self.savedVariables.log then
        Log:LoadPreviousQueue(self.savedVariables.log)
    end
    self.savedVariables.log = Log.q
                        -- Per-character for each character's inventory list.
    self.savedChariables = ZO_SavedVars:New("WritWorthyVars"
                            , self.savedVarVersion
                            , nil
                            , self.defaultChar
                            )

    WritWorthy.TooltipInterceptInstall()
    self:CreateSettingsWindow()

    WritWorthy.InventoryList = WritWorthyInventoryList:New()

                        -- Load the LibLazyCrafting queue BEFORE we start up
                        -- the list UI. This gives the list UI actual queue
                        -- data to consume when deciding which checkboxes to
                        -- initially mark checked.
    WritWorthyInventoryList.RestoreFromSavedChariables()

    WritWorthy.InventoryList:BuildMasterlist()
    WritWorthy.InventoryList:Refresh()

    WritWorthyUI_RestorePos()

    --EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)
end

-- Postamble -----------------------------------------------------------------

EVENT_MANAGER:RegisterForEvent( WritWorthy.name
                              , EVENT_ADD_ON_LOADED
                              , WritWorthy.OnAddOnLoaded
                              )

ZO_CreateStringId("SI_BINDING_NAME_WritWorthyUI_ToggleUI",       "Show/Hide WritWorthy")

SLASH_COMMANDS["/writworthy"] = WritWorthy.SlashCommand
