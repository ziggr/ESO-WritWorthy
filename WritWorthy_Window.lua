-- WritWorthy UI window
--
-- NOT putting tooltip or settings UI code here. Just the big list-of-writs
-- window.

local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Define.lua

                        -- The header controls for each of our lists, recorded
                        -- during WritWorthyHeaderInit().
                        -- [column_name] = control
WritWorthy.list_header_controls = {}

                        -- The master list of rows for the inventory list UI
                        -- in no particular order.
WritWorthy.inventory_data_list = {}

                        -- Dolgubon's LibLazyCrafting, which maintains
                        -- a queue of "stuff to automatically craft next
                        -- time you're at a appropriate station." Often
                        -- called "LLC" for a shorter abbreviation.
                        --
                        -- Version 0.3 has BS/CL/WW + Enchanting
                        -- Some later version might add Alchemy.
                        -- Not sure if we'll EVER add Provisioning.
                        --
WritWorthy.LibLazyCrafting = nil

local Log  = WritWorthy.Log
local Util = WritWorthy.Util

-- Inventory List UI, "row type".
--
-- We could choose to use different IDs for different types (consumables vs.
-- smithing) but that's more complexity than I want today. Sticking with
-- homogeneous data and a single data type. The list UI doesn't need to know or
-- care that some rows leave their cells blank because Provisioning writs lack
-- a "quality" field...
local TYPE_ID = 1

WritWorthyInventoryList = ZO_SortFilterList:Subclass()
-- inherits field "self.list" which is the scroll list control

WritWorthyInventoryList.SORT_KEYS = {
  ["ui_type"      ] = {tiebreaker="ui_voucher_ct"}
, ["ui_voucher_ct"] = {tiebreaker="ui_detail1", isNumeric=true }
, ["ui_detail1"   ] = {tiebreaker="ui_detail2"}
, ["ui_detail2"   ] = {tiebreaker="ui_detail3"}
, ["ui_detail3"   ] = {tiebreaker="ui_detail4"}
, ["ui_detail4"   ] = {tiebreaker="ui_detail5"}
, ["ui_detail5"   ] = {tiebreaker="ui_is_queued"}
, ["ui_is_queued" ] = {tiebreaker="ui_can_queue"}
, ["ui_can_queue" ] = {} -- Not a visible column, but does have visible effect on "is_queued" column.
}

WritWorthyInventoryList.ROW_HEIGHT = 30

                        -- Icons we display in our Enqueue/De
WritWorthyInventoryList.TEXTURE_SET_CHECKMARK = {
    normal      = "EsoUI/Art/Buttons/accept_up.dds"
,   pressed     = "EsoUI/Art/Buttons/accept_down.dds"
,   mouseOver   = "EsoUI/Art/Buttons/accept_over.dds"
}
WritWorthyInventoryList.TEXTURE_SET_X = {
    normal      = "EsoUI/Art/Buttons/checkbox_checked.dds"
,   pressed     = "EsoUI/Art/Buttons/decline_down.dds"
,   mouseOver   = "EsoUI/Art/Buttons/decline_over.dds"
}
WritWorthyInventoryList.TEXTURE_SET_X2 = {
    normal      = "EsoUI/Art/Buttons/decline_up.dds"
,   pressed     = "EsoUI/Art/Buttons/decline_down.dds"
,   mouseOver   = "EsoUI/Art/Buttons/decline_over.dds"
}


-- Values written to savedChariables
WritWorthy.STATE_QUEUED    = "queued"
WritWorthy.STATE_COMPLETED = "completed"

WritWorthyInventoryList.COLOR_TEXT_CANNOT_QUEUE = "CC3333"
WritWorthyInventoryList.COLOR_TEXT_CAN_QUEUE    = "CCCCCC"
WritWorthyInventoryList.COLOR_TEXT_QUEUED       = "FFFFFF"
WritWorthyInventoryList.COLOR_TEXT_COMPLETED    = "AAAAAA"

function WritWorthy:RestorePos()
    local pos = self.default.position
    if self and self.savedVariables and self.savedVariables.position then
        pos = self.savedVariables.position
    end

    if not WritWorthyUI then
                        -- Common crash that occurs when I've messed up
                        -- the XML somehow. Force it to crash here in this
                        -- if block rather than mysteriously on the
                        -- proper SetAnchor() line later.
        d("Your XML probably did not load. Fix it.")
        local _ = WritWorthyUI.SetAnchor
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
    WritWorthy.InventoryList:UpdateAllCellWidths()
    -- ### Save Bounds
end

function WritWorthy_ToggleUI()
    local ui = WritWorthyUI
    if not ui then
        return
    end
    h = WritWorthyUI:IsHidden()
    if h then
        WritWorthy:RestorePos()
        local t = WritWorthyUIInventoryListTitle
        if t then
            t:SetText("Writ Inventory: "..GetUnitName("player"))
        end
        WritWorthy.InventoryList:BuildMasterlist()
        WritWorthy.InventoryList:Refresh()
        WritWorthy.InventoryList:UpdateSummaryAndQButtons()
    end
    WritWorthyUI:SetHidden(not h)

end

-- Inventory List ------------------------------------------------------------

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
WritWorthyInventoryList.CELL_ENQUEUE        = "Enqueue"
WritWorthyInventoryList.CELL_ENQUEUE_MASK   = "EnqueueMask" -- not a cell on its own.
WritWorthyInventoryList.CELL_NAME_LIST = {
  WritWorthyInventoryList.CELL_TYPE
, WritWorthyInventoryList.CELL_VOUCHERCT
, WritWorthyInventoryList.CELL_DETAIL1
, WritWorthyInventoryList.CELL_DETAIL2
, WritWorthyInventoryList.CELL_DETAIL3
, WritWorthyInventoryList.CELL_DETAIL4
, WritWorthyInventoryList.CELL_DETAIL5
, WritWorthyInventoryList.CELL_ENQUEUE
}
-- Cells that are shown/hidden click buttons, not text data.
WritWorthyInventoryList.CELL_XML_LIST = {
  [WritWorthyInventoryList.CELL_ENQUEUE] = true
}
WritWorthyInventoryList.HEADER_TOOLTIPS = {
  [WritWorthyInventoryList.CELL_TYPE      ] = nil
, [WritWorthyInventoryList.CELL_VOUCHERCT ] = "Voucher count"
, [WritWorthyInventoryList.CELL_DETAIL1   ] = nil
, [WritWorthyInventoryList.CELL_DETAIL2   ] = nil
, [WritWorthyInventoryList.CELL_DETAIL3   ] = nil
, [WritWorthyInventoryList.CELL_DETAIL4   ] = nil
, [WritWorthyInventoryList.CELL_DETAIL5   ] = nil
, [WritWorthyInventoryList.CELL_ENQUEUE   ] = "Enqueued for crafting"
}

function WritWorthy_HeaderInit(control, name, text, key)
    ZO_SortHeader_Initialize( control                   -- control
                            , text                      -- name
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
                        -- WritWorthyUIInventoryListHeaders:GetNamedChild().
                        -- We need this actual header cell control, which has
                        -- Text and alignment and live data, in addition to the
                        -- XML template control (which has dynamic width,
                        -- thanks to its two anchors).
    WritWorthy.list_header_controls[name] = control

    local tooltip_text = WritWorthyInventoryList.HEADER_TOOLTIPS[name]
    if tooltip_text then
        ZO_SortHeader_SetTooltip(control, tooltip_text)
    end
end

                        -- Live row_control used to lay out rows. Remembered
                        -- during SetupRowControl()
                        -- ZZ not sure if I need anymore
WritWorthyInventoryList.row_control_list = {}

function WritWorthyInventoryList:New()
    local o = ZO_SortFilterList.New(self, WritWorthyUIInventoryList)
    WritWorthyInventoryList.singleton = o
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
    self.sortFunction
        = function(row_a, row_b)
            return ZO_TableOrderingFunction( row_a.data
                                           , row_b.data
                                           , self.currentSortKey
                                           , WritWorthyInventoryList.SORT_KEYS
                                           , self.currentSortOrder
                                           )
        end

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

function WritWorthyInventoryList:SortScrollList()
    -- Original boilerplate SortScrollList() implementation that works
    -- perfectly with the usual sortFunction
    --
    local scroll_data = ZO_ScrollList_GetDataList(self.list)
    table.sort(scroll_data, self.sortFunction)
end

function WritWorthyInventoryList:Refresh()
    Log:Add("WritWorthyInventoryList:Refresh")
    self:RefreshData()
end

function WritWorthyInventoryList_Cell_OnMouseEnter(cell_control)
    -- d("enter "..tostring(cell_control))
                        -- .tooltip_text is our own field, not ZOS'.
                        -- We set it in PopulateUIFields() with our
                        -- own "reasons why you cannot queue this row"
                        -- text (same red text that WritWorthy stuffs
                        -- into sealed writ tooltips).
    if cell_control.tooltip_text then
        ZO_Tooltips_ShowTextTooltip(
                  cell_control
                , TOP
                , cell_control.tooltip_text)
    end
end

function WritWorthyInventoryList_Cell_OnMouseExit(cell_control)
    -- d("exit "..tostring(cell_control))
    ZO_Tooltips_HideTextTooltip()
end

-- First time through a row's SetupRowControl(), create the individual label
-- controls that will hold cell text.
function WritWorthyInventoryList:CreateRowControlCells(row_control, header_control)
    for i, cell_name in ipairs(self.CELL_NAME_LIST) do
        local header_cell_control = header_control:GetNamedChild(cell_name)
        local control_name = row_control:GetName() .. cell_name
        local cell_control = nil
        local is_text      = true
        local rel_to_left  = header_control:GetLeft()
        if self.CELL_XML_LIST[cell_name] then
            cell_control = row_control:GetNamedChild(cell_name)
            is_text      = false
        else
            cell_control = row_control:CreateControl(control_name, CT_LABEL)
        end
        row_control[cell_name]   = cell_control

        if i == 1 then
                        -- Leftmost column is flush up against
                        -- the left of the container
            cell_control:SetAnchor( LEFT                -- point
                                  , row_control         -- relativeTo
                                  , LEFT                -- relativePoint
                                  , 0                   -- offsetX
                                  , 0 )                 -- offsetY
        else
            local offsetX = header_cell_control:GetLeft()
                          - rel_to_left
            cell_control:SetAnchor( LEFT                -- point
                                  , row_control         -- relativeTo
                                  , LEFT                -- relativePoint
                                  , offsetX             -- offsetX
                                  , 0 )                 -- offsetY
        end
        cell_control:SetHidden(false)
                        -- Don't waste CPU time checking for tooltips in EVERY
                        -- cell. Only a couple columns have tooltips. Set the
                        -- mouse enter/exit handlers on only those columns.
        -- cell_control:SetHandler("OnMouseEnter", WritWorthyInventoryList_Cell_OnMouseEnter)
        -- cell_control:SetHandler("OnMouseExit",  WritWorthyInventoryList_Cell_OnMouseExit)

        if not is_text then
                        -- Lock our checkmark/cancel icons to 20x20
            cell_control:SetWidth(20)
            cell_control:SetHeight(20)
        else
            cell_control:SetWidth(header_cell_control:GetWidth())
            cell_control:SetHeight(self.ROW_HEIGHT)

            cell_control:SetFont("ZoFontGame")
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
            local horiz_align = TEXT_ALIGN_LEFT
            if header_name_control then
                horiz_align = header_name_control:GetHorizontalAlignment()
            end
            cell_control:SetHorizontalAlignment(horiz_align)

                            -- Align all cells to top so that long/multiline text
                            -- still look acceptable.
                            -- ### TEXT_ALIGN_CENTER seems to have no effect
                            -- ### TEXT_ALIGN_BOTTOM does give a bit more margin
                            --     between headers and top row text
            cell_control:SetVerticalAlignment(TEXT_ALIGN_TOP)
        end
    end

    local cb = row_control:GetNamedChild(self.CELL_ENQUEUE)
    if cb then
        ZO_CheckButton_SetToggleFunction(cb, function(checkbox, is_checked)
            WritWorthyInventoryList_EnqueueToggled(checkbox, is_checked)
        end)
    end
    cb:SetHandler("OnMouseEnter", WritWorthyInventoryList_Cell_OnMouseEnter)
    cb:SetHandler("OnMouseExit",  WritWorthyInventoryList_Cell_OnMouseExit)

                            -- Not a cell control, but a mask that floats above
                            -- one. Hook that up for fast access and tooltips.
    local mask_control = row_control:GetNamedChild(self.CELL_ENQUEUE_MASK)
    row_control[self.CELL_ENQUEUE_MASK] = mask_control
    mask_control:SetHidden(false)
    mask_control:SetHandler("OnMouseEnter", WritWorthyInventoryList_Cell_OnMouseEnter)
    mask_control:SetHandler("OnMouseExit",  WritWorthyInventoryList_Cell_OnMouseExit)
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
    local rel_to_left = WritWorthyUIInventoryListHeaders:GetLeft()

                        -- Cache header cell controls from which we'll
                        -- gather column widths. We want the GetNamedChild()
                        -- controls (they have anchors and dynamic width)
                        -- not the ZO_SortHeader_Initialize() controls
                        -- (which appear to never change widths).
    local hcl = {}
    for cell_name, _ in pairs(WritWorthy.list_header_controls) do
        hcl[cell_name] = WritWorthyUIInventoryListHeaders:GetNamedChild(cell_name)
    end

    for cell_name, _ in pairs(WritWorthy.list_header_controls) do
        local cell_control = row_control:GetNamedChild(cell_name)
        local header_cell_control = hcl[cell_name]
        if header_cell_control then
            local offsetX = header_cell_control:GetLeft() - rel_to_left
            cell_control:SetAnchor( LEFT                -- point
                                  , row_control         -- relativeTo
                                  , LEFT                -- relativePoint
                                  , offsetX             -- offsetX
                                  , 0 )                 -- offsetY
                        -- Resize text cells, but leave button cells locked
                        -- to whatever CreateRowControlCells() chose.
            local is_text = not WritWorthyInventoryList.CELL_XML_LIST[cell_name]
            if is_text then
                cell_control:SetWidth(header_cell_control:GetWidth())
            end
        end
    end

                        -- I don't always have a background, but when I do,
                        -- I want it to stretch all the way across this row.
    local background_control = GetControl(row_control, "BG")
    if background_control then
        background_control:SetWidth(row_control:GetWidth())
    end
end

local SHORTEN = {
  ["Alchemy"                  ] = "Alchemy"
, ["Enchanting"               ] = "Enchant"
, ["Provisioning"             ] = "Provis"

, ["Rubedite Axe"             ] = "1h axe"
, ["Rubedite Mace"            ] = "1h mace"
, ["Rubedite Sword"           ] = "1h sword"
, ["Rubedite Greataxe"        ] = "2h battle axe"
, ["Rubedite Greatsword"      ] = "2h greatsword"
, ["Rubedite Maul"            ] = "2h maul"
, ["Rubedite Dagger"          ] = "dagger"
, ["Rubedite Cuirass"         ] = "cuirass"
, ["Rubedite Sabatons"        ] = "sabatons"
, ["Rubedite Gauntlets"       ] = "gauntlets"
, ["Rubedite Helm"            ] = "helm"
, ["Rubedite Greaves"         ] = "greaves"
, ["Rubedite Pauldron"        ] = "pauldron"
, ["Rubedite Girdle"          ] = "girdle"
, ["Ancestor Silk Robe"       ] = "robe"
, ["Ancestor Silk Jerkin"     ] = "shirt"
, ["Ancestor Silk Shoes"      ] = "shoes"
, ["Ancestor Silk Gloves"     ] = "gloves"
, ["Ancestor Silk Hat"        ] = "hat"
, ["Ancestor Silk Breeches"   ] = "breeches"
, ["Ancestor Silk Epaulets"   ] = "epaulets"
, ["Ancestor Silk Sash"       ] = "sash"
, ["Rubedo Leather Jack"      ] = "jack"
, ["Rubedo Leather Boots"     ] = "boots"
, ["Rubedo Leather Bracers"   ] = "bracers"
, ["Rubedo Leather Helmet"    ] = "helmet"
, ["Rubedo Leather Guards"    ] = "guards"
, ["Rubedo Leather Arm Cops"  ] = "arm cops"
, ["Rubedo Leather Belt"      ] = "belt"
, ["Ruby Ash Bow"             ] = "bow"
, ["Ruby Ash Inferno Staff"   ] = "flame"
, ["Ruby Ash Frost Staff"     ] = "frost"
, ["Ruby Ash Lightning Staff" ] = "lightning"
, ["Ruby Ash Healing Staff"   ] = "resto"
, ["Ruby Ash Shield"          ] = "shield"

, ["Whitestrake's Retribution"] = "Whitestrake's"
, ["Armor of the Seducer"     ] = "Seducer"
, ["Night Mother's Gaze"      ] = "Night Mother's"
, ["Alessia's Bulwark"        ] = "Alessia's"
, ["Law of Julianos"          ] = "Julianos"
, ["Pelinal's Aptitude"       ] = "Pelinal's"

, ["Epic"                     ] = "|c973dd8Epic|r"
, ["Legendary"                ] = "|ce6c859Legendary|r"
}

-- Abbreviate strings so that they fit in narrow columns.
-- Increase data display density.
--
-- Also applies purple/gold color to epic/legendary
--
function WritWorthyInventoryList.Shorten(text)
    if not text then return "" end
    local s = SHORTEN[text]
    if s then return s end
    return text
end


function WritWorthyInventoryList:IsQueued(inventory_data)
                        -- O(n) list scan instead of O(1) hash lookup.
                        -- Calling repeatedly from inside a loop is O(n^2).
                        -- Replace if noticeable (for large n, it will be).
    local LLC = WritWorthy:GetLLC()
    local x = LLC:findItemByReference(inventory_data.unique_id)
    if 0 < #x then
        return true
    else
        return false
    end
end

function WritWorthyInventoryList:IsCompleted(inventory_data)
    if not (    WritWorthy.savedChariables
            and WritWorthy.savedChariables.writ_unique_id) then
        return false
    end
    return WritWorthy.savedChariables.writ_unique_id[inventory_data]
             == WritWorthy.STATE_COMPLETED
end

function WritWorthyInventoryList:CanQueue(inventory_data)
    if not inventory_data.parser.can_dolgubon then
        return false, "Not supported: Alchemy, Enchanting, Provisioning."
    end
    if self.IsCompleted(inventory_data) then
        return false, "completed"
    end
    local text_list = {}
    for _, know in ipairs(inventory_data.parser:ToKnowList()) do
        if not know.is_known then
            table.insert(text_list, know:TooltipText())
        end
    end
    if 0 < #text_list then
        return false, table.concat(text_list, "\n")
    end
    return true, ""
end

                        -- Lazy-instantiate fields within our "data model"
                        -- that contain UI-centric user-visible text for
                        -- list display.
function WritWorthyInventoryList:PopulateUIFields(inventory_data)
    inventory_data.ui_voucher_ct   = WritWorthy.ToVoucherCount(inventory_data.item_link)
    inventory_data.ui_is_queued    = self:IsQueued(inventory_data)
    inventory_data.ui_is_completed = self:IsCompleted(inventory_data)
    local can, why_not             = self:CanQueue(inventory_data)
    inventory_data.ui_can_queue    = can
    if can then
        inventory_data.ui_can_queue_tooltip = nil
    else
        inventory_data.ui_can_queue_tooltip = why_not
    end

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
        inventory_data.ui_type =  "Alchemy"
        local mat_list = parser:ToMatList()
        inventory_data.ui_detail1 = mat_list[1].name
        inventory_data.ui_detail2 = mat_list[2].name
        inventory_data.ui_detail3 = mat_list[3].name
        inventory_data.ui_detail4 = mat_list[4].name
    elseif parser.class == WritWorthy.Enchanting.Parser.class then
        inventory_data.ui_type =  "Enchanting"
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
        inventory_data.ui_type    = "Provisioning"
        inventory_data.ui_detail1 = parser.recipe.fooddrink_name
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

-- Called by ZOS code after user clicks in any of our "Enqueue" checkboxes.
function WritWorthyInventoryList_EnqueueToggled(cell_control, checked)
    Log:StartNewEvent()
    Log:Add("WritWorthyInventoryList_EnqueueToggled() checked:"..tostring(checked)
            .." unique_id:"..tostring(cell_control.inventory_data.unique_id))
    self = WritWorthyInventoryList.singleton
    if checked then
        self:Enqueue(cell_control.inventory_data)
    else
        self:Dequeue(cell_control.inventory_data)
    end
    self:UpdateUISoon(cell_control.inventory_data)
end

-- Called by ZOS code after user clicks "Enqueue All"
function WritWorthyInventoryList_EnqueueAll()
    Log:StartNewEvent()
    self = WritWorthyInventoryList.singleton
    self:EnqueueAll()
    self:Refresh()
    self:UpdateSummaryAndQButtons()
end

-- Called by ZOS code after user clicks "Dequeue All"
function WritWorthyInventoryList_DequeueAll()
    Log:StartNewEvent()
    self = WritWorthyInventoryList.singleton
    self:DequeueAll()
    self:Refresh()
    self:UpdateSummaryAndQButtons()
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
                        -- Retain pointers to our row_control instances so that
                        -- we can update all their cell wides later upon window
                        -- resize.
        table.insert(self.row_control_list, row_control)
    end

    self:PopulateUIFields(inventory_data)

                        -- For less typing.
    local rc  = row_control
    local i_d = inventory_data

                        -- Apply text color to entire row.
    local fn = Util.color
    local c  = WritWorthyInventoryList.COLOR_TEXT_CAN_QUEUE
    if inventory_data.ui_is_completed then
        c = WritWorthyInventoryList.COLOR_TEXT_COMPLETED
    elseif not inventory_data.ui_can_queue then
        c = WritWorthyInventoryList.COLOR_TEXT_CANNOT_QUEUE
    elseif inventory_data.ui_is_queued then
        c = WritWorthyInventoryList.COLOR_TEXT_QUEUED
    end

                        -- Fill in the cells with data for this row.
    rc[self.CELL_TYPE     ]:SetText(fn(c, i_d.ui_type))
    rc[self.CELL_VOUCHERCT]:SetText(fn(c, tostring(i_d.ui_voucher_ct)))
    rc[self.CELL_DETAIL1  ]:SetText(fn(c, i_d.ui_detail1))
    rc[self.CELL_DETAIL2  ]:SetText(fn(c, i_d.ui_detail2))
    rc[self.CELL_DETAIL3  ]:SetText(fn(c, i_d.ui_detail3))
    rc[self.CELL_DETAIL4  ]:SetText(fn(c, i_d.ui_detail4))
    rc[self.CELL_DETAIL5  ]:SetText(fn(c, i_d.ui_detail5))

                        -- The "Enqueue" checkbox and its mask that makes it
                        -- look dimmed out when we cannot enqueue this row
                        -- due to lack of knowledge or WritWorthy code.
                        --
                        -- The mask does a lot for us:
                        -- 1. dims the checkbox
                        -- 2. intercepts mouse events
                        -- 3. provides tooltips
                        -- So there's no need to disable or hide the checkbox.
                        --
    local b      = rc[self.CELL_ENQUEUE     ]
    local b_mask = rc[self.CELL_ENQUEUE_MASK]
    b.inventory_data      = inventory_data
    b_mask.inventory_data = inventory_data
    if i_d.ui_can_queue then
        ZO_CheckButton_SetCheckState(b, i_d.ui_is_queued)
        b_mask:SetHidden(true)
    else
        ZO_CheckButton_SetCheckState(b, false)
        b_mask:SetHidden(false)
        b_mask.tooltip_text = i_d.ui_can_queue_tooltip
    end
end

-- Callback from LibLazyCrafter into our code upon completion of a single
-- queued request.
--  - event is "success" or "not enough mats" or some other string.
--          We COULD key off of "success" and display error redness if fail.
--  - llc_result is a table with bag/slot id of the crafted item and
--          its unique_id reference.
function WritWorthy_LLCCompleted(event, station, llc_result)
    Log:StartNewEvent()
    local unique_id = nil
    if llc_result then
        unique_id = llc_result.reference
    end
    Log:Add("LibLazyCrafting completed"
            .." unique_id:"..tostring(unique_id)
            .." event:"..tostring(event)
            .." station:"..tostring(station)
            .." llc_result:"..tostring(llc_result))

                        -- Remove the completed request from "queued" and
                        -- move it to "completed".
    if unique_id
        and WritWorthy.savedChariables
        and WritWorthy.savedChariables.writ_unique_id then
        WritWorthy.savedChariables.writ_unique_id[unique_id] = WritWorthy.STATE_COMPLETED
    end

    if WritWorthyInventoryList and WritWorthyInventoryList.singleton then
        self = WritWorthyInventoryList.singleton
        inventory_data = self:UniqueIDToInventoryData(unique_id)
        if inventory_data then
            self:UpdateUISoon(inventory_data)
        end
    end
end

-- O(n) scan for an inventory_data with a matching unique_id
function WritWorthyInventoryList:UniqueIDToInventoryData(unique_id)
    for _, inventory_data in self.inventory_data_list do
        if inventory_data.unique_id == unique_id then
            return inventory_data
        end
    end
    return nil
end

-- Queued state for one or more rows has changed. Propagate that change through
-- our .inventory_data_list and into the UI.
--
-- Eventually this may move to a zo_callLater() function that NOPs for 0.1 seconds
-- and then updates only after we've stopped calling it for 0.1 seconds.
--
function WritWorthyInventoryList:UpdateUISoon(inventory_data)
    Log:Add("WritWorthyInventoryList:UpdateUISoon  unique_id:"
            ..tostring(inventory_data.unique_id))
    self:PopulateUIFields(inventory_data)
    WritWorthy:LogLLCQueue(WritWorthy:GetLLC().personalQueue)
    self:UpdateSummaryAndQButtons()
    self:Refresh()
end


-- LibLazyCrafting API k:addonName                "WritWorthy"
-- LibLazyCrafting API k:autocraft                true
-- LibLazyCrafting API k:personalQueue            {}
-- LibLazyCrafting API k:ImproveSmithingItem()
-- LibLazyCrafting API k:CraftSmithingItem()
-- LibLazyCrafting API k:craftItem()
-- LibLazyCrafting API k:CraftEnchantingItemId()
-- LibLazyCrafting API k:CraftEnchantingGlyph()
-- LibLazyCrafting API k:GetCurrentSetInteractionIndex()
-- LibLazyCrafting API k:findItemByReference()
-- LibLazyCrafting API k:cancelItemByReference()
-- LibLazyCrafting API k:findItemLocationById()
-- LibLazyCrafting API k:CraftAllItems()
-- LibLazyCrafting API k:cancelItem()
-- LibLazyCrafting API k:CraftSmithingItemByLevel()

function WritWorthy:GetLLC()
    if self.LibLazyCrafting then
        return self.LibLazyCrafting
    end

    d("WritWorthy: Initializing LibLazyCrafting... self:"..tostring(self)
                .."  bob_ct:"..tostring(BOB_CT))
    local lib = LibStub:GetLibrary("LibLazyCrafting", 0.3)
    self.LibLazyCrafting = lib:AddRequestingAddon(
         self.name                  -- name
       , true                       -- autocraft
       , WritWorthy_LLCCompleted    -- functionCallback
       )

    if not self.LibLazyCrafting then
        d("Unable to load LibLazyCrafting 0.3")
    end
                        -- Record API names to log so that I have them handy
                        -- rather than  spending any time asking "is Xxx()
                        -- available?"
    Log:StartNewEvent()
    Log:Add("LibLazyCrafting LLC:"..tostring(self.LibLazyCrafting))
    for k,v in pairs(self.LibLazyCrafting) do
        Log:Add("LibLazyCrafting API k:"..tostring(k).."  v:"..tostring(v))
    end
                        -- Also record queue contents. I suspect this is
                        -- always initially empty.
    if self.LibLazyCrafting.personalQueue then
        self:LogLLCQueue(self.LibLazyCrafting.personalQueue)
    end

    return self.LibLazyCrafting
end

-- Add the given item to LibLazyCrafting's queue of stuff
-- to be automatically crafted later.
function WritWorthyInventoryList:Enqueue(inventory_data)
                        -- Use the ZOS-assigned GetItemUniqueId() for
                        -- this sealed writ.
                        -- We previously relied on an internal counter from
                        -- Dolgubon's Lazy Set Crafter, but we're decoupling
                        -- from Lazy Set Crafter and no longer wish to us that
                        -- counter.
    local unique_id = inventory_data.parser.unique_id

    Log:Add("Enqueue "..tostring(unique_id))

                        -- Avoid enqueing the same writ twice: If we already
                        -- enqueued this specific writ, do nothing.
    if self:IsQueued(inventory_data) then
        d("BUG: Already enqueued. UI incorrectly showed item as not enqueued."
            .." Sealed writ unique_id:"..tostring(unique_id))
        return
    end
    WritWorthy:Enqueue(unique_id, inventory_data)

                        -- Remember this in savedChariables so that
                        -- we can restore checkbox state after /reloadui.
    if not WritWorthy.savedChariables.writ_unique_id then
        WritWorthy.savedChariables.writ_unique_id = {}
    end
    WritWorthy.savedChariables.writ_unique_id[unique_id] = WritWorthy.STATE_QUEUED
end

-- The Dolgubon-only portion of enqueing a request, no list UI work here.
-- Called from WritWorthy itself during RestoreFromSavedChariables()
function WritWorthy:Enqueue(unique_id, inventory_data)
                        -- ### This section is all Smithing-specific.
                        -- ### Will need rewrite once we support consumables.
    local dol_req = inventory_data.parser:ToDolRequest()
                        -- I _hate_ long lists of positional arguments.
                        -- Far too dangerous and prone to mixing up the
                        -- arguments. Better to use a named parameter block.
                        -- I'll likely do so for a mroe generic API when
                        -- I add consumable support to LLC later.
    local o       = dol_req.CraftRequestTable
    local LLC     = WritWorthy:GetLLC()
    LLC:CraftSmithingItemByLevel(
          o[ 1]     -- patternIndex
        , o[ 2]     -- isCP
        , o[ 3]     -- level
        , o[ 4]     -- styleIndex
        , o[ 5]     -- traitIndex
        , o[ 6]     -- useUniversalStyleItem
        , o[ 7]     -- station
        , o[ 8]     -- setIndex
        , o[ 9]     -- quality
        , o[10]     -- autocraft
        , unique_id -- reference (o[11] is Lazy Set Crafter counter, trying not to use that anymore)
        )
end

function WritWorthyInventoryList:Dequeue(inventory_data)
    local unique_id = inventory_data.parser.unique_id
    Log:Add("Dequeue "..tostring(unique_id))
    local LLC = WritWorthy:GetLLC()
    LLC:cancelItemByReference(unique_id)

                        -- Remove from savedChariables so that we do not
                        -- re-check this row upon /reloadui.
    if WritWorthy.savedChariables.writ_unique_id then
        WritWorthy.savedChariables.writ_unique_id[unique_id] = nil
    end
end

-- Reload the LibLazyCrafting queue from savedChariables
function WritWorthy:RestoreFromSavedChariables()
                        -- Do nothing if nothing to restore.
    if    (not self.savedChariables)
       or (not self.savedChariables.writ_unique_id) then
        return
    end

    local inventory_data_list = WritWorthy:ScanInventoryForMasterWrits()
    for _, inventory_data in pairs(inventory_data_list) do
        local unique_id = inventory_data.unique_id
        local state = self.savedChariables.writ_unique_id[unique_id]
        if state and state == WritWorthy.STATE_QUEUED then
            self:Enqueue(unique_id, inventory_data)
        end
    end
end

-- Dump LibLazyCrafting's entire queue to log file.
-- This can be HUGE if you have dozens of sealed writs in inventory, so
-- comment this out before shipping.
function WritWorthy:LogLLCQueue(queue)
    if not queue then return end

    for kk,vv in pairs(queue) do
        local vstr = tostring(vv)
        if type(vv) == "table" then
            vstr = vstr.."  ct:"..tostring(#vv)
        end
        Log:Add("LibLazyCrafting queue k:"..tostring(kk)
                .."  v:"..vstr)
        if type(vv) == "table" then
            for k,v in pairs(vv) do
                Log:Add("LibLazyCrafting queue k:"..tostring(kk)
                        ..","..tostring(k)
                        .."    v:"..tostring(v))
                if type(v) == "table" then
                    for k3, v3 in pairs(v) do
                        Log:Add("LibLazyCrafting queue k:"..tostring(kk)
                                ..","..tostring(k)
                                ..","..tostring(k3)
                                .."    v:"..tostring(v3))
                    end
                end
            end
        end
    end
end

-- O(n) scan to collect a hash of unique item ids of items actually
-- in LibLazyCrafter's queue.
function WritWorthyInventoryList:QueuedReferenceList()
    local queued_ids = {}
    for station, queued in ipairs(WritWorthy:GetLLC().personalQueue) do
        if type(queued) == "table" then
            for i, request in ipairs(queued) do
                if request.reference then
                    queued_ids[request.reference] = true
                end
            end
        end
    end
    return queued_ids
end

-- Fill our summary with actual data from our enqueued items.
-- Enable/disable "Enqueue All"/"Dequeue All" buttons depending on
-- whether we've any more to enqueue or dequeue.
function WritWorthyInventoryList:UpdateSummaryAndQButtons()
                        -- Collect hashtable of all queued unique_ids
                        -- so that we can use it later in an O(n) loop
                        -- for O(1) lookups.
    local queued_ids = self.QueuedReferenceList()

                        -- Accumulators
    local can_enqueue_any  = false
    local can_dequeue_any  = false
    local total_voucher_ct = 0
    local total_mat_gold   = 0

                        -- Scan our master request list, accumulate voucher
                        -- and mat totals for each request in LLC's queue.
                        -- While scanning, also notice if any of these can
                        -- be enqueued.
    for _, inventory_data in ipairs(self.inventory_data_list) do
        if inventory_data.parser.unique_id then
            if queued_ids[inventory_data.parser.unique_id] then
                local voucher_ct = WritWorthy.ToVoucherCount(inventory_data.item_link)
                total_voucher_ct = total_voucher_ct + voucher_ct
                local mat_list = inventory_data.parser:ToMatList()
                local mat_gold = WritWorthy.MatRow.ListTotal(mat_list)
                total_mat_gold = total_mat_gold + mat_gold
                can_dequeue_any = true
            elseif inventory_data.ui_can_queue
                   and not inventory_data.ui_is_queued then
                can_enqueue_any = true
            end
        end
    end

    local mat_per_v      = 0
    if total_voucher_ct then
        mat_per_v = total_mat_gold / total_voucher_ct
    end

    local voucher_string = Util.ToMoney(total_voucher_ct).."v"
    local mat_string     = Util.ToMoney(total_mat_gold).."g"
    local mat_per_string = Util.ToMoney(mat_per_v).."g/v"
    WritWorthyUISummaryVoucherCt:SetText(voucher_string)
    WritWorthyUISummaryMatCost:SetText(mat_string)
    WritWorthyUISummaryVoucherCost:SetText(mat_per_string)

    WritWorthyUIEnqueueAll:SetEnabled(can_enqueue_any)
    WritWorthyUIDequeueAll:SetEnabled(can_dequeue_any)
end

function WritWorthyInventoryList:EnqueueAll()
    for _, inventory_data in ipairs(self.inventory_data_list) do
        if inventory_data.ui_can_queue and not inventory_data.ui_is_queued then
            self:Enqueue(inventory_data)
        end
    end
end

function WritWorthyInventoryList:DequeueAll()
    for _, inventory_data in ipairs(self.inventory_data_list) do
        if inventory_data.ui_is_queued then
            self:Dequeue(inventory_data)
        end
    end
end

