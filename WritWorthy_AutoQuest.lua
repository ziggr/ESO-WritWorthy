ZO_CreateStringId("SI_KEYBINDINGS_CATEGORY_WRIT_WORTHY", "WritWorthy")
ZO_CreateStringId("WRIT_WORTHY_ACCEPT_QUESTS", "Accept Writ Quests")

local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Define.lua
WritWorthy.AQCache = {}             -- class defined later in this file

                        -- Hints to help us immediately recognize accepted
                        -- master writ quests so that we can skip over any
                        -- sealed master writs of that type when looking for
                        -- the next acceptable writ.
                        --
                        -- Imperfect! Both WW and BS use the same quest
                        -- name and details for completed weapons.
                        --
WritWorthy.QUEST_TITLES = {
  ["A Masterful Concoction"] = { CRAFTING_TYPE_ALCHEMY }
, ["Masterful Tailoring"   ] = { CRAFTING_TYPE_CLOTHIER }
, ["A Masterful Plate"     ] = { CRAFTING_TYPE_BLACKSMITHING }
, ["A Masterful Glyph"     ] = { CRAFTING_TYPE_ENCHANTING }
, ["A Masterful Feast"     ] = { CRAFTING_TYPE_PROVISIONING }
, ["A Masterful Shield"    ] = { CRAFTING_TYPE_WOODWORKING }
, ["A Masterful Weapon"    ] = { CRAFTING_TYPE_WOODWORKING
                               , CRAFTING_TYPE_BLACKSMITHING }
, ["An overpriced bauble"  ] = { CRAFTING_TYPE_JEWELRYCRAFTING }
}

local SLOT_ID_NONE = -1     -- slot_id when we KNOW that the bag holds no
                            -- auto-questable sealed master writs.
                            -- Because "nil" means "don't know"
                            -- and "0" is an actual valid slot ID.

function WritWorthy:AddKeyBind()
    local menu = LibStub("LibCustomMenu")
    menu:RegisterContextMenu(WritWprthy_AddAutoQuest, menu.CATEGORY_EARLY)
    menu:RegisterKeyStripEnter(WritWprthy_AddAutoQuest, menu.CATEGORY_EARLY)

    self.auto_queue_button_group = {
          alignment = KEYBIND_STRIP_ALIGN_LEFT
        , {   name      = GetString(WRIT_WORTHY_ACCEPT_QUESTS)
          ,   keybind   = "WRIT_WORTHY_ACCEPT_QUESTS"
          ,   enabled   = true
          ,   visible   = WritWorthy_BagHasAnyWrits
          ,   order     = 100
          ,   callback  = WritWorthy_AutoQuest
          }
    }

    BACKPACK_MENU_BAR_LAYOUT_FRAGMENT:RegisterCallback(
          "StateChange"
        , function(old_state, new_state)
            if new_state == SCENE_SHOWN then
--                WritWorthy:AQInvalidateAll()
                KEYBIND_STRIP:AddKeybindButtonGroup(WritWorthy.auto_queue_button_group)
            elseif new_state == SCENE_HIDING then
                KEYBIND_STRIP:RemoveKeybindButtonGroup(WritWorthy.auto_queue_button_group)
            end
          end
        )
end

-- Enable/disable function for AutoQuest "Accept Writ Quests"
-- Called VERY frequently as you mouse over the inventory screen.
function WritWorthy_BagHasAnyWrits()
    -- d("WWAQ:BagHasAny()")
    return SLOT_ID_NONE ~= WritWorthy:GetNextAutoQuestableWrit()
end

-- Scan for and return the bag slot_id of the next Sealed Master Writ that
-- can be accepted and turned in.
--
-- Called from UI command-enabling code VERY frequently as the mouse
-- hovers over each inventory item, so results MUST be O(1) cached.
--
-- Returns SLOT_ID_NONE, not nil, no no auto-questable sealed
-- master writs found.
function WritWorthy:GetNextAutoQuestableWrit()
    if not self.aq_next_writ_slot then
        self.aq_next_writ_slot = WritWorthy.AQCache:New(
            { scan_func  = WritWorthy.FindNextAutoQuestableWrit
            , event_list = { EVENT_INVENTORY_ITEM_USED
                           , EVENT_ITEM_SLOT_CHANGED
                           , EVENT_CLOSE_BANK
                           , EVENT_QUEST_LIST_UPDATED
                           }
            , name       = "next_writ_slot"
            })
    end
    return self.aq_next_writ_slot:Get()
end

function WritWorthy.FindNextAutoQuestableWrit()
    -- Return slot_id of a writ that can be accepted for turn-in
    d("WWAQ: FindNext...")
                        -- Do NOT use bank or ESO+ subscriber bank here,
                        -- even if enabled in settings: you cannot accept
                        -- a quest from a banked writ. Only ones in the bag.
    local bag_id = BAG_BACKPACK
    for slot_id = 0, GetBagSize(bag_id) do
        local item_link = GetItemLink(bag_id, slot_id)
        if WritWorthy.IsAutoQuestableWrit(bag_id, slot_id) then
            d("WWAQ: Yep : "..tostring(slot_id).." "..item_link)
            return slot_id
        end
        --d("WWAQ: Nope: "..tostring(slot_id).." "..item_link)
    end
    return SLOT_ID_NONE
end

function WritWorthy.IsAutoQuestableWrit(bag_id, slot_id, quest_state)
                        -- Is this a writ that we previously auto-crafted?
    local unique_id = WritWorthy.UniqueID(bag_id, slot_id)
    local inventory_data = WritWorthyInventoryList.singleton:UniqueIDToInventoryData(unique_id)
    if not (inventory_data and inventory_data.ui_is_completed) then
        return false
    end
                        -- Need to check state: only one quest
                        -- for each type
    local crafting_type = inventory_data.parser.crafting_type
    local qj = quest_state or WritWorthy:GetQuestState()
    if qj[crafting_type] then
        return false
    end

    return true
end

-- React to a button press in the innventory screen's
-- "WritWorthy: Accept Writ Quests" button.
function WritWorthy_AutoQuest()
    d("Pretend I'm doing the thing")

                        -- Register listeners to chain use/dialog/use/dialog
                        -- callback sequence.
    WritWorthy:StartAutoAcceptMode()

                        -- Start the sequence.
    WritWorthy:AcceptFirstAcceptableWrit()
end

function WritWorthy:AcceptFirstAcceptableWrit()

                        -- Get a fresh picture of the state of the world,
                        -- just in case things have changed that our
                        -- event listeners failed to detect. I don't EVER
                        -- want to accidentally use anything other than
                        -- a master writ.
    self:AQInvalidateAll()

    local slot_id = WritWorthy.FindNextAutoQuestableWrit()
    if not slot_id or slot_id == SLOT_ID_NONE then
        d("WWAQ: No more writs to accept. Done.")
        self:EndAutoAcceptMode()
        return
    end
    local item_link = GetItemLink(BAG_BACKPACK, slot_id)
    d("WWAQ: accept slot_id:"..tostring(slot_id).." "..tostring(item_link))
    if IsProtectedFunction("UseItem") then
        CallSecureProtected("UseItem", BAG_BACKPACK, slot_id)
    else
        UseItem(slot_id)
    end
end

function WritWorthy:StartAutoAcceptMode()
    self.aq_auto_accept_mode = true
    local name = WritWorthy.name .. "_aq_auto_accept_mode"
    EVENT_MANAGER:RegisterForEvent( name
                                  , EVENT_QUEST_ADDED
                                  , WritWorthy_AutoAcceptModeQuestAdded)

    EVENT_MANAGER:RegisterForEvent( name
                                  , EVENT_QUEST_OFFERED
                                  , WritWorthy_AutoAcceptModeQuestOffered)

    EVENT_MANAGER:RegisterForEvent( name
                                  , EVENT_CHATTER_BEGIN
                                  , WritWorthy_AutoAcceptModeChatterBegin)

end

function WritWorthy:EndAutoAcceptMode()
    d("WWAQ: EndAutoAcceptMode")
    self.aq_auto_accept_mode = false
    local name = WritWorthy.name .. "_aq_auto_accept_mode"
    local event_list = { EVENT_QUEST_ADDED
                       , EVENT_QUEST_OFFERED
                       , EVENT_CHATTER_BEGIN
                       }
    for _,event_id in ipairs(event_list) do
        EVENT_MANAGER:UnregisterForEvent( name
                                        , EVENT_QUEST_ADDED )
    end
    ResetChatter()
end

function WritWorthy_AutoAcceptModeQuestAdded()
    d("WWAQ: AutoAcceptModeQuestAdded.")
    zo_callLater(function() WritWorthy:AcceptFirstAcceptableWrit() end, 500 )
end

function WritWorthy_AutoAcceptModeQuestOffered()
    local x = {GetOfferedQuestInfo()}
    d("WWAQ: AutoAcceptModeQuestOffered response:"..tostring(x[2]))
    zo_callLater(
        function()
            d("WWAQ: AcceptOfferedQuest()")
            AcceptOfferedQuest()
            ResetChatter()
        end
    , 500 )
end

-- EVENT_CHATTER_BEGIN is NOT called for the "-Sealed XXX Writ-" dialog
-- that appears after using a Sealed Master Writ. Only EVENT_QUEST_OFFERED.
-- EVENT_CHATTER_END is still called when the "-Sealed XXX Writ-" dialog closes.
function WritWorthy_AutoAcceptModeChatterBegin(event_id, option_ct)
    d("WWAQ: AutoAcceptModeChatterBegin option_ct:"..tostring(option_ct))
    local x = { GetChatterOption(1) }
    d(x)
end

-- Quest Journal Cache -------------------------------------------------------
--
-- Return a table[crafting_type] = quest_index_int
--
-- Returned table is a snapshot of the quest journal, and does not
-- dynamically update if calling code later mutates the quest journal by
-- accepting or completing quests. This is usually what I want.
--
function WritWorthy:GetQuestState()
    if not self.aq_quest_state then
        self.aq_quest_state = WritWorthy.AQCache:New(
            { scan_func  = WritWorthy.ScanQuestJournal
            , event_list = { EVENT_QUEST_LIST_UPDATED
                           }
            , name       = "quest_state"
            })
    end
    local qs = self.aq_quest_state:Get()
    return qs
end

function WritWorthy.ScanQuestJournal()
    -- return a table[crafting_type] = quest_index

    -- If a single quest matches multiple possible crafting types, associate
    -- that quest with ALL possible matching crafting types. It is far simpler
    -- to code for occasionally being unable to accept any WW quest because
    -- a BS quest got in the way, than to code for accepting a quest and
    -- then dealing with UseItem() returning errors and us having to find
    -- ANOTHER inventory writ to accept, or leaving the "Autoquest" button
    -- enabled when in fact there are currently no writs that we can accept.

    local r = {}
    for qi = 1, MAX_JOURNAL_QUESTS do
        local qinfo = { GetJournalQuestInfo(qi) }
        local quest_name = qinfo[1]
        local crafting_type = WritWorthy.QUEST_TITLES[quest_name]
        if qinfo[10] == QUEST_TYPE_CRAFTING and not crafting_type then
            d("Unknown crafting quest:'"..quest_name.."'")
        end
        if quest_name and crafting_type then
            for _,ct in ipairs(crafting_type) do
d("WWAQ: ScanQuestJournal crafting_type:"..tostring(crafting_type).." qi:"..tostring(qi)
    .." "..tostring(quest_name))
                r[ct] = qi
            end
        end
    end
    return r
end

-- Each time we open the inventory screen, clear our cache and start clean.
-- During non-auto-queue mode, I really don't want to tap into all the
-- events I'd have to in order to detect any changes.
function WritWorthy:AQInvalidateAll()
    if self.aq_next_writ_slot then
        self.aq_next_writ_slot:Invalidate()
    end
    if self.aq_quest_state then
        self.aq_quest_state:Invalidate()
    end
end

-- AQCache -------------------------------------------------------------------
-- A cache that knows how to listen for and invalidate upon event(s).

function WritWorthy.AQCache:New(args)
    local o = {
        cache       = nil
    ,   scan_func   = args.scan_func
    ,   event_list  = args.event_list
    ,   name        = args.name
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function WritWorthy.AQCache:Scan()
d("AQC scan:"..self.name)
    return self.scan_func()
end

function WritWorthy.AQCache:Get()
    if not self.cache then
        self.cache = self:Scan()
        self:Register()
    end
    return self.cache
end

function WritWorthy.AQCache:Invalidate()
d("AQC invalidate:"..self.name)
    self.cache = nil
    self:Unregister()
end

function WritWorthy.AQCache:Register()
d("AQC register:"..self.name)
    for _,event_id in ipairs(self.event_list) do
        EVENT_MANAGER:RegisterForEvent( WritWorthy.name .. "_aq_" .. self.name
                                      , event_id
                                      , function() self:Invalidate() end)
    end
end

function WritWorthy.AQCache:Unregister()
d("AQC unregister:"..self.name)
    for _,event_id in ipairs(self.event_list) do
        EVENT_MANAGER:UnregisterForEvent( WritWorthy.name .. "_aq_" .. self.name
                                        , event_id )
    end
end

--[[
INVENTORY_ITEM_USED
QUEST_OFFERED
QUEST_ADDED 6, "A Masterful Plate", ""
CHATTER_END
INVENTORY_SLOT_SINGLE_SLOT_UPDATE ( 1,0,false,0,0,-1)
QUEST_POSITION_REQUEST_COMPLETE

]]


--[[

SURPRISE! This is NEVER CALLED for opening a sealed master writ
 All I get is

 INVENTORY_ITEM_USED
 QUEST_OFFERED

 GetInteractionType() -> 3 == INTERACTION_QUEST


function WWAQ_HandleChatterBegin(event_id, option_ct)
    d("WWAQ_HandleChatterBegin option_ct:"..tostring(option_ct))
    for i=1,option_ct do
        local x = {GetChatterOption(i)}
        d(tostring(i)..": option_type:"..tostring(x[2].." "..x[1]))
    end
end

EVENT_MANAGER:RegisterForEvent( "WritWorthy_ZZ_HACK"
                              , EVENT_CHATTER_BEGIN
                              , WWAQ_HandleChatterBegin)

2018-07-23 todo
-- test writ auto-accept chain, make sure it still works
-- listen for chatter begin
    on begin, zo_callLater() a test-and-accept function
    test-and-acccept
        if in chatter
            if chatter option 1 is "turn in" then
                turn in
                zo_callLater() test-and-accept
            else
                end this chain
                unregister chatter begin
                -- eventually zo_callLater() the inventory-writ-accept chain
        else
            -- not in chatter, maybe user aborted?
            do nothing

]]
