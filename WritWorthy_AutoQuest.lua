-- Automate the "open writs/turn in to Rolis" sequence that happens after
-- you have pre-crafted a ton of writ items and are standing near Rolis
-- ready to turn them all in.
--

ZO_CreateStringId("WRIT_WORTHY_ACCEPT_QUESTS", "Accept Writ Quests")

local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Define.lua
WritWorthy.AQCache = {}             -- class defined later in this file

local SLOT_ID_NONE = -1     -- slot_id when we KNOW that the bag holds no
                            -- auto-questable sealed master writs.
                            -- Because "nil" means "don't know"
                            -- and "0" is an actual valid slot ID.

function WritWorthy:AQAddKeyBind()
    local menu = LibCustomMenu
    if not menu then return end
    if not WritWorthy.RequireLibCraftText() then return end

                        -- ### BROKEN in 4.2 !
                        -- Not sure what broke when, will figure out later.
                        -- or not. `/writworthy auto` is mo fasta.

--     menu:RegisterContextMenu(WritWprthy_AddAutoQuest, menu.CATEGORY_EARLY)
--     menu:RegisterKeyStripEnter(WritWprthy_AddAutoQuest, menu.CATEGORY_EARLY)

--     self.auto_queue_button_group = {
--           alignment = KEYBIND_STRIP_ALIGN_LEFT
--         , {   name      = GetString(WRIT_WORTHY_ACCEPT_QUESTS)
--           ,   keybind   = "WRIT_WORTHY_ACCEPT_QUESTS"
--           ,   enabled   = true
--           ,   visible   = WritWorthy_BagHasAnyWrits
--           ,   order     = 100
--           ,   callback  = WritWorthy_AutoQuest
--           }
--     }

--     BACKPACK_MENU_BAR_LAYOUT_FRAGMENT:RegisterCallback(
--           "StateChange"
--         , function(old_state, new_state)
--             if new_state == SCENE_SHOWN then
-- --                WritWorthy:AQInvalidateAll()
--                 KEYBIND_STRIP:AddKeybindButtonGroup(WritWorthy.auto_queue_button_group)
--             elseif new_state == SCENE_HIDING then
--                 KEYBIND_STRIP:RemoveKeybindButtonGroup(WritWorthy.auto_queue_button_group)
--             end
--           end
--         )
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
    -- d("WWAQ: FindNext...")
                        -- Do NOT use bank or ESO+ subscriber bank here,
                        -- even if enabled in settings: you cannot accept
                        -- a quest from a banked writ. Only ones in the bag.
    local bag_id = BAG_BACKPACK
    for slot_id = 0, GetBagSize(bag_id) do
        local item_link = GetItemLink(bag_id, slot_id)
        if WritWorthy.IsAutoQuestableWrit(bag_id, slot_id) then
            -- d("WWAQ: Yep : "..tostring(slot_id).." "..item_link)
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
    d("|c33FF33WritWorthy: Don't forget your XP potion/scroll!")
    WritWorthy:AutoQuest()
end

function WritWorthy:AutoQuest()
                        -- Register listeners to chain use/dialog/use/dialog
                        -- callback sequence.
    WritWorthy:StartAutoAcceptMode()
    WritWorthy:RegisterRolisChatter()

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
        d("|cEEEEEEWritWorthy: Writs accepted. Go talk to Rolis.|r")
        self:EndAutoAcceptMode()
        return
    end
    local item_link = GetItemLink(BAG_BACKPACK, slot_id)
    -- d("WWAQ: accept slot_id:"..tostring(slot_id).." "..tostring(item_link))
    if IsProtectedFunction("UseItem") then
        CallSecureProtected("UseItem", BAG_BACKPACK, slot_id)
    else
        UseItem(BAG_BACKPACK, slot_id)
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

    -- EVENT_MANAGER:RegisterForEvent( name
    --                               , EVENT_CHATTER_BEGIN
    --                               , WritWorthy_AutoAcceptModeChatterBegin)
end

function WritWorthy:EndAutoAcceptMode()
    -- d("WWAQ: EndAutoAcceptMode")
    self.aq_auto_accept_mode = false
    local name = WritWorthy.name .. "_aq_auto_accept_mode"
    local event_list = { EVENT_QUEST_ADDED
                       , EVENT_QUEST_OFFERED
                       -- , EVENT_CHATTER_BEGIN
                       }
    for _,event_id in ipairs(event_list) do
        EVENT_MANAGER:UnregisterForEvent( name
                                        , EVENT_QUEST_ADDED )
    end
    ResetChatter()
end

function WritWorthy_AutoAcceptModeQuestAdded()
    -- d("WWAQ: AutoAcceptModeQuestAdded.")
    zo_callLater(function() WritWorthy:AcceptFirstAcceptableWrit() end, 500 )
end

function WritWorthy_AutoAcceptModeQuestOffered()
    local x = {GetOfferedQuestInfo()}
    -- d("WWAQ: AutoAcceptModeQuestOffered response:"..tostring(x[2]))
    zo_callLater(
        function()
            -- d("WWAQ: AcceptOfferedQuest()")
            AcceptOfferedQuest()
            ResetChatter()
        end
    , 500 )
end

-- EVENT_CHATTER_BEGIN is NOT called for the "-Sealed XXX Writ-" dialog
-- that appears after using a Sealed Master Writ. Only EVENT_QUEST_OFFERED.
-- EVENT_CHATTER_END is still called when the "-Sealed XXX Writ-" dialog closes.
-- function WritWorthy_AutoAcceptModeChatterBegin(event_id, option_ct)
--     d("WWAQ: AutoAcceptModeChatterBegin option_ct:"..tostring(option_ct))
--     local x = { GetChatterOption(1) }
--     d(x)
-- end

function WritWorthy:RegisterRolisChatter()
-- d("WWAQ:RegisterRolisChatter")
    local name = WritWorthy.name .. "_aq_rolis_chatter"
    EVENT_MANAGER:RegisterForEvent( name
                                  , EVENT_CHATTER_BEGIN
                                  , function() WritWorthy:OnRolisChatterBegin() end )
    EVENT_MANAGER:RegisterForEvent( name
                                  , EVENT_QUEST_COMPLETE_DIALOG
                                  , function(event_id, quest_index)
                                        WritWorthy:OnRolisQuestCompleteDialog(
                                                                  event_id
                                                                , quest_index )
                                    end )
end

function WritWorthy:UnregisterRolisChatter()
-- d("WWAQ:UnregisterRolisChatter")
    local name = WritWorthy.name .. "_aq_rolis_chatter"
    local event_list = { EVENT_CHATTER_BEGIN
                       , EVENT_QUEST_COMPLETE_DIALOG
                       }
    for _,event_id in ipairs(event_list) do
        EVENT_MANAGER:UnregisterForEvent( name
                                        , event_id
                                        )
    end
end

function WritWorthy:OnRolisChatterBegin()
    -- d("WWAQ: rolis chatter begin")
    zo_callLater(function() WritWorthy:RolisChoose() end, 500)
end

function WritWorthy:RolisChoose()
    if not WritWorthy.RequireLibCraftText() then return end

    local opt_text = GetChatterOption(1)
                        -- "I've finished the Blacksmithing job."
    local ct = LibCraftText.RolisDialogOptionToCraftingType(opt_text)

                        -- "<Finish the job.>"
    if ct or LibCraftText.MASTER.DIALOG.OPTION_FINISH_JOB == opt_text then
        SelectChatterOption(1)

                        -- "Store (Mastercraft Mediator)"
    elseif LibCraftText.MASTER.DIALOG.OPTION_STORE == opt_text then
                        -- All writs turned in. We're done
        WritWorthy:AQInvalidateAll()
        WritWorthy:UnregisterRolisChatter()
        EndInteraction(INTERACTION_CONVERSATION)
        local next_writ_slot_id = WritWorthy:GetNextAutoQuestableWrit()
        -- d("|cEEEEEEDone turning in writs.|r")
        if (SLOT_ID_NONE ~= next_writ_slot_id) then
            d("|cEEEEEEOpening more writs...|r")
            WritWorthy:AutoQuest()
        else
            WritWorthy:UnregisterRolisChatter()
            d("|cEEEEEENo more writs.|r")
        end
    else
                        -- Dialog is not a Writ turn-in dialog,
    end
end

function WritWorthy:OnRolisQuestCompleteDialog(event_id, quest_index)
    -- d("WWAQ: rolis quest complete dialog")
    zo_callLater(function() WritWorthy:RolisCompleteQuest(quest_index) end, 500)
end

function WritWorthy:RolisCompleteQuest(quest_index)
    if not WritWorthy.RequireLibCraftText() then return end
    local x = { GetJournalQuestEnding(quest_index) }
                        -- "<He notes your work and tenders payment.>"
    if x[2] == LibCraftText.MASTER.DIALOG.RESPONSE_ENDING then
        CompleteQuest()
    end
end

-- Quest Journal Cache -------------------------------------------------------
--
-- Return a table[crafting_type] = quest_index_int
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

function WritWorthy.RequireLibCraftText()
    if WritWorthy.aq_libcrafttext_loaded == nil then
        if LibCraftText then
            WritWorthy.aq_libcrafttext_loaded = true
        else
            WritWorthy.aq_libcrafttext_loaded = false
            d("|cFF6666WritWorthy_AutoQuest: missing LibCraftText.")
        end
    end
    return WritWorthy.aq_libcrafttext_loaded
end

function WritWorthy.ScanQuestJournal()
    if not WritWorthy.RequireLibCraftText() then return {} end

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
        local crafting_type_list = LibCraftText.MasterQuestNameToCraftingTypeList(quest_name)
        if qinfo[10] == QUEST_TYPE_CRAFTING and not crafting_type_list then
            d("Unknown crafting quest:'"..quest_name.."'")
        end
        if quest_name and crafting_type_list then
            for _,ct in ipairs(crafting_type_list) do
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
-- d("AQC scan:"..self.name)
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
-- d("AQC invalidate:"..self.name)
    self.cache = nil
    self:Unregister()
end

function WritWorthy.AQCache:Register()
-- d("AQC register:"..self.name)
    zo_callLater(function()
        for _,event_id in ipairs(self.event_list) do
            EVENT_MANAGER:RegisterForEvent( WritWorthy.name .. "_aq_" .. self.name
                                          , event_id
                                          , function() self:Invalidate() end)
        end
        end, 100)
end

function WritWorthy.AQCache:Unregister()
-- d("AQC unregister:"..self.name)
    for _,event_id in ipairs(self.event_list) do
        EVENT_MANAGER:UnregisterForEvent( WritWorthy.name .. "_aq_" .. self.name
                                        , event_id )
    end
end
