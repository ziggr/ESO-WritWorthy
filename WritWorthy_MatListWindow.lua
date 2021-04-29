-- Window to display list of required materials.

local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Define.lua
WritWorthy.MatUI = ZO_SortFilterList:Subclass()
-- Inherits field "self.list" which is the scroll list control.
-- "WritWorthy.MatUI" is NOT the actual list control that has useful
-- "data members. Use WritWorthy.MatUI.scroll_filter_list for that.

local Util = WritWorthy.Util
local Fail = WritWorthy.Util.Fail
local Log  = WritWorthy.Log
local WW   = WritWorthy
                        -- savedVariables key for window position
local WINDOW_POS_KEY = "mat_list_position"

                        -- How ZO_SortFilterList differentiates row data types
                        -- for heterogeneous data. But our data's homogeneous,
                        -- so use this same type for each row
local DATA_TYPE_ID = 1


                        -- The header controls for each of our lists, recorded
                        -- during WritWorthyHeaderInit().
                        -- [column_name] = control
WritWorthy.MatUI.list_header_controls = {}

                        -- The master list of row data for the inventory list
                        -- in no particular order.
WritWorthy.MatUI.data_list = {}

                        -- Live row_control used to lay out rows. Remembered
                        -- during SetupRowControl(). Used in
                        -- UpdateAllCellWidths().
WritWorthy.MatUI.row_control_list = {}

                        -- How to break ties when sorting by any
                        -- specific column. Avoid cycles!`
WritWorthy.MatUI.SORT_KEYS = {
  ["ui_name"        ] = {                                       }
, ["ui_required_ct" ] = { tiebreaker="ui_name" , isNumeric=true }
, ["ui_have_ct"     ] = { tiebreaker="ui_name" , isNumeric=true }
, ["ui_buy_ct"      ] = { tiebreaker="ui_name" , isNumeric=true }
, ["ui_price_ea"    ] = { tiebreaker="ui_name" , isNumeric=true }
, ["ui_buy_subtotal"] = { tiebreaker="ui_name" , isNumeric=true }
}
                        -- The XML name suffixes for each of our columns.
                        -- NOT used for UI display (although they often match).
                        -- Useful when iterating through columns/cells.
WritWorthy.MatUI.CELL_NAME           = "Name"
WritWorthy.MatUI.CELL_REQUIRED_CT    = "RequiredCt"
WritWorthy.MatUI.CELL_HAVE_CT        = "HaveCt"
WritWorthy.MatUI.CELL_BUY_CT         = "BuyCt"
WritWorthy.MatUI.CELL_PRICE_EA       = "PriceEa"
WritWorthy.MatUI.CELL_BUY_SUBTOTAL   = "BuySubtotal"
WritWorthy.MatUI.CELL_NAME_LIST = {
  WritWorthy.MatUI.CELL_NAME
, WritWorthy.MatUI.CELL_REQUIRED_CT
, WritWorthy.MatUI.CELL_HAVE_CT
, WritWorthy.MatUI.CELL_BUY_CT
, WritWorthy.MatUI.CELL_PRICE_EA
, WritWorthy.MatUI.CELL_BUY_SUBTOTAL
}
WritWorthy.MatUI.HEADER_TOOLTIPS = {
  [WritWorthy.MatUI.CELL_NAME        ] = WW.Str("header_tooltip_Name")
, [WritWorthy.MatUI.CELL_REQUIRED_CT ] = WW.Str("header_tooltip_RequiredCt")
, [WritWorthy.MatUI.CELL_HAVE_CT     ] = WW.Str("header_tooltip_HaveCt")
, [WritWorthy.MatUI.CELL_BUY_CT      ] = WW.Str("header_tooltip_BuyCt")
, [WritWorthy.MatUI.CELL_PRICE_EA    ] = WW.Str("header_tooltip_PriceEa")
, [WritWorthy.MatUI.CELL_BUY_SUBTOTAL] = WW.Str("header_tooltip_BuySubtotal")
}

WritWorthy.MatUI.ROW_HEIGHT = 30

WritWorthy.MatUI.COLOR_TEXT_NEED_MORE    = "CC3333"
WritWorthy.MatUI.COLOR_TEXT_HAVE_ENOUGH  = "FFFFFF"

WritWorthy.MatUI.FILTER_NAME_ALL_MATS       = "mat_ui_filter_all_mats"
WritWorthy.MatUI.FILTER_NAME_MISSING_MATS   = "mat_ui_filter_missing_mats"
WritWorthy.MatUI.FILTER_NAME_MISSING_MOTIFS = "mat_ui_filter_missing_motifs"
WritWorthy.MatUI.FILTER_NAMES_LIST = {
     WritWorthy.MatUI.FILTER_NAME_ALL_MATS
,    WritWorthy.MatUI.FILTER_NAME_MISSING_MATS
-- ,    WritWorthy.MatUI.FILTER_NAME_MISSING_MOTIFS
}


-- REMOVE ME -- debugging check to learn that the parameter "self" in XML-hosted
--              code is indeed the XML control.
-- function WritWorthy.MatUI.OnInitialized(top_level_control)
--     d("WWMUI.OnInitialized() top_level_control    :"..tostring(top_level_control))
--     d("WWMUI.OnInitialized() WritWorthyMatWindow  :"..tostring(WritWorthyMatWindow))
-- end
-- end REMOVE ME

-- MatUI: The window around the material list --------------------------------
function WritWorthy.MatUI:LazyInit()
    Log.Debug("WWML:LazyInit()")

                        -- Bring our portion of saved variables into existence
                        -- if necessary.
    WritWorthy.savedVariables.mat_ui = WritWorthy.savedVariables.mat_ui or {}

                        -- Create a ZO controller for our list UI. The
                        -- controller connects the XML-defined "...List"
                        -- container element with its "...ListHeaders" and
                        -- "...ListList" element. Will call back into us
                        --
                        -- Pass ourself WW.MatUI as the delegate for
                        -- calls :Initialize(), :CreateRowControlCells(),
                        -- and many, many more.
                        --
    local o = ZO_SortFilterList.New(self, WritWorthyMatUIListContainer)
    WritWorthy.MatUI.scroll_filter_list = o

                        -- Replace label with combo box.
    local container = WritWorthyMatWindowComboBoxPlaceholder
    local cb_name = nil
    local cb = WINDOW_MANAGER:CreateControlFromVirtual(
                      cb_name
                    , container
                    , "ZO_ComboBox"
                    )
    WritWorthy.MatUI.combo_box = cb
    cb:SetAnchor(TOPLEFT,     container, TOPLEFT,     0, 0)
    cb:SetAnchor(BOTTOMRIGHT, container, BOTTOMRIGHT, 0, 0)
    cb.m_comboBox:SetSortsItems(false)
    local function fn(control, choice_text, choice_entry)
        Log.Debug("Filter choice_text:"..choice_text)
        Log.Debug("Filter filter_name:"..choice_entry.filter_name)
        WritWorthy.savedVariables.mat_ui.filter_name = choice_entry.filter_name
        WritWorthy.MatUI.RefreshSoon()
    end
    local cb_items = {}
    for _, filter_name in ipairs(WritWorthy.MatUI.FILTER_NAMES_LIST) do
        local text = WW.Str(filter_name)
        local e = cb.m_comboBox:CreateItemEntry(text, fn)
        e.filter_name = filter_name
        cb.m_comboBox:AddItem(e, ZO_COMBOBOX_SUPPRESS_UPDATE)
        cb_items[filter_name] = e
    end
    local initial_filter = WritWorthy.savedVariables.mat_ui.filter_name
                        or WritWorthy.MatUI.FILTER_NAME_ALL_MATS
    WritWorthy.MatUI.SelectFilterComboBox(initial_filter, true)
    cb:SetHidden(false)
end

function WritWorthy.MatUI.RestorePos()
    Log.Debug("WWMUI_RestorePos()")
    Util.RestorePos(WritWorthyMatWindow, WINDOW_POS_KEY)
end

function WritWorthy.MatUI.OnMoveStop()
    Log.Debug("WWMUI_OnMoveStop()")
    Util.OnMoveStop(WritWorthyMatWindow, WINDOW_POS_KEY)
end

function WritWorthy.MatUI.OnResizeStop()
    Log.Debug("WWMUI_OnResizeStop()")
    Util.OnResizeStop( WritWorthyMatWindow
                     , WritWorthy.MatUI
                     , WritWorthy.MatUI.scroll_filter_list
                     , WINDOW_POS_KEY )
end

function WritWorthy.MatUI.ToggleUI()
    Log.Debug("WWMUI_ToggleUI()")
    if not WritWorthyMatWindow then
        Log.Error("WritWorthyMatWindow missing")
        return
    end
    local h = WritWorthyMatWindow:IsHidden()
    if h then
        WritWorthy.MatUI.RestorePos()
        WritWorthy.MatUI.RefreshUI()
        WritWorthy.MatUI:UpdateAllCellWidths()
        WritWorthy.MatUI:RegisterListeners()
        WritWorthy.MatUI.RefreshSoon()
    else
        WritWorthy.MatUI:UnregisterListeners()
    end
    WritWorthyMatWindow:SetHidden(not h)
end

-- Wrapper function called by "Refresh" shark arrow button.
function WritWorthy.MatUI.RefreshUI()
    local list = WritWorthy.MatUI.scroll_filter_list
    WritWorthy_MatUI_Refresh()
end

function WritWorthy_MatUI_Refresh()
    Log.Debug("WWUI:Refresh()")
                        -- Ignore refreshes that come in before ever showing
                        -- our window, or while our window is closed.
    if WritWorthyMatWindow:IsHidden() then
        return
    end
    local list = WritWorthy.MatUI.scroll_filter_list
    list:BuildMasterlist()
    list:Refresh()
    -- self:UpdateSummary() -- ### Why isn't this function entered in MatUI's table?
end

-- Rather than waste CPU time re-calculating window display state
-- every time the user types a keystroke in a filter edit box,
-- queue up a request to update the entire UI soon, and then
-- only do so if the user has stopped typing.
function WritWorthy.MatUI.RefreshSoon()
    Util.CallSoon("wwmui.refreshsoon_ms", WritWorthy_MatUI_Refresh)
end


function WritWorthy.MatUI.HeaderInit(control, name, text, key)
    Log.Debug( "WWMUI_HeaderInit() c:%s n:%s t:%s k:%s"
             , tostring(control), name, text, key )
    local l10n_text = WW.Str("header_"..name) or text
                        -- All our columns are numeric, align-right,
                        -- except for our leftmost column "Name"
    local align     = TEXT_ALIGN_RIGHT
    if key == "ui_name" then
        align = TEXT_ALIGN_LEFT
    end

    ZO_SortHeader_Initialize( control                   -- control
                            , l10n_text                 -- name
                            , key or string.lower(text) -- key
                            , ZO_SORT_ORDER_DOWN        -- initialDirection
                            , align or TEXT_ALIGN_LEFT  -- alignment
                            , "ZoFontWinT1"             -- font
                            , nil                       -- highlightTemplate
                            )

                        -- Remember this control!
                        --
                        -- The header cell control that we get here, and which
                        -- ZO_SortHeader_Initialize() fills in is NOT the same
                        -- as the XML template control reachable from
                        -- WritWorthyMatUIListContainerHeaders:GetNamedChild().
                        -- We need this actual header cell control, which has
                        -- Text and alignment and live data, in addition to the
                        -- XML template control (which has dynamic width,
                        -- thanks to its two anchors).
    WritWorthy.MatUI.list_header_controls[name] = control

    local tooltip_text = WritWorthy.MatUI.HEADER_TOOLTIPS[name]
    if tooltip_text then
        ZO_SortHeader_SetTooltip(control, tooltip_text)
    end
end

-- First time through a row's SetupRowControl(), programmatically create the
-- individual label controls that will hold cell text. Doing so
-- programmatically here is less maintenance work than  trying to keep the XML
-- "virtual" row in sync with the XML headers.
--
-- Do not fill labels with live text: that's SetupRowControl()'s job.
function WritWorthy.MatUI:CreateRowControlCells(row_control, header_container)
    for i, cell_name in ipairs(self.CELL_NAME_LIST) do
        local header_cell_control = header_container:GetNamedChild(cell_name)
        local control_name        = row_control:GetName() .. cell_name
        local cell_control        = nil
        local is_text             = true
        local rel_to_left         = header_container:GetLeft()
        local cell_control        = row_control:CreateControl(control_name, CT_LABEL)
        row_control[cell_name]    = cell_control
        local y_offset            = 0

        Util.SetAnchorCellLeft( row_control
                              , cell_control
                              , header_cell_control
                              , i == 1
                              , y_offset
                              , rel_to_left )

        cell_control:SetHidden(false)

        cell_control:SetWidth(header_cell_control:GetWidth())
        cell_control:SetHeight(self.ROW_HEIGHT - y_offset)

        cell_control:SetFont("ZoFontGame")
        cell_control:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)

        Util.SetCellToHeaderAlign( cell_control
                                 , header_container
                                 , self.list_header_controls[cell_name] )

                            -- Click to toggle item tooltip for row's mat/motif
        cell_control:SetMouseEnabled(true)
        cell_control:SetHandler("OnMouseDown", WritWorthy.MatUI.Cell_OnMouseDown)
    end
end

-- After a resize, widen our "detail1" column and nudge the others to its right.
function WritWorthy.MatUI:UpdateAllCellWidths()
    Log.Debug("WWML:UpdateAllCellWidths")
    for _, row_control in ipairs(self.row_control_list) do
        self:UpdateColumnWidths(row_control)
    end
end


-- Change column width/offsets after a window resize. NOP if nothing changed.
function WritWorthy.MatUI:UpdateColumnWidths(row_control)
                        -- Do nothing if we have not yet fully initialized.
    local container = WritWorthyMatUIListContainer
    if not container then return end
    local header_container = container:GetNamedChild("Headers")
    if not header_container then return end

    local header_control = header_container:GetNamedChild("Name")
    if not header_control then return end
    local rel_to_left = header_control:GetLeft()

                        -- Cache header cell controls from which we'll
                        -- gather column widths. We want the GetNamedChild()
                        -- controls (they have anchors and dynamic width)
                        -- not the ZO_SortHeader_Initialize() controls
                        -- (which appear to never change widths).
    local hcl = {}
    for cell_name, _ in pairs(self.list_header_controls) do
        hcl[cell_name] = header_container:GetNamedChild(cell_name)
    end

    for cell_name, _ in pairs(self.list_header_controls) do
        local cell_control = row_control:GetNamedChild(cell_name)
        local header_cell_control = hcl[cell_name]
        if header_cell_control then
            local offsetX = header_cell_control:GetLeft() - rel_to_left
                        -- 1 bool    isValidAnchor
                        -- 2 integer point
                        -- 3 object  relativeTo
                        -- 4 integer relativePoint
                        -- 5 number  offsetX
                        -- 6 number  offsetY
                        -- 7 AnchorConstrains anchorConstrains
            local a = { cell_control:GetAnchor(0) }
            if a and a[1] then
                cell_control:SetAnchor( LEFT                -- point
                                      , row_control         -- relativeTo
                                      , LEFT                -- relativePoint
                                      , offsetX             -- offsetX
                                      , a[6] )              -- offsetY
            end
            cell_control:SetWidth(header_cell_control:GetWidth())
        end
    end
    Util.StretchBGWidth(row_control)
end

-- Called by ZO_SortFilterList:New()
function WritWorthy.MatUI:Initialize(control)
    ZO_SortFilterList.Initialize(self, control)
    self.mat_row_data_list = {}
    self:SetEmptyText("no materials required")

                        -- Tell ZO_ScrollList how it can ask us to
                        -- create row controls.
    ZO_ScrollList_AddDataType(
          self.list             -- scroll list control
        , DATA_TYPE_ID          -- row data type ID
        , "WritWorthyMatUIRow"  -- template: virtual button defined in XML
        , self.ROW_HEIGHT       -- row height
                                -- setupCallback
        , function(control, mat_row_data)
             self:SetupRowControl(control, mat_row_data)
         end
        )

    self:RefreshData()
end

-- Convert integer 987 to "1K"
local function abbr_num(num)
    return ZO_AbbreviateNumber( num
                              , NUMBER_ABBREVIATION_PRECISION_LARGEST_UNIT
                              , true
                              )
end

-- ZO_ScrollFilterList will instantiate (or reuse!) a
-- WritWorthyMatUIRow row_control to display some mat_row_data. But
-- it's our job to fill in that control's nested labels with the appropriate
-- bits of data.
--
-- Called as self.setupCallback from ZO_ScrollList_Commit()
--
-- mat_row_data is the instance passed to ZO_ScrollList_CreateDataEntry() by
-- FilterScrollList(), is an element of master list
-- WritWorthy.MatUI.mat_row_data_list.
function WritWorthy.MatUI:SetupRowControl(row_control, mat_row_data)
    Log.Verbose("SetupRowControl row_control:%s", tostring(row_control))
    row_control.mat_row_data = mat_row_data

                        -- ZO_SortList reuses row_control instances, so there
                        -- is a good chance we've already created these cell
                        -- controls.
    local already_created = row_control[self.CELL_NAME]
    if not already_created then
        local list_container   = WritWorthyMatUIListContainer
        local header_container = list_container:GetNamedChild("Headers")
        self:CreateRowControlCells(row_control, header_container)
                        -- Retain pointers to our row_control instances so that
                        -- we can update all their cell widths later upon
                        -- window resize.
        table.insert(self.row_control_list, row_control)
    end

    self:PopulateUIFields(mat_row_data)
                        -- Refresh mutable state (aka queued/completed)

                        -- For less typing.
    local rc  = row_control
    local r_d = mat_row_data

                        -- Replace item_link color with red if missing.
    local name = r_d.mat_row.link

                        -- Apply text color to entire row.
    local fn = Util.color
    local c  = self.COLOR_TEXT_HAVE_ENOUGH
    local is_missing = r_d.ui_have_ct < r_d.ui_required_ct
    if is_missing then
        c = self.COLOR_TEXT_NEED_MORE
        name = r_d.ui_name
    end

                        -- Allow each cell's OnMouseDown handler easy
                        -- access to this row's data.
    for _, name in ipairs(self.CELL_NAME_LIST) do
        rc[name].mat_row_data = r_d
    end
                        -- Fill in the cells with data for this row.
    rc[self.CELL_NAME        ]:SetText(fn(c,              name                ))
    rc[self.CELL_REQUIRED_CT ]:SetText(fn(c,     abbr_num(r_d.ui_required_ct )))
    rc[self.CELL_HAVE_CT     ]:SetText(fn(c,     abbr_num(r_d.ui_have_ct     )))
    rc[self.CELL_PRICE_EA    ]:SetText(fn(c, Util.ToMoney(r_d.ui_price_ea    )))
    if 0 < r_d.ui_buy_ct then
        rc[self.CELL_BUY_CT      ]:SetText(fn(c,     abbr_num(r_d.ui_buy_ct      )))
        rc[self.CELL_BUY_SUBTOTAL]:SetText(fn(c, Util.ToMoney(r_d.ui_buy_subtotal)))
    else
        rc[self.CELL_BUY_CT      ]:SetText("")
        rc[self.CELL_BUY_SUBTOTAL]:SetText("")
    end
end

local function HaveCt(item_link)
    local bag_ct, bank_ct, craft_bag_ct = GetItemLinkStacks(item_link)
    return bag_ct + bank_ct + craft_bag_ct
end

-- Fill in all mat_row_data.ui_xxx fields.
function WritWorthy.MatUI:PopulateUIFields(mat_row_data)
    local r_d = mat_row_data -- For less typing.
    r_d.ui_name         = zo_strformat("<<t:1>>",GetItemLinkName(r_d.mat_row.link))
    r_d.ui_required_ct  = r_d.mat_row.ct
    r_d.ui_have_ct      = HaveCt(r_d.mat_row.link)
    r_d.ui_price_ea     = r_d.mat_row.mm or -1
    r_d.ui_buy_ct       = 0
    r_d.ui_buy_subtotal = 0

                        -- Only fill in buy cells if we need to buy some.
    if r_d.ui_have_ct < r_d.ui_required_ct then
        r_d.ui_buy_ct   = r_d.ui_required_ct - r_d.ui_have_ct
        if r_d.ui_price_ea == WritWorthy.GOLD_UNKNOWN then
            r_d.ui_buy_subtotal = -1 -- WritWorthy.GOLD_UNKNOWN
        else
            r_d.ui_buy_subtotal = r_d.ui_buy_ct * r_d.ui_price_ea
        end
    end
end

function WritWorthy.MatUI:BuildMasterlist()
    Log.Debug("WWMUI:BuildMasterlist()")

    local filter_name = self.GetFilterName() or WritWorthy.MatUI.FILTER_NAME_ALL_MATS

                        -- Accumulate all queued writs' materials
                        -- into a single, summed, table.
    mat_table = {} -- index = mat item_link, value = summed MatRow
    self.inventory_data_list = WritWorthy:ScanInventoryForMasterWrits()
    for _, inventory_data in pairs(self.inventory_data_list) do
        local is_queued    = WritWorthyInventoryList:IsQueued(inventory_data)
        local is_completed = WritWorthyInventoryList:IsCompleted(inventory_data)
        local is_use_mimic = WritWorthyInventoryList:IsUseMimic(inventory_data)
        if is_queued and not is_completed then
            local parser   = inventory_data.parser
            local mat_list = parser:ToMatList()
            for _, mat_row in ipairs(mat_list) do
                        -- Replace style mat with mimic stone, if requested.
                local item_link = mat_row.link
                if is_use_mimic and mat_row.can_mimic then
                    item_link = WritWorthy.LINK["mimic"]
                end
                        -- Add to existing accumulator cell, or...
                local mr2       = mat_table[item_link]
                if mr2 then
                    mr2.ct = mr2.ct + mat_row.ct
                else    -- Create new accumulator cell for this first appearance.
                    mr2 = WritWorthy.MatRow:FromLink(item_link, mat_row.ct)
                    mat_table[item_link] = mr2
                end
            end
        end
    end
                        -- Filter: pass all, or pass only missing
    local function filter_pass(mat_row, filter_name)
        if filter_name == WritWorthy.MatUI.FILTER_NAME_ALL_MATS then
            return true
        elseif filter_name == WritWorthy.MatUI.FILTER_NAME_MISSING_MATS then
            return mat_row:HaveCt() < mat_row.ct
        end
        return false
    end

    local u = {}
    for _, mat_row in pairs(mat_table) do
        if filter_pass(mat_row, filter_name) then
            local r_d = {}
            r_d.mat_row = mat_row
                        -- Must populate ui fields NOW so that sort will work.
                        -- Lazy-populating ui fields for rows not yet scrolled
                        -- into view will cause them to sort using nil ui cell
                        -- values, and that's not going to work.
            self:PopulateUIFields(r_d)
            table.insert(u, r_d)
        end
    end

    self.mat_row_data_list = u
    Log.Debug("WWMUI:BuildMasterlist() mrdl.ct:%d", #self.mat_row_data_list)
end

-- Populate the ScrollList's rows, using our data model as a source.
function WritWorthy.MatUI:FilterScrollList()
    local scroll_data = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scroll_data)
    for _, mat_row_data in ipairs(self.mat_row_data_list) do
        table.insert( scroll_data
                    , ZO_ScrollList_CreateDataEntry(DATA_TYPE_ID, mat_row_data))
    end
end

function WritWorthy.MatUI:SortScrollList()
                        -- How to order our table rows. Probably doesn't need
                        -- to be a specific data member with a specific name,
                        -- we just need to know how to find it and pass it to
                        -- table.sort() from within FilterScrollList() below.
    Log.Debug(string.format( "WWMUI:SortScrollList() key=%s order=%s"
                           , tostring(self.currentSortKey)
                           , tostring(self.currentSortOrder)
                           ))

    local sort_function = function(row_a, row_b)
        local key   = self.currentSortKey or "ui_name"
        local order = self.currentSortOrder
        if order == nil then
            order = ZO_SORT_ORDER_UP
        end
        return ZO_TableOrderingFunction( row_a.data
                                       , row_b.data
                                       , key
                                       , WritWorthy.MatUI.SORT_KEYS
                                       , order
                                       )
    end
    local scroll_data = ZO_ScrollList_GetDataList(self.list)
    table.sort(scroll_data, sort_function)
end

function WritWorthy.MatUI:Refresh()
    self:RefreshData()
end

function WritWorthy.MatUI:UpdateSummary()
    -- self.mat_row_data_list = {}
    Log.Debug("MMUI:UpdateSummary()")
    -- ###
end

-- Switch the combo box to the requested filter.
--
-- ignore_callback is optional, if passed nil/false, callbacks fire.
-- If true, suppresses callbacks.
function WritWorthy.MatUI.SelectFilterComboBox(filter_name, ignore_callback)
    local cb = WritWorthy.MatUI.combo_box.m_comboBox
    for index, item in ipairs(cb.m_sortedItems) do
        if item.filter_name == filter_name then
            cb:SelectItem(item, ignore_callback)
            return
        end
    end
end

function WritWorthy.MatUI.GetFilterName()
    local entry = WritWorthy.MatUI.combo_box.m_comboBox:GetSelectedItemData()
    return entry.filter_name
end

function WritWorthy.MatUI.Cell_OnMouseDown(cell_control)
    WritWorthy.X = cell_control
    if not (    cell_control
            and cell_control.mat_row_data
            and cell_control.mat_row_data.mat_row
            and cell_control.mat_row_data.mat_row.link) then
        return
    end
    ZO_PopupTooltip_SetLink(cell_control.mat_row_data.mat_row.link)
end

-- Intentory Listeners -------------------------------------------------------
--
-- Listen for inventory changes while our window is visible, so that we can
-- update with new "have/buy" counts.
--
-- EVENT_INVENTORY_SINGLE_SLOT_UPDATE is probably all we need, but I'm casting
-- a ridiculously wide net here to reduce the number of times in the next year
-- that I have to add yet another event to this list because "window didn't
-- update after I X'ed" for some as yet unknown "X'ed"
--
WritWorthy.MatUI.INVENTORY_EVENTS = {
  [EVENT_CLOSE_BANK                   ] = "EVENT_CLOSE_BANK"
, [EVENT_CRAFT_COMPLETED              ] = "EVENT_CRAFT_COMPLETED"
, [EVENT_END_CRAFTING_STATION_INTERACT] = "EVENT_END_CRAFTING_STATION_INTERACT"
, [EVENT_INVENTORY_FULL_UPDATE        ] = "EVENT_INVENTORY_FULL_UPDATE"
, [EVENT_INVENTORY_ITEM_DESTROYED     ] = "EVENT_INVENTORY_ITEM_DESTROYED"
, [EVENT_INVENTORY_SINGLE_SLOT_UPDATE ] = "EVENT_INVENTORY_SINGLE_SLOT_UPDATE"
, [EVENT_ITEM_SLOT_CHANGED            ] = "EVENT_ITEM_SLOT_CHANGED"
, [EVENT_LOOT_RECEIVED                ] = "EVENT_LOOT_RECEIVED"
}

function WritWorthy.MatUI.RegisterListeners()
    Log.Debug("WWMUI.RegisterListeners")
    for event_code, debug_name in pairs(WritWorthy.MatUI.INVENTORY_EVENTS) do
        EVENT_MANAGER:RegisterForEvent(WritWorthy.name, event_code, WritWorthy.MatUI.OnInventoryChanged)
    end

    -- EVENT_MANAGER:AddFilterForEvent( WritWorthy.name
    --                                , EVENT_INVENTORY_SINGLE_SLOT_UPDATE
    --                                , REGISTER_FILTER_INVENTORY_UPDATE_REASON
    --                                , INVENTORY_UPDATE_REASON_DEFAULT )
end

function WritWorthy.MatUI.UnregisterListeners()
    Log.Debug("WWMUI.UnregisterListeners")
    for event_code, debug_name in pairs(WritWorthy.MatUI.INVENTORY_EVENTS) do
        EVENT_MANAGER:UnregisterForEvent(WritWorthy.name, event_code)
    end
end

function WritWorthy.MatUI.OnInventoryChanged(event_code)
    local ev = WritWorthy.MatUI.INVENTORY_EVENTS[event_code or 0] or tostring(event_code)
    Log.Debug(string.format("WWMUI.OnInventoryChanged() %s",ev))
    WritWorthy.MatUI.RefreshSoon()
end

function WritWorthy.MatUI.OnWWQueueChanged()
    Log.Debug("WWMUI.OnWWQueueChanged()")
    WritWorthy.MatUI.RefreshSoon()
end
