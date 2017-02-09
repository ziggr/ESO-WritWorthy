local LAM2 = LibStub("LibAddonMenu-2.0")

local WritWorthy = {}

WritWorthy.name            = "WritWorthy"
WritWorthy.version         = "2.7.1"

-- Chat Colors ---------------------------------------------------------------

WritWorthy.GREY = "999999"

function WritWorthy.color(color, text)
    return "|c" .. color .. text .. "|r"
end

function WritWorthy.grey(text)
    return WritWorthy.color(WritWorthy.GREY, text)
end

function WritWorthy.round(f)
    if not f then return f end
    return math.floor(0.5+f)
end

-- Number/String conversion --------------------------------------------------

-- Return commafied integer number, or "?" if nil.
function WritWorthy.ToMoney(x)
    if not x then return "?" end
    return ZO_CurrencyControl_FormatCurrency(WritWorthy.round(x), false)
end


-- WritWorthy ====================================================================

function WritWorthy.MMPrice(link)
    if not MasterMerchant then return nil end
    if not link then return nil end
    mm = MasterMerchant:itemStats(link, false)
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
            d("Monkey patch called")
            local daysRange = 100  -- 3+ months is long enough.
            return GetTimeStamp() - (86400 * daysRange), daysRange
          end
    mm = MasterMerchant:itemStats(link, false)
    MasterMerchant.TimeCheck = save_tc

    if not mm then return nil end
    return mm.avgPrice
end

-- Tooltip Intercept ---------------------------------------------------------

-- Monkey-patch ZOS' ItemTooltip with our own after-overrides. Lets ZOS code
-- create and show the original tooltip, and then we come in and insert our
-- own stuff.
--
-- Based on CraftStore's CS.TooltipHandler().
--
function WritWorthy.TooltipInterceptInstall()
    local tt=ItemTooltip.SetBagItem
    ItemTooltip.SetBagItem=function(control,bagId,slotIndex,...)
        tt(control,bagId,slotIndex,...)
        WritWorthy.TooltipInsertOurText(control,GetItemLink(bagId,slotIndex))
    end
    local tt=ItemTooltip.SetLootItem
    ItemTooltip.SetLootItem=function(control,lootId,...)
        tt(control,lootId,...)
        WritWorthy.TooltipInsertOurText(control,GetLootItemLink(lootId))
    end
    local tt=PopupTooltip.SetLink
    PopupTooltip.SetLink=function(control,link,...)
        tt(control,link,...)
        WritWorthy.TooltipInsertOurText(control,link)
    end
end

function WritWorthy.TooltipInsertOurText(control, link)
    local insert_text = "Zig was here."
    control:AddLine(insert_text)
end

-- Init ----------------------------------------------------------------------

function WritWorthy.OnAddOnLoaded(event, addonName)
    if addonName ~= WritWorthy.name then return end
    if not WritWorthy.version then return end
    WritWorthy:Initialize()
end

function WritWorthy:Initialize()
    WritWorthy.TooltipInterceptInstall()
    --EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)
end


-- Postamble -----------------------------------------------------------------

EVENT_MANAGER:RegisterForEvent( WritWorthy.name
                              , EVENT_ADD_ON_LOADED
                              , WritWorthy.OnAddOnLoaded
                              )

