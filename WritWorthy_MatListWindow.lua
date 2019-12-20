-- Window to display list of required materials.

local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Define.lua
WritWorthy.MatUI = ZO_SortFilterList:Subclass()
-- Inherits field "self.list" which is the scroll list control.
-- "WritWorthy.MatUI" is NOT the actual list control that has useful
-- "data members. Use WritWorthy.MatUI.singleton for that.

local Util = WritWorthy.Util
local Fail = WritWorthy.Util.Fail
local Log  = WritWorthy.Log

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
WritWorthy.MatUI.CELL_TYPE           = "Name"
WritWorthy.MatUI.CELL_REQUIRED_CT    = "RequiredCt"
WritWorthy.MatUI.CELL_HAVE_CT        = "HaveCt"
WritWorthy.MatUI.CELL_BUY_CT         = "BuyCt"
WritWorthy.MatUI.CELL_PRICE_EA       = "PriceEa"
WritWorthy.MatUI.CELL_BUY_SUBTOTAL   = "BuySubtotal"
WritWorthy.MatUI.CELL_NAME_LIST = {
  WritWorthy.MatUI.CELL_TYPE
, WritWorthy.MatUI.CELL_REQUIRED_CT
, WritWorthy.MatUI.CELL_HAVE_CT
, WritWorthy.MatUI.CELL_BUY_CT
, WritWorthy.MatUI.CELL_PRICE_EA
, WritWorthy.MatUI.CELL_BUY_SUBTOTAL
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
    -- ###
end

function WritWorthy.MatUI:UpdateAllCellWidths()
    Log.Debug("WWML:UpdateAllCellWidths")
    -- ###
end
