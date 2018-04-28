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

                        -- see EXTERNAL_FILTER_PROVIDER in ags FilterBase.lua
local FILTER_TYPE_ID_WRITWORTHY = 103

function WritWorthy.InitAGSIntegration()
    if WritWorthy.ags_init_started then return end
    WritWorthy.ags_init_started = true
    local AGS = AwesomeGuildStore   -- for less typing
    if not (    AGS
            and AGS.GetAPIVersion
            and AGS.GetAPIVersion() == 3) then
        return
    end

    Log:Add("InitAGSIntegration, AGS e:"..tostring(AwesomeGuildStore ~= nil)
        .." .FILTER_PRESETS e:"..tostring(AwesomeGuildStore
                                      and AwesomeGuildStore.FILTER_PRESETS ~= nil))
    Log:Add("AGS.FilterBase:"..tostring(AwesomeGuildStore
                                      and AwesomeGuildStore.FilterBase))
    WritWorthy:InsertIntoAGSTables()
end

function WritWorthy:InsertIntoAGSTables()
    Log:StartNewEvent()
    Log:Add("InsertIntoAGSTables")
    if not (    AwesomeGuildStore
            and AwesomeGuildStore.FilterBase ) then
        Log:Add("InsertIntoAGSTables() called too soon."
                .." AGS.FilterBase not yet defined.")
        return
    end
                        -- Find the FILTER_PRESETS slot for
                        -- Consumables/Master Writs
    local want_label = zo_strformat( SI_TOOLTIP_ITEM_NAME
                                   , GetString( "SI_ITEMTYPE"
                                              , ITEMTYPE_MASTER_WRIT
                                              )
                                   )
    local fp  = AwesomeGuildStore.FILTER_PRESETS
    local fpc = fp[ITEMFILTERTYPE_CONSUMABLE]
    for i,subcategory in ipairs(fpc.subcategories) do
        if subcategory.label == want_label then
            Log:Add("subcategory.subfilters before insertion:"
                ..tostring(subcategory.subfilters))
            subcategory.subfilters = subcategory.subfilters or {}
            table.insert(subcategory.subfilters, SUBFILTER_WRITWORTHY)
            Log:Add("subcategory.subfilters after insertion:"
                ..tostring(subcategory.subfilters))
        end
    end

    if not WritWorthy.ags_filter_class then
        WritWorthy.ags_filter_class = WritWorthy.AGS_CreateFilterClass()
    end
                        -- Insert a subfilter definition for
                        -- SUBFILTER_WRITWORTHY.
    local filter = {
        type = FILTER_TYPE_ID_WRITWORTHY
    ,   label = "WritWorthy63"  -- user visible? History? Where?
    ,   filter = FILTER_TYPE_ID_WRITWORTHY
    ,   class  = WritWorthy.ags_filter_class
    }
    AwesomeGuildStore.SUBFILTER_PRESETS[SUBFILTER_WRITWORTHY] = filter
end

-- begin editor inheritance from Master Merchant -----------------------------

function WritWorthy.AGS_CreateFilterClass()
    local gettext           = LibStub("LibGetText")("AwesomeGuildStore").gettext
    local FilterBase        = AwesomeGuildStore.FilterBase
    local WWAGSFilter       = FilterBase:Subclass()
    local LINE_SPACING      = 4

    function WWAGSFilter:New(name, tradingHouseWrapper, ...)
                        -- FilterBase.New() internally calls
                        --   InitializeBase(), creating container control
                        --      and resetButton
                        --   Initialize() overridable
        return FilterBase.New(self, FILTER_TYPE_ID_WRITWORTHY, name, tradingHouseWrapper, ...)
    end

    function WWAGSFilter:Initialize(name, tradingHouseWrapper)
        local tradingHouse = tradingHouseWrapper.tradingHouse
        local saveData = tradingHouseWrapper.saveData
        local container = self.container

                        -- Red (pink!) title for our portion of
                        -- the filter sidebar.
        local label = container:CreateControl(name .. "Label", CT_LABEL)
        label:SetFont("ZoFontWinH4")
        label:SetText("Per Voucher:")
        self:SetLabelControl(label)

                        -- Edit field.
        local bg = CreateControlFromVirtual(
                          "WritWorthyAGSEditBG"
                        , container
                        , "WritWorthyAGSEditBox"
                        )
        bg:SetAnchor(TOPLEFT    , label    , BOTTOMLEFT , 0,  LINE_SPACING)
        bg:SetAnchor(BOTTOMRIGHT, container, BOTTOMRIGHT, 0,  0)
        self.edit = bg:GetNamedChild("Box")
        ZO_EditDefaultText_Initialize(self.edit, "Filter by crafted cost")
        self.edit:SetMaxInputChars(6)
        self.edit:SetHandler("OnTextChanged",
            function()
                ZO_EditDefaultText_OnTextChanged(self.edit)
                self:HandleChange()
            end
        )
        self.edit:SetTextType(TEXT_TYPE_NUMERIC_UNSIGNED_INT)

        container:SetHeight(  label:GetHeight() + LINE_SPACING
                            + 28 )

        local tooltipText = gettext("Reset <<1>> Filter", label:GetText():gsub(":", ""))
        self.resetButton:SetTooltipText(tooltipText)
    end

    function WWAGSFilter:GetTextAsNumber()
        local s = self.edit:GetText()
        local n = tonumber(s)
        if n and 0 <= n and n <= 99999 then return n end
        return nil
    end

    function WWAGSFilter:BeforeRebuildSearchResultsPage(tradingHouseWrapper)
        if(not self:IsDefault()) then
            self.max_gold_per_voucher = self:GetTextAsNumber()
            return true
        end
        return false
    end

    function WWAGSFilter:ApplyFilterValues(filterArray)
        -- do nothing here as we want to filter on the result page
    end

    function WWAGSFilter:FilterPageResult(index, icon, name, quality, stackCount, sellerName, timeRemaining, purchasePrice)
                        -- Is this a sealed master writ that WritWorthy
                        -- can understand?
        local item_link  = GetTradingHouseSearchResultItemLink(index,LINK_STYLE_DEFAULT)
        local parser     = WritWorthy.CreateParser(item_link)
        if not (parser and parser:ParseItemLink(item_link)) then return true end
        local voucher_ct = WritWorthy.ToVoucherCount(item_link)
        if not voucher_ct then return true end
        local mat_list   = parser:ToMatList()
        local mat_gold   = WritWorthy.MatRow.ListTotal(mat_list) or 0
        local total_gold = (mat_gold or 0) + (purchasePrice or 0)
        local gold_per_voucher = Util.round(total_gold / voucher_ct)
        return gold_per_voucher <= self.max_gold_per_voucher
    end

    function WWAGSFilter:Reset()
        self.edit:SetText("")
    end

    function WWAGSFilter:IsDefault()
        local n = self:GetTextAsNumber()
        local is_default = not n
        return is_default
    end

    function WWAGSFilter:Serialize()
        local per_voucher = self:GetTextAsNumber()
        if not per_voucher then return "" end
        return tostring(per_voucher)
    end

    function WWAGSFilter:Deserialize(state)
        local text   = state
        local number = tonumber(text)
        if number then
            self.edit:SetText(tostring(number))
        else
            self.edit:SetText("")
        end
    end

    function WWAGSFilter:GetTooltipText(state)
                        -- Return a list of { label, text } tuples
                        -- that appear in the AGS search history.
        local tip_line_list = {}

        local text   = state
        local number = tonumber(text)
        if number then
            local line = { label = "Crafted per-voucher cost"
                         , text  = Util.ToMoney(number).."g"
                         }
            table.insert(tip_line_list, line)
        end
        return tip_line_list
    end

    return WWAGSFilter
end

--[[ Still not working yet

* sporadic "duplicate name" errors on load

-- Not adding for now, but I could see this being useful:
* filter by "motif and traits known, writ is craftable"

]]
