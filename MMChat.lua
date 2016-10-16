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
MMChat.channel_id_enabled = {
  [CHAT_CHANNEL_WHISPER] = true
, [CHAT_CHANNEL_GUILD_3] = true
--, [CHAT_CHANNEL_GUILD_5] = true
, [CHAT_CHANNEL_OFFICER_3] = true
--, [CHAT_CHANNEL_OFFICER_5] = true
}
MMChat.text_queue = {}

MMChat.LINK_PATTERN   = '|H%d:item:[0-9:]+|h[^|]*|h'
MMChat.LINK_PATTERN_N = '([%d+x]*) ?('..MMChat.LINK_PATTERN..')'

function MMChat.round(f)
    if not f then return f end
    return math.floor(0.5+f)
end


-- Item ----------------------------------------------------------------------
local Item = {}
function Item:FromLinkCt(link, ct)
    local o = { total_value = 0
              , ct          = ct
              , mm          = nil
              , link        = link
              }
    setmetatable(o, self)
    self.__index = self
    return o
end

-- A formatted line suitable for display in chat
function Item:ToText()
    return         tostring(ZO_CurrencyControl_FormatCurrency(self.total_value, false))
        .."  = ".. tostring(self.ct) .."x"
        .." "   .. tostring(ZO_CurrencyControl_FormatCurrency(self.mm, false)) .."g"
        .."   " .. tostring(self.link)
end

function Item:FetchMM()
    self.mm = MMChat.MMPrice(self.link)
    self.mm = 12 -- NUR ZUM DEBUGGEN
    if self.mm then
        self.total_value = self.mm * self.ct
    end
end

-- MMChat --------------------------------------------------------------------
-- Might some day go dynamic, but for now...
function MMChat:IsEnabledForChannelID(channel_id)
    return MMChat.channel_id_enabled[channel_id]
end

-- Is this MM-worthy?
-- "|H0:item:4456:30:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
function MMChat:ContainsLink(text)
    return string.match(text, MMChat.LINK_PATTERN)
end

-- Convert "100x" to integer 100. Convert empty (no multiplier) to 1.
function MMChat:ToInt(s)
    if not s or s == "" then return 1 end
    local nox = string.gsub(s,"x", "")
    return tonumber(nox)
end

-- Donated by @astraea360: 10x|H1:item:54181:34:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h 100x|H1:item:54180:33:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h 200x|H1:item:54179:32:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h 200x|H1:item:54178:31:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h
-- (Flash Auction, 15 seconds) Donated by @dot_hackza: |H1:item:84705:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:0:0|h|h

-- Given a string "100xRawhide 50xHemming Dreugh Wax"
-- return a list of Items
--      (100 "Rawhide"      )
--      ( 50 "Hemming"      )
--      (  1  "Dreugh Wax"  )
--
-- Suitable for MM-ification and multiplication (but that's someone else's focus).
--
function MMChat:ToLinkCounts(text)
    local r = {}
    for ct, link in string.gmatch(text, MMChat.LINK_PATTERN_N) do
        local item = Item:FromLinkCt(link, MMChat:ToInt(ct))
        table.insert(r, item)
    end
    return r
end

function MMChat.MMPrice(link)
    if not MasterMerchant then return nil end
    if not link then return nil end
    mm = MasterMerchant:itemStats(link, false)
    if not mm then return nil end
    --d("MM for link: "..tostring(link).." "..tostring(mm.avgPrice))
    return mm.avgPrice
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
    --EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)
end

-- Chat Event Handler --------------------------------------------------------

-- Using zo_calllater() to defer this MM handling until AFTER we're out of chat
-- handling, so that we don't break any chat events with our noise.
function MMChat.AfterMessage()
    local text = table.remove(MMChat.text_queue, 1)
    if not text then
        d("dequeued nothing")
        return
    end
    d("dequeued " .. text)
    local item_list = MMChat:ToLinkCounts(text)
    local total     = 0
    for i, item in ipairs(item_list) do
        item:FetchMM()
        d(item:ToText())
        total = total + item.total_value
    end
    d(ZO_CurrencyControl_FormatCurrency(total, false) .. "g total")
end

function MMChat.OnEventChatMessageChannel(
          event_id
        , channel_id
        , from
        , text
        , is_cust_svc
        )
    if not MMChat:IsEnabledForChannelID(channel_id) then return end

    d("on_event")
    -- d("on_e event_id:"..tostring(event_id)
    --     .." id:"..tostring(channel_id).." from:"..tostring(from)
    --     .." is_cs:"..tostring(is_cust_svc).." text:'"..tostring(text).."'")

    -- -- Get channel information
    -- local zo_channel_info_array = ZO_ChatSystem_GetChannelInfo()
    -- local zo_channel_info = zo_channel_info_array[channel_id]
    -- if not zo_channel_info or not zo_channel_info.format then return end

    -- return text, zo_channel_info.saveTarget
    if MMChat:ContainsLink(text) then
        d("link detected")
        table.insert(MMChat.text_queue, text)
        -- zo_calllater(MMChat.AfterMessage, 50)
        MMChat.AfterMessage()
    end
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
