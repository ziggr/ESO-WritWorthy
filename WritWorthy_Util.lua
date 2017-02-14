WritWorthy = {}

WritWorthy.Util = {}
local Util = WritWorthy.Util

function Util.Fail(msg)
    d(msg)
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
    ,   item_id          = tonumber(x[ 3])
    ,   sub_type         = tonumber(x[ 4])
    ,   internal_level   = tonumber(x[ 5])
    ,   enchant_id       = tonumber(x[ 6])
    ,   enchant_sub_type = tonumber(x[ 7])
    ,   enchant_level    = tonumber(x[ 8])
    ,   writ1            = tonumber(x[ 9])
    ,   writ2            = tonumber(x[10])
    ,   writ3            = tonumber(x[11])
    ,   writ4            = tonumber(x[12])
    ,   writ5            = tonumber(x[13])
    ,   writ6            = tonumber(x[14])
    ,   item_style       = tonumber(x[18])
    ,   is_crafted       = tonumber(x[19])
    ,   is_bound         = tonumber(x[20])
    ,   is_stolen        = tonumber(x[21])
    ,   charge_ct        = tonumber(x[22])
    ,   writ_reward      = tonumber(x[23])
    }
    return o
end

-- Chat Colors ---------------------------------------------------------------

WritWorthy.GREY = "999999"

function Util.color(color, text)
    return "|c" .. color .. text .. "|r"
end

function Util.grey(text)
    return Util.color(WritWorthy.GREY, text)
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

-- Master Merchant integration
function Util.MMPrice(link)
    if not MasterMerchant then return nil end
    if not link then return nil end
    local mm = MasterMerchant:itemStats(link, false)
    if not mm then return nil end
    if mm.avgPrice and 0 < mm.avgPrice then
        return mm.avgPrice
    end

                        -- Normal price lookup came up empty, try an
                        -- expanded time range.
                        --
                        -- MasterMerchant lacks an API to control time range,
                        -- it does this internally by polling the state of
                        -- control/shift-key modifiers (!) so we monkey-patch
                        -- MM with our own code that ignores modifier keys
                        -- and always returns a LOOONG time range
    local save_tc = MasterMerchant.TimeCheck
    MasterMerchant.TimeCheck
        = function(self)
            local daysRange = 100  -- 3+ months is long enough.
            return GetTimeStamp() - (86400 * daysRange), daysRange
          end
    mm = MasterMerchant:itemStats(link, false)
    MasterMerchant.TimeCheck = save_tc

    if not mm then return nil end
    return mm.avgPrice
end
