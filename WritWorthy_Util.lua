
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

-- Number/String conversion --------------------------------------------------

-- Return commafied integer number "123,456", or "?" if nil.
function Util.ToMoney(x)
    if not x then return "?" end
    return ZO_CurrencyControl_FormatCurrency(Util.round(x), false)
end

function Util.MatPrice(link)
                        -- LibPrice required for price lookups
    if LibPrice then
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
    if WritWorthy.savedVariables.enable_mm_fallback then
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
