-- Window to display list of required materials.

local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Define.lua

local Util = WritWorthy.Util
local Fail = WritWorthy.Util.Fail
local Log  = WritWorthy.Log

function WritWorthy.MLToggle()
    Log.Debug("MLToggle")

    local ui = WritWorthyMatListUI
    if not ui then
        return
    end
    local h = WritWorthyMatListUI:IsHidden()
    WritWorthyMatListUI:SetHidden(not h)
end
