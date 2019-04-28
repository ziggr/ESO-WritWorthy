-- AwesomeGuildStore integration
--
local WritWorthy = WritWorthy or {}
local Log  = WritWorthy.Log
local Util = WritWorthy.Util

                        -- NOT the filter Type ID that appears in
                        -- filterTypeIds.txt. Must avoid collision with any
                        -- SUBFILTER_XXX values in CategoryPresets.lua,
                        -- which currently range from 1..33. Using a high
                        -- value here to avoid collision and might as well
                        -- match our filter type ID for no real reason.
local SUBFILTER_WRITWORTHY = 103

                        -- see WRIT_WORTHY_WRIT_COST_FILTER in ags data/FilterIds.lua
local FILTER_TYPE_ID_WRITWORTHY = 103

function WritWorthy.InitAGSIntegration(trading_house_wrapper)
    local AGS = AwesomeGuildStore   -- for less typing

    if WritWorthy.ags_init_started then return end
    WritWorthy.ags_init_started = true
    if not (    AGS
            and AGS.GetAPIVersion
            and AGS.GetAPIVersion() == 4) then
        return
    end

    local FilterBase            = AGS.class.FilterBase
    local ValueRangeFilterBase  = AGS.class.ValueRangeFilterBase
    local FILTER_ID             = AGS.data.FILTER_ID
    local SUB_CATEGORY_ID       = AGS.data.SUB_CATEGORY_ID
    local MIN_VALUE             =     0
    local MAX_VALUE             = 10000
    local WW_AGS_Filter         = ValueRangeFilterBase:Subclass()
    WritWorthy.WW_AGS_Filter    = WW_AGS_Filter

    function WW_AGS_Filter:New(...)
        return ValueRangeFilterBase.New(self, ...)
    end

    function WW_AGS_Filter:Initialize()
        ValueRangeFilterBase.Initialize(
                      self
                    , FILTER_ID.WRIT_WORTHY_WRIT_COST_FILTER
                    , FilterBase.GROUP_LOCAL
                    , {
                          label     = WritWorthy.Str("ags_label")
                        , currency  = CURT_MONEY
                        , min       = MIN_VALUE
                        , max       = MAX_VALUE
                        , precision = 0
                        , steps     = { MIN_VALUE, 2, 4, 6, 8, 10, 20, 30, 40
                                      , 50, 100, 200, 300, 400, MAX_VALUE }
                        , enabled    = {
                            [SUB_CATEGORY_ID.CONSUMABLE_WRIT] = true
                        }
                    }
        )
    end

    function WW_AGS_Filter:FilterLocalResult(item_data)
        local item_link      = item_data.itemLink
        local purchase_price = item_data.purchasePrice

        local voucher_ct     = WritWorthy.ToVoucherCount(item_link)
        if not voucher_ct then
            return true
        end
        local mat_gold   = WritWorthy.GetMatCost(item_link)
        if not mat_gold then
            return true
        end
        local total_gold = (mat_gold or 0) + (purchase_price or 0)
        local gold_per_voucher = Util.round(total_gold / voucher_ct)

        if (self.localMin and gold_per_voucher < self.localMin) then
            return false
        elseif(self.localMax and self.localMax < gold_per_voucher) then
            return false
        end

        return true
    end

    function WW_AGS_Filter:IsLocal()
        return true
    end

    AGS:RegisterFilter(WW_AGS_Filter:New())
    AGS:RegisterFilterFragment(AGS.class.PriceRangeFilterFragment:New(
                                    FILTER_ID.WRIT_WORTHY_WRIT_COST_FILTER))
end

-- Must be called AFTER AGS.SearchTabWrapper:InitializeFilters() because
-- RegisterFilterFragment() requires InitializeFilters()'s creation of
-- ags.tradingHouse.searchTab.filterArea.
--
-- Must be called BEFORE  searchManager:OnFiltersInitialized()
-- and self.filterArea:OnFiltersInitialized()
--
-- AGS.callback.AFTER_FILTER_SETUP was created for exactly this purpose.
--
function WritWorthy.RegisterAGSInitCallback()
    local AGS = AwesomeGuildStore   -- for less typing
    if WritWorthy.ags_callback_registered then return end
    WritWorthy.ags_callback_registered = true
    if not (    AGS
            and AGS.GetAPIVersion
            and AGS.GetAPIVersion() == 4) then
        return
    end

    AGS:RegisterCallback( AGS.callback.AFTER_FILTER_SETUP
                        , WritWorthy.InitAGSIntegration
                        )
end

local CACHED_MAT_COST_MAX_CT = 100

function WritWorthy.GetCachedMatCost(item_link)
    WritWorthy.cached_mat_cost    = WritWorthy.cached_mat_cost or {}
    WritWorthy.cached_mat_cost_ct = WritWorthy.cached_mat_cost_ct or 0
    return WritWorthy.cached_mat_cost[item_link]
end

function WritWorthy.SetCachedMatCost(item_link, mat_cost)
    WritWorthy.cached_mat_cost    = WritWorthy.cached_mat_cost or {}
    WritWorthy.cached_mat_cost_ct = WritWorthy.cached_mat_cost_ct or 0

                        -- Replacing existing value?
                        -- Then we already know the value fits.
                        -- Insert and we're done.
    if WritWorthy.cached_mat_cost[item_link] then
        WritWorthy.cached_mat_cost[item_link] = mat_cost
        return
    end

                        -- Not enough room? Make room
    for k,_ in pairs(WritWorthy.cached_mat_cost) do
        if CACHED_MAT_COST_MAX_CT <= WritWorthy.cached_mat_cost_ct then
            WritWorthy.cached_mat_cost_ct = WritWorthy.cached_mat_cost_ct - 1
            WritWorthy.cached_mat_cost[k] = nil
        else
            break
        end
    end

    WritWorthy.cached_mat_cost_ct = WritWorthy.cached_mat_cost_ct + 1
    WritWorthy.cached_mat_cost[item_link] = mat_cost
end

function WritWorthy.GetMatCost(item_link)
    local mat_gold = WritWorthy.GetCachedMatCost(item_link)
    if mat_gold then
        -- Log:Add("GetMatCost cache hit : "..item_link.." cost:"..tostring(mat_gold))
        return mat_gold
    end
    -- Log:Add("GetMatCost cache miss: "..tostring(item_link))
    local parser     = WritWorthy.CreateParser(item_link)
    if not (parser and parser:ParseItemLink(item_link)) then
        return nil
    end
    local mat_list   = parser:ToMatList()
    local mat_gold   = WritWorthy.MatRow.ListTotal(mat_list) or 0
    WritWorthy.SetCachedMatCost(item_link, mat_gold)
    return mat_gold
end
