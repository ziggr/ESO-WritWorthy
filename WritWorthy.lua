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

                        -- UI topleft
,   position = { 50, 50 }
}

                        -- The header controls for each of our lists, recorded
                        -- during WritWorthyHeaderInit().
                        -- [column_name] = control
WritWorthy.list_header_controls = {}

                        -- The master list of rows for the inventory list UI
                        -- in no particular order.
WritWorthy.inventory_data_list = {}

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

-- Inventory List UI, "row type".
--
-- We could choose to use different IDs for different types (consumables vs.
-- smithing) but that's more complexity than I want today. Sticking with
-- homogeneous data and a single data type. The list UI doesn't need to know or
-- care that some rows leave their cells blank because Provisioning writs lack
-- a "quality" field...
local TYPE_ID = 1

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

-- Inventory UI: Save/Restore UI Position --------------------------------------------------
function WritWorthy:RestorePos()
    local pos = self.default.position
    if self and self.savedVariables and self.savedVariables.position then
        pos = self.savedVariables.position
    end

    WritWorthyUI:SetAnchor(
             TOPLEFT
            ,GuiRoot
            ,TOPLEFT
            ,pos[1]
            ,pos[2]
            )
end

function WritWorthy_OnMouseUp()
    -- d("OnMouseUp")
    local l = WritWorthyUI:GetLeft()
    local t = WritWorthyUI:GetTop()
    local r = WritWorthyUI:GetRight()
    local b = WritWorthyUI:GetBottom()
    d("OnMouseUp ltrb=".. l .. " " .. t .. " " .. r .. " " .. b)
end

function WritWorthy_OnMoveStop()
    local l = WritWorthyUI:GetLeft()
    local t = WritWorthyUI:GetTop()
    local r = WritWorthyUI:GetRight()
    local b = WritWorthyUI:GetBottom()
    d("OnMoveStop ltrb=".. l .. " " .. t .. " " .. r .. " " .. b)
    -- ### Save Bounds
end

function WritWorthy_OnResizeStop()
    local l = WritWorthyUI:GetLeft()
    local t = WritWorthyUI:GetTop()
    local r = WritWorthyUI:GetRight()
    local b = WritWorthyUI:GetBottom()
    d("OnResizeStop ltrb=".. l .. " " .. t .. " " .. r .. " " .. b)
    -- WritWorthy.InventoryList:UpdateAllCellWidths()
    -- ### Save Bounds
end

-- Invetory UI ---------------------------------------------------------------
function WritWorthy_ToggleUI()
    d("toggle ui")
    ui = WritWorthyUI
    if not ui then
        d("No UI")
        return
    end
    h = WritWorthyUI:IsHidden()
    if h then
        WritWorthy:RestorePos()
    end
    WritWorthyUI:SetHidden(not h)

                        -- Refresh the list NOW after showing it.
                        -- I would prefer to refresh BEFORE showing, so once
                        -- this all works, try to move this up before
                        -- SetHidden(false).
    if h then
        WritWorthy.InventoryList:BuildMasterlist()
        WritWorthy.InventoryList:Refresh()
    end
end

function WritWorthy_HeaderInit(control, text)
    ZO_SortHeader_Initialize( control
                            , text
                            , string.lower(text)
                            , ZO_SORT_ORDER_DOWN
                            , align or TEXT_ALIGN_LEFT
                            , "ZoFontWinT1"
                            )

                        -- Remember this control!
                        --
                        -- The header cell control that we get here, and which
                        -- ZO_SortHeader_Initialize() fills in is NOT the same
                        -- as the XML template control reachable from
                        -- WritWorthyUIInventoryListHeaders:GetNamedChild().
                        -- We need this actual header cell control, which has
                        -- Text and alignment and live data, in addition to the
                        -- XML template control (which has dynamic width,
                        -- thanks to its two anchors).
    WritWorthy.list_header_controls[text] = control
end

WritWorthyInventoryList = ZO_SortFilterList:Subclass()
-- inherits field "self.list" which is the scroll list control

WritWorthyInventoryList.SORT_KEYS = {
  ["type"]    = {}
, ["detail1"] = {tiebreaker="type"}
, ["detail2"] = {tiebreaker="type"}
}

WritWorthyInventoryList.ROW_HEIGHT = 30

                        -- The XML name suffixes for each of our columns.
                        -- NOT used for UI display (although they often match).
                        -- Useful when iterating through columns/cells.
WritWorthyInventoryList.CELL_TYPE           = "Type"
WritWorthyInventoryList.CELL_VOUCHERCT      = "VoucherCt"
WritWorthyInventoryList.CELL_DETAIL1        = "Detail1"
WritWorthyInventoryList.CELL_DETAIL2        = "Detail2"
WritWorthyInventoryList.CELL_DETAIL3        = "Detail3"
WritWorthyInventoryList.CELL_DETAIL4        = "Detail4"
WritWorthyInventoryList.CELL_DETAIL5        = "Detail5"
WritWorthyInventoryList.CELL_QUEUEBUTTON    = "QueueButton"
WritWorthyInventoryList.CELL_DEQUEUEBUTTON  = "DequeueButton"
WritWorthyInventoryList.CELL_NAME_LIST = {
  WritWorthyInventoryList.CELL_TYPE
, WritWorthyInventoryList.CELL_VOUCHERCT
, WritWorthyInventoryList.CELL_DETAIL1
, WritWorthyInventoryList.CELL_DETAIL2
, WritWorthyInventoryList.CELL_DETAIL3
, WritWorthyInventoryList.CELL_DETAIL4
, WritWorthyInventoryList.CELL_DETAIL5
, WritWorthyInventoryList.CELL_QUEUEBUTTON
, WritWorthyInventoryList.CELL_DEQUEUEBUTTON
}


                        -- Live row_control used to lay out rows. Remembered
                        -- during SetupRowControl()
                        -- ZZ not sure if I need anymore
WritWorthyInventoryList.row_control_list = {}

function WritWorthyInventoryList:New()
    local o = ZO_SortFilterList.New(self, WritWorthyUIInventoryList)
    return o
end

function WritWorthyInventoryList:Initialize(control)
    ZO_SortFilterList.Initialize(self, control)
    self.inventory_data_list = {}

                        -- Tell ZO_ScrollList how it can ask us to
                        -- create row controls.
    ZO_ScrollList_AddDataType(
          self.list                     -- scroll list control
        , TYPE_ID                       -- row data type ID
        , "WritWorthyInventoryListRow"  -- tamplate: virtual button defined in XML
        , self.ROW_HEIGHT               -- row height
                                        -- setupCallback
        , function(control, inventory_data)
             self:SetupRowControl(control, inventory_data)
         end
        )

    ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight")

                        -- After ZO_SortFilterList:Initialize() we should
                        -- have a sortHeaderGroup. At least, that's how it
                        -- works in ScrollListExample.
    self.sortHeaderGroup:SelectHeaderByKey("detail1")
    ZO_SortHeader_OnMouseExit(WritWorthyUIInventoryListHeadersType)
    self:RefreshData()
end

-- Collect data that we'll eventually use to fill the inventory list UI.
-- Just data, no UI code here (that's FilterScrollList()'s job).
function WritWorthyInventoryList:BuildMasterlist()
    self.inventory_data_list = WritWorthy:ScanInventoryForMasterWrits()
end

-- Populate the ScrollList's rows, using our data model as a source.
function WritWorthyInventoryList:FilterScrollList()
    local scroll_data = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scroll_data)
    for _, inventory_data in ipairs(self.inventory_data_list) do
        table.insert( scroll_data
                    , ZO_ScrollList_CreateDataEntry(TYPE_ID, inventory_data))
    end
end

function WritWorthyInventoryList:Refresh()
    self:RefreshData()
end

-- First time through a row's SetupRowControl(), create the individual label
-- controls that will hold cell text.
function WritWorthyInventoryList:CreateRowControlCells(row_control, header_control)
    local prev_header_cell_control  = nil
    local prev_cell_control         = nil

    for i, cell_name in ipairs(self.CELL_NAME_LIST) do
        local header_cell_control = header_control:GetNamedChild(cell_name)
        local control_name = row_control:GetName() .. cell_name
        local cell_control = row_control:CreateControl(control_name, CT_LABEL)
        local horiz_align = TEXT_ALIGN_LEFT

        if i == 1 then
                        -- Leftmost column is flush up against
                        -- the left of the container
            cell_control:SetAnchor( LEFT                -- point
                                  , row_control         -- relativeTo
                                  , LEFT                -- relativePoint
                                  , 0                   -- offsetX
                                  , 0 )                 -- offsetY
        else
                        -- 2nd and later columns are to the right of
                        -- the previous column.
            local offsetX = header_cell_control:GetLeft()
                          - prev_header_cell_control:GetRight()

            cell_control:SetAnchor( LEFT                -- point
                                  , prev_cell_control   -- relativeTo
                                  , RIGHT               -- relativePoint
                                  , offsetX             -- offsetX
                                  , 0 )                 -- offsetY
        end

        cell_control:SetFont("ZoFontGame")
        cell_control:SetWidth(header_cell_control:GetWidth())
        cell_control:SetHeight(self.ROW_HEIGHT)
        cell_control:SetHidden(false)
        cell_control:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
        --cell_control:SetLinkEnabled(true)
        cell_control:SetMouseEnabled(true)

                        -- Surprise! Headers:GetNamedChild() returns a
                        -- control instance that lacks a "Name" sub-control,
                        -- which we need if we want to match text alignment.
                        -- Use the control we passed to
                        -- ZO_SortHeader_Initialize().
        local header_name_control = header_control:GetNamedChild("Name")
        if not header_name_control then
            local hc2 = WritWorthy.list_header_controls[cell_name]
            if hc2 then
                header_name_control = hc2:GetNamedChild("Name")
            end
        end
        if header_name_control then
            horiz_align = header_name_control:GetHorizontalAlignment()
        end
        cell_control:SetHorizontalAlignment(horiz_align)

                        -- Align all cells to top so that long/multiline text
                        -- still look acceptable.
        cell_control:SetVerticalAlignment(TEXT_ALIGN_TOP)

        row_control[cell_name]   = cell_control
        prev_cell_control        = cell_control
        prev_header_cell_control = header_cell_control
    end
end

-- After a resize, widen our "detail1" column and nudge the others to its right.
function WritWorthyInventoryList:UpdateAllCellWidths()
    for _, row_control in ipairs(self.row_control_list) do
        self:UpdateColumnWidths(row_control)
    end
end

-- Change column width/offsets after a window resize. NOP if nothing changed.
function WritWorthyInventoryList:UpdateColumnWidths(row_control)
                        -- Do nothing if we have not yet fully initialized.
    local hc = WritWorthyUIInventoryListHeadersType
    if not hc then return end

                        -- Cache header cell controls from which we'll
                        -- gather column widths. We want the GetNamedChild()
                        -- controls (they have anchors and dynamic width)
                        -- not the ZO_SortHeader_Initialize() controls
                        -- (which appear to never change widths).
    local hcl = {}
    for cell_name, _ in pairs(WritWorthy.list_header_controls) do
        hcl[cell_name] = WritWorthyUIInventoryListHeaders:GetNamedChild(cell_name)
    end

    local want_width = hc:GetWidth()
    for cell_name, _ in pairs(WritWorthy.list_header_controls) do
        local cell_control = row_control:GetNamedChild(cell_name)
        local header_cell_control = hcl[cell_name]
        cell_control:SetWidth(header_cell_control:GetWidth())
    end

                        -- I don't always have a background, but when I do,
                        -- I want it to stretch all the way across this row.
    local background_control = GetControl(row_control, "BG")
    if background_control then
        background_control:SetWidth(row_control:GetWidth())
    end
end

local SHORTEN = {
                        -- Parser.class and Smithing.SCHOOL_XXX.
}

-- Abbreviate strings so that they fit in narrow columns.
-- Increase data display density.
function WritWorthyInventoryList.Shorten(text)
    if not text then return "" end
    local s = SHORTEN[text]
    if s then return s end
    return text
end

                        -- Lazy-instantiate fields within our "data model"
                        -- that contain UI-centric user-visible text for
                        -- list display.
function WritWorthyInventoryList:PopulateUIFields(inventory_data)
    inventory_data.ui_voucher_ct = WritWorthy.ToVoucherCount(inventory_data.item_link)

                        -- For less typing.
    local parser = inventory_data.parser
    if parser.class == WritWorthy.Smithing.Parser.class then
        local ri     = parser.request_item  -- For less typing.
        local school = ri.school
        if school == WritWorthy.Smithing.SCHOOL_WOOD then
            inventory_data.ui_type = "Wood"
        else
            inventory_data.ui_type = school.armor_weight_name
        end
        inventory_data.ui_detail1 = parser.set_bonus.name
        inventory_data.ui_detail2 = ri.item_name
        inventory_data.ui_detail3 = parser.motif.motif_name
        inventory_data.ui_detail4 = ri.trait_set[parser.trait_num].trait_name
        inventory_data.ui_detail5 = parser.improve_level.name
    elseif parser.class == WritWorthy.Alchemy.Parser.class then
        inventory_data.ui_type =  "Alch"
        local mat_list = parser:ToMatList()
        inventory_data.ui_detail1 = mat_list[1].name
        inventory_data.ui_detail2 = mat_list[2].name
        inventory_data.ui_detail3 = mat_list[3].name
        inventory_data.ui_detail4 = mat_list[4].name
    elseif parser.class == WritWorthy.Enchanting.Parser.class then
        inventory_data.ui_type =  "Ench"
        if parser.level == 150 then
            inventory_data.ui_detail1 = "Superb"
        else
            inventory_data.ui_detail1 = "Truly Superb"
        end
        inventory_data.ui_detail2 = parser.glyph.name

        if parser.quality_num == 4 then
           inventory_data.ui_detail5 = "Epic"
        else
           inventory_data.ui_detail5 = "Legendary"
        end
    elseif parser.class == WritWorthy.Provisioning.Parser.class then
        inventory_data.ui_type =  "Prov"
        inventory_data.ui_detail1 = parser.fooddrink_name
    end

                        -- Since the point of these UI fields is to  drive the
                        -- UI, we might as well shorten them here, once, rather
                        -- than over and over again later during display and
                        -- sort.
                        --
                        -- Shorten() also converts empty/nil to "" for safer
                        -- use later.
                        --
                        -- leave ui_voucher_ct as an integer for better sorting.
    inventory_data.ui_type       = self.Shorten(inventory_data.ui_type      )
    inventory_data.ui_detail1    = self.Shorten(inventory_data.ui_detail1   )
    inventory_data.ui_detail2    = self.Shorten(inventory_data.ui_detail2   )
    inventory_data.ui_detail3    = self.Shorten(inventory_data.ui_detail3   )
    inventory_data.ui_detail4    = self.Shorten(inventory_data.ui_detail4   )
    inventory_data.ui_detail5    = self.Shorten(inventory_data.ui_detail5   )
end

-- ZO_ScrollFilterList will instantiate (or reuse!) a
-- WritWorthyInventoryListRow row_control to display some inventory_data. But
-- it's our job to fill in that control's nested labels with the appropriate
-- bits of data.
--
-- Called as self.setupCallback from ZO_ScrollList_Commit()
--
-- inventory_data is the instance passed to ZO_ScrollList_CreateDataEntry() by
-- FilterScrollList(), is an element of master list
-- WritWorthy.inventory_data_list.
function WritWorthyInventoryList:SetupRowControl(row_control, inventory_data)

    row_control.inventory_data = inventory_data

                        -- ZO_SortList reuses row_control instances, so there
                        -- is a good chance we've already created these cell
                        -- controls.
    local already_created = row_control[WritWorthyInventoryList.CELL_TYPE]
    if not already_created then
        local header_control = WritWorthyUIInventoryListHeaders
        self:CreateRowControlCells(
                  row_control
                , header_control
                )
                        -- Not sure we need to retain pointers to
                        -- our row_control instances.
        table.insert(self.row_control_list, row_control)
    end

    self:PopulateUIFields(inventory_data)

                        -- For less typing.
    local rc  = row_control
    local i_d = inventory_data

                        -- Fill in the cells with data for this row.
    rc[self.CELL_TYPE         ]:SetText(i_d.ui_type)
    rc[self.CELL_VOUCHERCT    ]:SetText(tostring(i_d.ui_voucher_ct))
    rc[self.CELL_DETAIL1      ]:SetText(i_d.ui_detail1)
    rc[self.CELL_DETAIL2      ]:SetText(i_d.ui_detail2)
    rc[self.CELL_DETAIL3      ]:SetText(i_d.ui_detail3)
    rc[self.CELL_DETAIL4      ]:SetText(i_d.ui_detail4)
    rc[self.CELL_DETAIL5      ]:SetText(i_d.ui_detail5)
    rc[self.CELL_QUEUEBUTTON  ]:SetText("v")  -- ###
    rc[self.CELL_DEQUEUEBUTTON]:SetText("x")  -- ###
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

    self:RestorePos()

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

ZO_CreateStringId("SI_BINDING_NAME_WritWorthy_Dol_EnqueueAll", "Enqueue All in Dolgubon's")
ZO_CreateStringId("SI_BINDING_NAME_WritWorthy_ToggleUI",       "Show/Hide WritWorthy")

