-- Window to display list of required materials.

local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Define.lua
WritWorthy.MatUI = ZO_SortFilterList:Subclass()
-- Inherits field "self.list" which is the scroll list control.
-- "WritWorthy.MatUI" is NOT the actual list control that has useful
-- "data members. Use WritWorthy.MatUI.singleton for that.

local Util = WritWorthy.Util
local Fail = WritWorthy.Util.Fail
local Log  = WritWorthy.Log

WINDOW_POS_KEY = "mat_list_position"

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
