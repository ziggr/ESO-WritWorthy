local LAM2 = LibStub("LibAddonMenu-2.0")

local MMChat = {}
MMChat.name            = "MMChat"
MMChat.version         = "2.6.1"
MMChat.savedVarVersion = 1
MMChat.NAME_BANK       = "bank"
MMChat.NAME_CRAFT_BAG  = "craft bag"
MMChat.char_index      = nil
MMChat.default = {
    bag = {}
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
           -- , link        = "" -- Not retaining Link: makes data file too large.
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
    if ct == 0 then return nil end
    local mm = MMChat.MMPrice(item_link)
    local o = { total_value = Item.round(ct * max(npc_sell_price, mm))
              , ct          = ct
              , mm          = Item.round(mm)
              , npc         = npc_sell_price
              , name        = item_name
           -- , link        = item_link
              }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Item.round(f)
    if not f then return f end
    return math.floor(0.5+f)
end

function Item:ToDString()
    return "tot:" .. tostring(self.total_value)
      ..   " ct:" .. tostring(self.ct)
      ..   " mm:" .. tostring(self.mm)
      ..  " npc:" .. tostring(self.npc)
      .. " name:" .. tostring(self.name)
      -- .. " link:" .. tostring(self.link)
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
              , items = {}
              }
    setmetatable(o, self)
    self.__index = self
    return o
end

-- Main entry for a bag.
-- Fans out to specific bag-fetching subroutines.
function Bag:ReadFromServer()
    if self.name == MMChat.NAME_BANK then
        self:ReadFromBagId(BAG_BANK)
        self.gold = GetBankedMoney()
        self.total = self.gold + self.item_subtotal
        d(self.name .. " total:" .. ZO_CurrencyControl_FormatCurrency(self.total, false) .. " item_ct:" .. self.item_ct)
    elseif self.name == MMChat.NAME_CRAFT_BAG then
        self:ReadFromCraftBag()
        self.total = self.gold + self.item_subtotal
        d(self.name .. " total:" .. ZO_CurrencyControl_FormatCurrency(self.total, false) .. " item_ct:" .. self.item_ct)
    else
        self:ReadFromBagId(BAG_BACKPACK)
        self:ReadFromBagId(BAG_WORN)
        self.gold = GetCurrentMoney()
        self.total = self.gold + self.item_subtotal
        d(self.name .. " total:" .. ZO_CurrencyControl_FormatCurrency(self.total, false) .. " item_ct:" .. self.item_ct)
    end
end

function Bag:ReadFromBagId(bag_id)
    local slot_ct = GetBagSize(bag_id)
    for slot_index = 0, slot_ct do
        local item = Item:FromBag(bag_id, slot_index)
        self:AddItem(item)
    end
end

function Bag:ReadFromCraftBag()
    slot_id = GetNextVirtualBagSlotId(slot_id)
    while slot_id do
        local item = Item:FromBag(BAG_VIRTUAL, slot_id)
        self:AddItem(item)
        slot_id = GetNextVirtualBagSlotId(slot_id)
    end
end

function Bag:AddItem(item)
    if not item then return end
    self.item_subtotal = self.item_subtotal + item.total_value
    self.item_ct = self.item_ct + 1

        -- We don't actually NEED itemized lists here, except for debugging
        -- or checking our work. ToDString() is sufficient, and allows us to
        -- fit all 8 characters + bank and craftbag all under 1MB.
        --
        -- 8x data compression just by omitting links and storing only
        -- strings instead of structured data:
        --
        -- 256KB structured, with links
        --  96KB structured, without links
        --  29KB as strings, without links
    table.insert(self.items, item:ToDString())
end

-- Init ----------------------------------------------------------------------

function MMChat.OnAddOnLoaded(event, addonName)
    if addonName ~= MMChat.name then return end
    if not MMChat.version then return end
    if not MMChat.default then return end
    MMChat:Initialize()
end

function MMChat:Initialize()

    self.savedVariables = ZO_SavedVars:NewAccountWide(
                              "MMChatVars"
                            , self.savedVarVersion
                            , nil
                            , self.default
                            )
    self.char_index = self:FindCharIndex()
    self:CreateSettingsWindow()
    --EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)
end

-- Return the bag index for this character, if it already has one, or a new
-- index if not.
function MMChat:FindCharIndex()
    local char_name = GetUnitName("player")
    for i, bag in ipairs(self.savedVariables.bag) do
        if bag.name == char_name then return i end
    end
    return 1 + #self.savedVariables.bag
end

-- UI ------------------------------------------------------------------------

function MMChat:CreateSettingsWindow()
    local panelData = {
          type                = "panel"
        , name                = "MMChat"
        , displayName         = "MMChat"
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
        , text      = ""
        , width     = "half"
        , reference = "MMChat_desc_bags"
        },

        { type      = "description"
        , text      = ""
        , width     = "half"
        , reference = "MMChat_desc_amounts"
        },

    }

    LAM2:RegisterOptionControls("MMChat", optionsData)
    CALLBACK_MANAGER:RegisterCallback("LAM-PanelControlsCreated"
            , self.OnPanelControlsCreated)
end

-- Delay initialization of options panel: don't waste time fetching
-- guild names until a human actually opens our panel.
function MMChat.OnPanelControlsCreated(panel)
    self = MMChat
    if not (MMChat_desc_amounts and MMChat_desc_amounts.desc) then return end
    if MMChat_desc_amounts.desc then
        MMChat_desc_amounts.desc:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
    end
    self:UpdateDisplay()
end

function MMChat:UpdateDisplay()
    local bag_name   = {}
    local bag_amount = {}
    local total      = 0
    local total_gold = 0
    local total_item = 0
    for i, bag in ipairs(self.savedVariables.bag) do
        bag_name  [i] = bag.name
        bag_amount[i] = ZO_CurrencyControl_FormatCurrency(bag.gold + bag.item_subtotal, false)
        total = total + bag.gold + bag.item_subtotal
        total_gold = total_gold + bag.gold
        total_item = total_item + bag.item_subtotal
    end
    table.insert(bag_name,   "--")
    table.insert(bag_name,  "total")
    table.insert(bag_amount, "--")
    table.insert(bag_amount, ZO_CurrencyControl_FormatCurrency(total, false))
    table.insert(bag_name,   "")
    table.insert(bag_amount, "")
    table.insert(bag_name,   "in gold")
    table.insert(bag_name,   "in inventory")
    table.insert(bag_amount, ZO_CurrencyControl_FormatCurrency(total_gold, false))
    table.insert(bag_amount, ZO_CurrencyControl_FormatCurrency(total_item, false))

    local sn = table.concat(bag_name,   "\n")
    local sa = table.concat(bag_amount, "\n")

    MMChat_desc_bags.data.text    = sn
    MMChat_desc_amounts.data.text = sa
    MMChat_desc_bags.desc:SetText(sn)
    MMChat_desc_amounts.desc:SetText(sa)
end

-- Fetch Inventory Data from the server ------------------------------------------

function MMChat:ScanNow()
    local char_name = GetUnitName("player")
    local ci = self.char_index
    self.bag = { [1 ] = Bag:FromName(MMChat.NAME_BANK)
               , [2 ] = Bag:FromName(MMChat.NAME_CRAFT_BAG)
               , [ci] = Bag:FromName(char_name)
               }
    self.bag[1 ]:ReadFromServer()
    self.bag[2 ]:ReadFromServer()
    self.bag[ci]:ReadFromServer()

    self.savedVariables.bag[1 ] = self.bag[1 ]
    self.savedVariables.bag[2 ] = self.bag[2 ]
    self.savedVariables.bag[ci] = self.bag[ci]

    self:UpdateDisplay()
end

function MMChat.MMPrice(link)
    if not MasterMerchant then return nil end
    if not link then return nil end
    mm = MasterMerchant:itemStats(link, false)
    if not mm then return nil end
    --d("MM for link: "..tostring(link).." "..tostring(mm.avgPrice))
    return mm.avgPrice
end

-- Chat Event Handler --------------------------------------------------------

function MMChat.OnChatMessageChannel( channel_id
                                    , from
                                    , text
                                    , is_cust_svc
                                    )

    d("on_cmc id:"..tostring(channel_id).." from:"..tostring(from)
        .." is_cs:"..tostring(is_cust_svc).." text:'"..tostring(text).."'")


    -- Get channel information
    local zo_channel_info_array = ZO_ChatSystem_GetChannelInfo()
    local zo_channel_info = zo_channel_info_array[channel_id]
    if not zo_channel_info or not zo_channel_info.format then return end

    return text, zo_channel_info.saveTarget
end

function MMChat.OnEventChatMessageChannel( event_id
                                    , channel_id
                                    , from
                                    , text
                                    , is_cust_svc
                                    )

    d("on_e event_id:"..tostring(event_id)
        .." id:"..tostring(channel_id).." from:"..tostring(from)
        .." is_cs:"..tostring(is_cust_svc).." text:'"..tostring(text).."'")


    -- Get channel information
    local zo_channel_info_array = ZO_ChatSystem_GetChannelInfo()
    local zo_channel_info = zo_channel_info_array[channel_id]
    if not zo_channel_info or not zo_channel_info.format then return end

    return text, zo_channel_info.saveTarget
end

-- Postamble -----------------------------------------------------------------

EVENT_MANAGER:RegisterForEvent( MMChat.name
                              , EVENT_ADD_ON_LOADED
                              , MMChat.OnAddOnLoaded
                              )

-- ZO_ChatSystem_AddEventHandler() does not work if other
-- ZO_ChatSystem_AddEventHandler() clients are in play: Shissu/pChat/libChat2
-- and wkyyyd's enhanced chat all cause this  to not be called.
--
-- ZO_ChatSystem_AddEventHandler ( EVENT_CHAT_MESSAGE_CHANNEL
--                               , MMChat.OnChatMessageChannel
--                               )

-- EVENT_MANAGER:RegisterForEvent() is post-called, after the message appears
-- in chat, after wykkyd and libChat2 have a chance to modify and display.
-- Perfect for our needs as an after-event trigger.

EVENT_MANAGER:RegisterForEvent( MMChat.name .. "2"
                              , EVENT_CHAT_MESSAGE_CHANNEL
                              , MMChat.OnEventChatMessageChannel
                              )
