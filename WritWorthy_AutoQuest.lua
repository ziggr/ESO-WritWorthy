ZO_CreateStringId("SI_KEYBINDINGS_CATEGORY_WRIT_WORTHY", "WritWorthy")
ZO_CreateStringId("WRIT_WORTHY_ACCEPT_QUESTS", "Accept Writ Quests")


local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Define.lua

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
function WritWorthy_BagHasAnyWrits()
    return WritWorthy.FindNextAutoQuestableWrit()
end

function WritWorthy.FindNextAutoQuestableWrit()
    -- Return slot_id of a writ that can be accepted for turn-in

                        -- Do NOT use bank or ESO+ subscriber bank here,
                        -- even if enabled in settings: you cannot accept
                        -- a quest from a banked writ. Only ones in the bag.
    local bag_id = BAG_BACKPACK
    for slot_it = 0, GetBagSize(bag_id) do
        if WritWorthy.IsAutoQuestableWrit(bag_id, slot_id) then
            return slot_id
        end
    end
    return nil
end

function WritWorthy.IsAutoQuestableWrit(bag_id, slot_id)
                        -- Is this a writ that we previously auto-crafted?
    local unique_id = WritWorthy.UniqueID(bag_id, slot_id)
    local inventory_data = WritWorthyInventoryList.singleton:UniqueIDToInventoryData(unique_id)
    if not inventory_data and inventory_data.ui_is_completed then
        return false
    end

    local crafting_type = inventory_data.parser.crafting_type


                        -- Need to check state: only one questable
                        -- for each type

                        -- Need to check savedChariables for
                        -- unique ID did we craft this or not.

    return true
end


function WritWorthy_AutoQuest()
    d("Pretend I'm doing the thing")
end

--[[
A Masterful Concoction - alch
Masterful Tailoring - cloth
A Masterful Plate - black
A Masterful Glyph - ench
A Masterful Feast - prov
A Masterful Shield - wood

]]
