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

local Log  = WritWorthy.Log

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
  ["ui_type"      ] = {tiebreaker="ui_voicher_ct"}
, ["ui_voucher_ct"] = {tiebreaker="ui_detail1", isNumeric=true }
, ["ui_detail1"   ] = {tiebreaker="ui_detail2"}
, ["ui_detail2"   ] = {tiebreaker="ui_detail3"}
, ["ui_detail3"   ] = {tiebreaker="ui_detail4"}
, ["ui_detail4"   ] = {tiebreaker="ui_detail5"}
, ["ui_detail5"   ] = {}
}

WritWorthyInventoryList.ROW_HEIGHT = 30

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
    local ui = WritWorthyUI
    if not ui then
        d("No UI")
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
    end
    WritWorthyUI:SetHidden(not h)

end

function WritWorthy_HeaderInit(control, text, key)
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
    WritWorthy.list_header_controls[text] = control
end



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
                        -- ### TEXT_ALIGN_CENTER seems to have no effect
                        -- ### TEXT_ALIGN_BOTTOM does give a bit more margin
                        --     between headers and top row text
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
        inventory_data.ui_type =  "Provisioning"
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

