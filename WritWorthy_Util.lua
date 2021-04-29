
local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Define.lua

WritWorthy.Util = {}
local Util = WritWorthy.Util

WritWorthy.GOLD_UNKNOWN = nil

function Util.Fail(msg)
    d(msg)
    WritWorthy.Log:Add(msg)
    WritWorthy.Log:EndEvent()
end

-- Break an item_link string into its numeric pieces
--
-- The writ1..writ6 fields are what we really want.
-- Their meanings change depending on the master writ type.
--
function Util.ToWritFields(item_link)
    local x = { ZO_LinkHandler_ParseLink(item_link) }
    local o = {
        text             =          x[ 1]
    ,   link_style       = tonumber(x[ 2])
    ,   unknown3         = tonumber(x[ 3])
    ,   item_id          = tonumber(x[ 4])
    ,   sub_type         = tonumber(x[ 5])
    ,   internal_level   = tonumber(x[ 6])
    ,   enchant_id       = tonumber(x[ 7])
    ,   enchant_sub_type = tonumber(x[ 8])
    ,   enchant_level    = tonumber(x[ 9])
    ,   writ1            = tonumber(x[10])
    ,   writ2            = tonumber(x[11])
    ,   writ3            = tonumber(x[12])
    ,   writ4            = tonumber(x[13])
    ,   writ5            = tonumber(x[14])
    ,   writ6            = tonumber(x[15])
    ,   item_style       = tonumber(x[16])
    ,   is_crafted       = tonumber(x[17])
    ,   is_bound         = tonumber(x[18])
    ,   is_stolen        = tonumber(x[19])
    ,   charge_ct        = tonumber(x[20])
    ,   unknown21        = tonumber(x[21])
    ,   unknown22        = tonumber(x[22])
    ,   unknown23        = tonumber(x[23])
    ,   writ_reward      = tonumber(x[24])
    }

    -- d("text             = [ 1] = " .. tostring(o.text            ))
    -- d("link_style       = [ 2] = " .. tostring(o.link_style      ))
    -- d("item_id          = [ 4] = " .. tostring(o.item_id         ))
    -- d("sub_type         = [ 5] = " .. tostring(o.sub_type        ))
    -- d("internal_level   = [ 6] = " .. tostring(o.internal_level  ))
    -- d("enchant_id       = [ 7] = " .. tostring(o.enchant_id      ))
    -- d("enchant_sub_type = [ 8] = " .. tostring(o.enchant_sub_type))
    -- d("enchant_level    = [ 9] = " .. tostring(o.enchant_level   ))
    -- d("writ1            = [10] = " .. tostring(o.writ1           ))
    -- d("writ2            = [11] = " .. tostring(o.writ2           ))
    -- d("writ3            = [12] = " .. tostring(o.writ3           ))
    -- d("writ4            = [13] = " .. tostring(o.writ4           ))
    -- d("writ5            = [14] = " .. tostring(o.writ5           ))
    -- d("writ6            = [15] = " .. tostring(o.writ6           ))
    -- d("writ_reward      = [24] = " .. tostring(o.writ_reward     ))

    return o
end

-- Chat Colors ---------------------------------------------------------------

WritWorthy.Util.COLOR_WHITE  = "FFFFFF"
WritWorthy.Util.COLOR_RED    = "FF3333"
WritWorthy.Util.COLOR_GREEN  = "33AA33"
WritWorthy.Util.COLOR_GREY   = "999999"
WritWorthy.Util.COLOR_ORANGE = "FF8800"

function Util.color(color, text)
    return "|c" .. color .. text .. "|r"
end

function Util.grey(text)
    local GREY = "999999"
    return Util.color(GREY, text)
end

function Util.red(text)
    local RED  = "FF3333"
    return Util.color(RED, text)
end

function Util.round(f)
    if not f then return f end
    return math.floor(0.5+f)
end

-- clean up suffixes such as ^F or ^S
-- Code copied from Advanced Filters
function Util.decaret(s)
    return zo_strformat(SI_TOOLTIP_ITEM_NAME, s) or " "
end

-- Number/String conversion --------------------------------------------------

-- Return commafied integer number "123,456", or "?" if nil.
function Util.ToMoney(x)
    if (not x) or x == -1 then return "?" end
    return ZO_CurrencyControl_FormatCurrency(Util.round(x), false)
end

function Util.MatPrice(link)
    local sv = WritWorthy.savedVariables

                        -- LibPrice required for price lookups
    if LibPrice and (sv.enable_lib_price or (sv.enable_lib_price == nil)) then
                        -- Explicitly list the guild store sources, omit all
                        -- others. We don't want "NPC Vencor" price of
                        -- 13g-per-Zircon-Plating creeping into our price
                        -- calculations.
        local gold,s,f = LibPrice.ItemLinkToPriceGold(link, "mm", "att", "ttc")
        -- if gold then
        --     d(string.format( "|c999999%s.%s |cFFFFFF%d|c999999 for %s"
        --                    , s, f, gold,link ))
        -- end
        if gold then return gold end
    end

                        -- If fallback enabled, use that
    if sv.enable_mm_fallback then
        local fb = WritWorthy.FallbackPrice(link)
        if fb then
            return fb
        end
    end
                        -- No price for you!
    return WritWorthy.GOLD_UNKNOWN
end

                        -- Prevent access to LibSets until
                        -- it is done scanning sets.
                        --
                        -- SURPRISE this isn't a "util" function, but I need
                        -- it defined early in the load order, so might as
                        -- well put it here in util.lua.
function WritWorthy.LibSets()
    if not WritWorthy.lib_sets then
        if LibSets and (not LibSets.IsSetsScanning())
            and LibSets.AreSetsLoaded() then
                WritWorthy.lib_sets = LibSets
        end
    end
    return WritWorthy.lib_sets
end

-- Window position -----------------------------------------------------------

function WritWorthy.Util.RestorePos(top_level_control, saved_var_key_name)
    local pos = WritWorthy.default[saved_var_key_name]
    if      WritWorthy
        and WritWorthy.savedVariables
        and WritWorthy.savedVariables[saved_var_key_name] then
        pos = WritWorthy.savedVariables[saved_var_key_name]
    end
    if not pos then
        WritWorthy.Log.Debug( "RestorePos: no saved pos for key:'%s'"
                 , saved_var_key_name )
        return
    end

    if not top_level_control then
                        -- Common crash that occurs when I've messed up
                        -- the XML somehow. Force it to crash here in this
                        -- if block rather than mysteriously on the
                        -- proper SetAnchor() line later.
        d("Your XML probably did not load. Fix it.")
        local _ = top_level_control.SetAnchor
    end
    top_level_control:ClearAnchors()
    top_level_control:SetAnchor(
              TOPLEFT
            , GuiRoot
            , TOPLEFT
            , pos[1]
            , pos[2]
            )

    if pos[3] and pos[4] then
        top_level_control:SetWidth( pos[3] - pos[1])
        top_level_control:SetHeight(pos[4] - pos[2])
    end
end


function WritWorthy.Util.SavePos(top_level_control, saved_var_key_name)
    local l = top_level_control:GetLeft()
    local t = top_level_control:GetTop()
    local r = top_level_control:GetRight()
    local b = top_level_control:GetBottom()
    -- d("SavePos ltrb=".. l .. " " .. t .. " " .. r .. " " .. b)
    local pos = { l, t, r, b }
    WritWorthy.savedVariables[saved_var_key_name] = pos
end

function WritWorthy.Util.OnMoveStop(top_level_control, saved_var_key_name)
    WritWorthy.Util.SavePos(top_level_control, saved_var_key_name)
end

function WritWorthy.Util.OnResizeStop( top_level_control
                                     , list
                                     , singleton
                                     , saved_var_key_name )
    list:UpdateAllCellWidths()
    WritWorthy.Util.SavePos(top_level_control, saved_var_key_name)

                        -- Update vertical scrollbar and extents to
                        -- match new scrollpane height.
    if      singleton
        and singleton.list then
        local scroll_list = singleton.list
        ZO_ScrollList_Commit(scroll_list)
    end
end

-- Delayed refresh -----------------------------------------------------------
--
-- Don't hammer the CPU refreshing UI over and over while the user types
-- into a filter field. Delays call to refres (or `func` here) until after
-- 400ms or so have passed between keystrokes (or calls to `CallSoon()` here).
function WritWorthy.Util.CallSoon(key, func)
    WritWorthy.Log.Debug("CallSoon     k:%s %d", key, WritWorthy[key] or -1)
    if not WritWorthy[key] then
        zo_callLater( function()
                        WritWorthy.Util.CallSoonPoll(key, func)
                      end
                    , 250 )
    end
    WritWorthy[key] = GetFrameTimeMilliseconds() + 400
end

function WritWorthy.Util.CallSoonPoll(key, func)
    WritWorthy.Log.Debug("CallSoonPoll k:%s %d", key, WritWorthy[key] or -1)
    if not WritWorthy[key] then return end
    local now = GetFrameTimeMilliseconds() or 0
    if now <= WritWorthy[key] then
        WritWorthy.Log.Debug("CallSoonPoll k:%s fire", key)
        WritWorthy[key] = nil
        func()
    else
        zo_callLater( function()
                        WritWorthy.Util.CallSoonPoll(key, func)
                      end
                    , 250 )
    end
end

function Util.MatHaveCt(item_link)
    local bag_ct, bank_ct, craft_bag_ct = GetItemLinkStacks(item_link)
    return bag_ct + bank_ct + craft_bag_ct
end

-- ZO_ScrollList -------------------------------------------------------------

function Util.SetCellToHeaderAlign(
          cell_control
        , header_control
        , fallback_header_control )
    local header_name_control = header_control:GetNamedChild("Name")

                        -- Surprise! Headers:GetNamedChild() returns a control
                        -- instance that lacks a "Name" sub-control, or whose
                        -- "Name" subcontrol is not a label with
                        -- GetHorizontalAlignment(). We need that horizontal
                        -- alignment. Fall back to the control we passed to
                        -- ZO_SortHeader_Initialize().
    if not ( header_name_control
             and header_name_control.GetHorizontalAlignment ) then
        -- WritWorthy.Log.Debug("no horiz %d %-20s falling back", i, cell_name)
        header_name_control = nil
    end
    if (not header_name_control) and fallback_header_control then
        -- WritWorthy.Log.Debug("no hnc, fallback to list_header_controls['%s']", cell_name)
        header_name_control = fallback_header_control:GetNamedChild("Name")
    end

    local horiz_align = TEXT_ALIGN_LEFT
    if header_name_control then
        horiz_align = header_name_control:GetHorizontalAlignment()
    end
    cell_control:SetHorizontalAlignment(horiz_align)

                    -- Align all cells to top so that long/multiline
                    -- text still look acceptable. But hopefully we'll
                    -- never need this because TEXT_WRAP_MODE_ELLIPSIS
                    -- above should prevent multiline text.
    cell_control:SetVerticalAlignment(TEXT_ALIGN_TOP)
end

function Util.StretchBGWidth(row_control)
                        -- I don't always have a background, but when I do,
                        -- I want it to stretch all the way across this row.
    local background_control = GetControl(row_control, "BG")
    if background_control then
        background_control:SetWidth(row_control:GetWidth())
    end
end

function Util.SetAnchorCellLeft(
          row_control
        , cell_control
        , header_cell_control
        , is_leftmost_cell
        , y_offset
        , rel_to_left )
    if not y_offset then
        y_offset = 0
    end

    if is_leftmost_cell then
                    -- Leftmost column is flush up against
                    -- the left of the container
        cell_control:SetAnchor( LEFT                -- point
                              , row_control         -- relativeTo
                              , LEFT                -- relativePoint
                              , 0                   -- offsetX
                              , y_offset )          -- offsetY
    else
        local offsetX = header_cell_control:GetLeft()
                      - rel_to_left
        cell_control:SetAnchor( LEFT                -- point
                              , row_control         -- relativeTo
                              , LEFT                -- relativePoint
                              , offsetX             -- offsetX
                              , y_offset )          -- offsetY
    end
end

