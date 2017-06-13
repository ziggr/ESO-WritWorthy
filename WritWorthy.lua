-- WritWorthy: Is this Maaster Writ worth doing?
--
-- In a master writ's tooltip, include the material cost for that writ
-- as both a gold total, and a gold per writ voucher reward.

local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Define.lua
local LAM2 = LibStub("LibAddonMenu-2.0")

WritWorthy.name            = "WritWorthy"
WritWorthy.version         = "3.0.2"
WritWorthy.savedVarVersion = 1
WritWorthy.default = {
    enable_mat_list_chat = false

                        -- UI topleft
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
    return mat_list, know_list
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
        table.insert( tooltip_elements
                    , "Mat total: " .. Util.ToMoney(mat_gold) .. "g" )
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

    local mat_list, know_list   = WritWorthy.ToMatKnowList(item_link)
    local voucher_ct = WritWorthy.ToVoucherCount(item_link)
    local mat_text = WritWorthy.MatTooltipText(mat_list, purchase_gold, voucher_ct)
    if not mat_text then return end
    control:AddLine(mat_text)
    if WritWorthy.savedVariables.enable_mat_list_chat then
        WritWorthy.MatRow.ListDump(mat_list)
        --WritWorthy.KnowDump(know_list)
    end
    local know_text = WritWorthy.KnowTooltipText(know_list)
    if know_text then
        control:AddLine(know_text)
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
    local bag_id = BAG_BACKPACK
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
            parser.unique_id = unique_id
            table.insert(result_list, { item_link  = item_link
                                      , parser     = parser
                                      , unique_id  = unique_id
                                      } )
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

    WritWorthy.LibLazyCrafting = nil    -- lazy initialized in :GetLLC()


    WritWorthy.TooltipInterceptInstall()
    self:CreateSettingsWindow()

    self:RestorePos()
    self:RestoreFromSavedChariables()

    WritWorthy.InventoryList = WritWorthyInventoryList:New()
    WritWorthy.InventoryList:BuildMasterlist()
    WritWorthy.InventoryList:Refresh()

    --EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)
end

-- Postamble -----------------------------------------------------------------

EVENT_MANAGER:RegisterForEvent( WritWorthy.name
                              , EVENT_ADD_ON_LOADED
                              , WritWorthy.OnAddOnLoaded
                              )

ZO_CreateStringId("SI_BINDING_NAME_WritWorthy_ToggleUI",       "Show/Hide WritWorthy")

