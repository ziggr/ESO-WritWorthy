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

                        -- Provisioning fields written when Provisioning.ZZ_SAVE_DATA = true.
                        -- This is how Zig exports a table of recipe/ingredients.
                        -- Provisioning fields here are never read.
,   provisioning_recipes = {}
,   provisioning_ingredient_links = {}
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

-- Dolgubon integration ------------------------------------------------------
--
-- If Dolgubon's Lazy Set (SET not Writ!) Crafter is installed, then enqueue
-- a crafting request for each craftable BS/CL/WW master writ in our inventory.

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

-- Can we craft this item in Dolgubon's Lazy Set Crafter?
function WritWorthy.Dol_IsQueueable(parser)
    if not parser.can_dolgubon then return false end

                        -- Some parsers do not have knowledge checks (alchemy).
    if not parser.ToKnowList then return true end
    local know_list = nil
    if parser.ToKnowList then
        know_list = parser:ToKnowList()
    end
    if know_list then
        for _, know in ipairs(know_list) do
            if not know.is_known then return false end
        end
    end
    return true
end

-- If Dolgubon's Lazy Set Crafter is installed, enqueue one crafting request
-- in Dolgubon's for each BS/CL/WW master writ in the current character's
-- inventory.
--
-- Probably should not do this while AT a crafting station: will need to
-- exit+re-enter that station to start crafting.
--
function WritWorthy_Dol_EnqueueAll()
    local DOL = DolgubonSetCrafter -- for less typing
    if not (DOL and DOL.savedVars.counter) then
        d("WritWorthy: Cannot queue items for crafting."
          .." Requires Dolgubon's Lazy Set Crafter version 1.0.8 or later.")
        return
    end
                        -- Avoid duplicate requests by keeping track of
                        -- which writs we've already requested.
    local queued_id = WritWorthy:Dol_QueuedIDs()
                        -- Scan inventory and build a list of all
                        -- that we can craft in Dolgubon's Lazy Set Crafter.
    d("WritWorthy: Scanning inventory for master writs...")
    local mw_list = WritWorthy:ScanInventoryForMasterWrits()
    local q_able_list = {}
    local unique_ids = {}
    local dol_ct = 0
    local dup_ct = 0
    for _, mw in ipairs(mw_list) do
                        -- Accumulate a hashtable of all master writ IDs
                        -- currently in our inventory. We'll use this
                        -- later to accelerate removal of stale IDs.
        unique_ids[mw.parser.unique_id] = true
                        -- Skip if already queued.
        local dol_reference = queued_id[mw.parser.unique_id]
        local dol_item_list = DOL.LazyCrafter:findItemByReference(dol_reference)

        if dol_reference and (0 < #dol_item_list) then
            dup_ct = dup_ct + 1
        elseif not WritWorthy.Dol_IsQueueable(mw.parser) then
        else
            dol_ct = dol_ct + 1
            table.insert(q_able_list, mw)
        end
    end
    if 0 < dol_ct then
        d("WritWorthy: queued requests for " ..tostring(dol_ct).." out of "
          ..tostring(#mw_list).." master writs.")
    end
    if 0 < dup_ct then
        d("WritWorthy: skipped requests for " ..tostring(dup_ct)
          .." master writs already queued.")
    end
                        -- Purge old writs from our unique_id -> Dol reference
                        -- deduplication table.
    WritWorthy:Dol_RemoveStaleQueuedIDs(unique_ids)

                        -- Queue up all requests.
    for _, r in ipairs(q_able_list) do
        local dol_request = r.parser:ToDolRequest()
        table.insert(DOL.savedVars.queue, dol_request)
        local o = dol_request.CraftRequestTable
        DOL.LazyCrafter:CraftSmithingItemByLevel(unpack(o))
    end
    DOL.updateList()
end

function WritWorthy:Dol_QueuedIDs()
    if not self.savedVariables.dol_queued_ids then
        self.savedVariables.dol_queued_ids = {}
    end
    return self.savedVariables.dol_queued_ids
end

-- Do we still have writ -> counter records for writs we no longer posess?
-- Stop wasting memory on them.
function WritWorthy:Dol_RemoveStaleQueuedIDs(current_unique_ids)
    if not self.savedVariables.dol_queued_ids then return end
    local DOL = DolgubonSetCrafter
                        -- Build a list of the doomed.
                        -- Don't remove from a collection while iterating over
                        -- that collection: might be safe, but I really don't
                        -- want to have to pore over Lua library details to be
                        -- sure.
    local remove_list = {}
    for unique_id, dol_reference in pairs(self.savedVariables.dol_queued_ids) do
                        -- No longer in our inventory
        if not current_unique_ids[unique_id] then
            table.insert(remove_list, unique_id)
        else
                        -- No longer queued in Dolgubon.
            local m = DolgubonSetCrafter.LazyCrafter:findItemByReference(dol_reference)
            if #m <= 0 then
                table.insert(remove_list, unique_id)
            end
        end
    end
                        -- Remove.
    for _, unique_id in pairs(remove_list) do
        self.savedVariables.dol_queued_ids[unique_id] = nil
    end
end

function WritWorthy:Dol_AssignReference(unique_id)
    local queued_ids = WritWorthy:Dol_QueuedIDs()
    if queued_ids[unique_id] then
        d("WritWorthy: unique_id already queued once? "..tostring(unique_id))
    end
    DolgubonSetCrafter.savedVars.counter = DolgubonSetCrafter.savedVars.counter + 1
    local reference = DolgubonSetCrafter.savedVars.counter
    queued_ids[unique_id] = reference
    return reference
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
    WritWorthy.TooltipInterceptInstall()
    self:CreateSettingsWindow()
    --EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)
end

-- Postamble -----------------------------------------------------------------

EVENT_MANAGER:RegisterForEvent( WritWorthy.name
                              , EVENT_ADD_ON_LOADED
                              , WritWorthy.OnAddOnLoaded
                              )

ZO_CreateStringId("SI_BINDING_NAME_WritWorthy_Dol_EnqueueAll", "Enqueue All in Dolgubon's")

