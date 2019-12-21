-- Window to display list of required materials.

local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Define.lua
WritWorthy.MatUI = ZO_SortFilterList:Subclass()
-- Inherits field "self.list" which is the scroll list control.
-- "WritWorthy.MatUI" is NOT the actual list control that has useful
-- "data members. Use WritWorthy.MatUI.singleton for that.

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
                        -- specific column. Recurses down the line.
                        -- Avoid cycles! Break at ui_buy_total_cost.
WritWorthy.MatUI.SORT_KEYS = {
  ["ui_name"        ] = { tiebreaker="ui_required_ct"                  }
, ["ui_required_ct" ] = { tiebreaker="ui_have_ct"     , isNumeric=true }
, ["ui_have_ct"     ] = { tiebreaker="ui_buy_ct"      , isNumeric=true }
, ["ui_buy_ct"      ] = { tiebreaker="ui_price_ea"    , isNumeric=true }
, ["ui_price_ea"    ] = {                               isNumeric=true }
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

-- MatUI: The window around the material list --------------------------------
function WritWorthy.MatUI:New()
    Log.Debug("WWML:New()")
    local xml_control = WritWorthyMatUIList
    local o = ZO_SortFilterList.New(self, xml_control)
    WritWorthy.MatUI.singleton = o
    return o
end

function WritWorthy.MatUI.RestorePos()
    Log.Debug("WWMUI_RestorePos()")
    Util.RestorePos(WritWorthyMatUI, WINDOW_POS_KEY)
end

function WritWorthy.MatUI.OnMoveStop()
    Log.Debug("WWMUI_OnMoveStop()")
    Util.OnMoveStop(WritWorthyMatUI, WINDOW_POS_KEY)
end

function WritWorthy.MatUI.OnResizeStop()
    Log.Debug("WWMUI_OnResizeStop()")
    Util.OnResizeStop( WritWorthyMatUI
                     , WritWorthy.MatUI
                     , WritWorthy.MatUI.singleton
                     , WINDOW_POS_KEY )
end

function WritWorthy.MatUI.ToggleUI()
    Log.Debug("WWMUI_ToggleUI()")
    if not WritWorthyMatUI then
        Log.Error("WritWorthyMatUI missing")
        return
    end
    local h = WritWorthyMatUI:IsHidden()
    if h then
        WritWorthy.MatUI.RestorePos()
        WritWorthy.MatUI.RefreshUI()
        WritWorthy.MatUI:UpdateAllCellWidths()
    end
    WritWorthyMatUI:SetHidden(not h)
end


function WritWorthy.MatUI.RefreshUI()
    Log.Debug("WWMUI_RefreshUI()")
    -- ###
end

function WritWorthy.MatUI.HeaderInit(control, name, text, key)
    Log.Debug( "WWMUI_HeaderInit() c:%s n:%s t:%s k:%s"
             , tostring(control), name, text, key )
    local l10n_text = WW.Str("header_"..text) or text
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
                        -- WritWorthyUIInventoryListHeaders:GetNamedChild().
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

function WritWorthy.MatUI:UpdateAllCellWidths()
    Log.Debug("WWML:UpdateAllCellWidths")
    -- ###
end
