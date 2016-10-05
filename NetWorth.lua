local LAM2 = LibStub("LibAddonMenu-2.0")

local NetWorth = {}
NetWorth.name            = "NetWorth"
NetWorth.version         = "2.5.1"
NetWorth.savedVarVersion = 1
NetWorth.NAME_BANK        = "bank"
NetWorth.NAME_CRAFT_BAG   = "craft bag"
NetWorth.default = {
    bags = {}
}

-- Item ----------------------------------------------------------------------
--
-- The occupant of a single bag slot. This is a single item, or a stack of
-- items. In the BAG_BACKPACK, materials can occupy multiple slots, so they
-- will appear as multiple Item instances. This is expected.

local Item = {}
function Item:FromNothing()
    local o = { total_value = 0
              , ct          = 0
              , mm          = 0
              , npc         = 0  -- Value if sold to NPC Vendor
              , name        = ""
              }
    setmetatable(o, self)
    self.__index = self
    return o
end

function max(a, b)
    if not a then return b end
    if not b then return a end
    return math.max(a, b)
end

function Item:FromBag(bag_id, slot_index)
    local item_name = GetItemName(bag_id, slot_index)
    local item_link = GetItemLink(bag_id, slot_index, LINK_STYLE_DEFAULT)
    local _, ct, npc_sell_price = GetItemInfo(bag_id, slot_index)
    local mm = NetWorth.MMPrice(item_link)
    local o = { total_value = ct * max(npc_sell_price, mm)
              , ct          = ct
              , mm          = mm
              , npc         = npc_sell_price
              , name        = item_name
              }
    setmetatable(o, self)
    self.__index = self
    return o
end

-- Bag -----------------------------------------------------------------------
--
-- One line in the summary display, with the itemized details that built
-- up to that line.
--
-- One "bag" is one of:
--    - a single character's items (BAG_BACKPACK + BAG_WORN)
--    - bank (BAG_BANK)
--    - craft bag (BAG_VIRTUAL)
--

local Bag = {}
function Bag:FromName(name)
    local o = { name = name
              , total = 0
              , gold  = 0
              , item_subtotal = 0
              , item_ct = 0
              }
    setmetatable(o, self)
    self.__index = self
    return o
end

-- Main entry for a bag.
-- Fans out to specific bag-fetching subroutines.
function Bag:ReadFromServer()
    if self.name == NetWorth.NAME_BANK then
        self:ReadFromBagId(BAG_BANK)
        self.gold = GetBankedMoney()
        self.total = self.gold + self.item_subtotal
        d(self.name .. " total:" .. tostring(self.total) .. " item_ct:" .. #self.items)
    elseif self.name == NetWorth.NAME_CRAFT_BAG then
        self:ReadFromCraftBag()
        self.total = self.gold + self.item_subtotal
        d(self.name .. " total:" .. tostring(self.total) .. " item_ct:" .. #self.items)
    else
        self:ReadFromBagId(BAG_BACKPACK)
        self:ReadFromBagId(BAG_WORN)
        self.gold = GetCurrentMoney()
        self.total = self.gold + self.item_subtotal
        d(self.name .. " total:" .. tostring(self.total) .. " item_ct:" .. #self.items)
    end
end

function Bag:ReadFromBagId(bag_id)
    local slot_ct = GetBagSize(bag_id)
    for slot_index = 1, slot_ct do
        local item = Item:FromBag(bag_id, slot_index)
        self:AddItem(item)
    end
end

function Bag:ReadFromCraftBag()
    slot_id = GetNextVirtualBagSlotId(slot_id)
    while slot_id do
        local item = Item:FromBag(bag_id, slot_index)
        self:AddItem(item)
        slot_id = GetNextVirtualBagSlotId(slot_id)
    end
end

function Bag:AddItem(item)
    self.item_subtotal = self.item_subtotal + item.total_value
    self.item_ct = self.item_ct + 1
end

-- Init ----------------------------------------------------------------------

function NetWorth.OnAddOnLoaded(event, addonName)
    if addonName ~= NetWorth.name then return end
    if not NetWorth.version then return end
    if not NetWorth.default then return end
    NetWorth:Initialize()
end

function NetWorth:Initialize()

    self.savedVariables = ZO_SavedVars:NewAccountWide(
                              "NetWorthVars"
                            , self.savedVarVersion
                            , nil
                            , self.default
                            )
    self:CreateSettingsWindow()
    --EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)
end

-- UI ------------------------------------------------------------------------

function NetWorth:CreateSettingsWindow()
    local panelData = {
          type                = "panel"
        , name                = "Net Worth"
        , displayName         = "Net Worth"
        , author              = "ziggr"
        , version             = self.version
        , slashCommand        = "/nn"
        , registerForRefresh  = true
        , registerForDefaults = false
    }
    local cntrlOptionsPanel = LAM2:RegisterAddonPanel( self.name
                                                     , panelData
                                                     )
    local optionsData = {
        { type      = "button"
        , name      = "Scan Now"
        , tooltip   = "Fetch inventory data now."
        , func      = function() self:ScanNow() end
        },

        { type      = "description"
        , text      = "line 1\nline 2\nline 3\n"
        , width     = "half"
        , reference = "NetWorth_desc_left"
        },

        { type      = "description"
        , text      = "val 1\nval 2\nval 3\n"
        , width     = "half"
        , reference = "NetWorth_desc_right"
        },

    }

    LAM2:RegisterOptionControls("NetWorth", optionsData)
    CALLBACK_MANAGER:RegisterCallback("LAM-PanelControlsCreated"
            , self.OnPanelControlsCreated)
end

-- Delay initialization of options panel: don't waste time fetching
-- guild names until a human actually opens our panel.
function NetWorth.OnPanelControlsCreated(panel)
    self = NetWorth
    -- ### put live data into the desc panels
end

-- Fetch Inventory Data from the server ------------------------------------------

function NetWorth:ScanNow()
    local char_name = GetUnitName("player")
    self.bag = { [1] = Bag:FromName(NetWorth.NAME_BANK)
               , [2] = Bag:FromName(NetWorth.NAME_CRAFT_BAG)
               , [3] = Bag:FromName(char_name)
               }
    self.bag[1]:ReadFromServer()
    self.bag[2]:ReadFromServer()
    self.bag[3]:ReadFromServer()
end

function NetWorth.MMPrice(link)
    if not MasterMerchant then return nil end
    if not link then return nil end
    mm = MasterMerchant:itemStats(link, false)
    if not mm then return nil end
    --d("MM for link: "..tostring(link).." "..tostring(mm.avgPrice))
    return mm.avgPrice
end


-- Postamble -----------------------------------------------------------------

EVENT_MANAGER:RegisterForEvent( NetWorth.name
                              , EVENT_ADD_ON_LOADED
                              , NetWorth.OnAddOnLoaded
                              )
