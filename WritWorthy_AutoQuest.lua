ZO_CreateStringId("SI_KEYBINDINGS_CATEGORY_WRIT_WORTHY", "WritWorthy")
ZO_CreateStringId("WRIT_WORTHY_ACCEPT_QUESTS", "Accept Writ Quests")


local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Define.lua
WritWorthy.AQCache = {}

WritWorthy.QUEST_TITLES = {
  ["A Masterful Concoction"] = CRAFTING_TYPE_ALCHEMY
, ["Masterful Tailoring"   ] = CRAFTING_TYPE_CLOTHIER
, ["A Masterful Plate"     ] = CRAFTING_TYPE_BLACKSMITHING
, ["A Masterful Glyph"     ] = CRAFTING_TYPE_ENCHANTING
, ["A Masterful Feast"     ] = CRAFTING_TYPE_PROVISIONING
, ["A Masterful Shield"    ] = CRAFTING_TYPE_WOODWORKING
, ["An overpriced bauble"  ] = CRAFTING_TYPE_JEWELRYCRAFTING
}

function WritWorthy_AddAutoQuest(inventory_slot, slot_actions)
    local bag_id, slot_index = ZO_Inventory_GetBagAndIndex(inventory_slot)
    if not WritWorthy.IsAutoQuestableWrit(bag_id, slot_id) then
        return false
    end
    -- ZIG YOU LEFT OFF HERE
end

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
    return WritWorthy:GetNextAutoQuestableWrit()
end

-- Scan for and return the bag slot_id of the next Sealed Master Writ that
-- can be accepted and turned in.
--
-- Called from UI command-enabling code VERY frequently as the mouse
-- hovers over each inventory item, so results MUST be O(1) cached.
function WritWorthy:GetNextAutoQuestableWrit()
    if not self.aq_next_writ_slot then
        self.aq_next_writ_slot = WritWorthy.AQCache:New(
            { scan_func  = WritWorthy.FindNextAutoQuestableWrit
            , event_list = { EVENT_INVENTORY_ITEM_USED
                           , EVENT_ITEM_SLOT_CHANGED
                           -- need back dep/withdrawal events here
                           , EVENT_QUEST_ADDED
                           , EVENT_QUEST_COMPLETE
                           }
            , name       = "next_writ_slot"
            })
    end
    local r = self.aq_next_writ_slot:Get()
    if 0 < r then
        return r
    end
    return nil
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
    return 0
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

                        -- Accept every acceptable master writ that
                        -- we can find. This is an O(n*m) loop. If
                        -- this turns out to be slow, or if the
                        -- quest journal doesn't update without a
                        -- zo_callLater() chain, then we can rewrite
                        -- this loop later.
    local loop_limit = 7
    local slot_id = WritWorthy.FindNextAutoQuestableWrit()
    while slot_id do
        d("WWAQ: accept slot_id:"..tostring(slot_id))

        if IsProtectedFunction("UseItem") then
            CallSecureProtected("UseItem", BAG_BACKPACK, slot_id)
        else
            UseItem(slot_id)
        end

                        -- Prevent infinite loops.
        loop_limit = loop_limit - 1
        if loop_limit <= 0 then return end
    end
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
            , event_list = { EVENT_QUEST_ADDED
                           , EVENT_QUEST_COMPLETE
                           }
            , name       = "quest_state"
            })
    end
    local qs = self.aq_quest_state:Get()
    return qs
end

function WritWorthy.ScanQuestJournal()
    -- return a table[crafting_type] = quest_index
    local r = {}
    for qi = 1, MAX_JOURNAL_QUESTS do
        local qinfo = { GetJournalQuestInfo(qi) }
        local quest_name = qinfo[1]
        local crafting_type = WritWorthy.QUEST_TITLES[quest_name]
        if qinfo[10] == QUEST_TYPE_CRAFTING and not crafting_type then
            d("Unknown crafting quest:'"..quest_name.."'")
        end
        if quest_name and crafting_type then
d("WWAQ: ScanQuestJournal crafting_type:"..tostring(crafting_type).." qi:"..tostring(qi)
    .." "..tostring(quest_name))
            r[crafting_type] = qi
        end
    end
    return r
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

