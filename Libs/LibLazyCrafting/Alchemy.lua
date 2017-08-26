local LibLazyCrafting = LibStub("LibLazyCrafting")
local sortCraftQueue = LibLazyCrafting.sortCraftQueue

local function dbug(...)
	if not DolgubonGlobalDebugOutput then return end
	DolgubonGlobalDebugOutput(...)
end

local function LLC_CraftAlchemyPotionItemId(self, solventId, reagentId1, reagentId2, reagentId3, autocraft, reference)
	dbug('FUNCTION:LLCCraftAlchemy')
	if reference == nil then reference = "" end
	if not self then d("Please call with colon notation") end
	if autocraft==nil then autocraft = self.autocraft end
	if not solventId and reagentId1 and reagentId2 then return end -- reagentId3 optional, nil okay.

	table.insert(craftingQueue[self.addonName][CRAFTING_TYPE_ALCHEMY],
	{
		["solventId"] = solventId,
		["reagentId1"] = reagentId1,
		["reagentId2"] = reagentId2,
		["reagentId3"] = reagentId3,
		["timestamp"] = GetTimeStamp(),
		["autocraft"] = autocraft,
		["Requester"] = self.addonName,
		["reference"] = reference,
		["station"] = CRAFTING_TYPE_ALCHEMY,
	}
	)

	sortCraftQueue()
	if GetCraftingInteractionType()==CRAFTING_TYPE_ALCHEMY then
		LibLazyCrafting.craftInteract(event, CRAFTING_TYPE_ALCHEMY)
	end
end

local function LLC_CraftAlchemyPotion(self, selventBagId, solventSlotId, reagent1BagId, reagent1SlotId, reagent2BagId, reagent2SlotId, reagent3BagId, reagent3SlotId, timesToMake, autocraft, reference)
	local reagent3itemId
	if reagent3SlotId==nil then
		reagent3itemId = nil
	else
		reagent3itemId = GetItemId(reagent3BagId, reagent3SlotId)
	end
	LLC_CraftEnchantingGlyphItemID(self, GetItemId(selventBagId, solventSlotId),GetItemId( reagent1BagId, reagent1SlotId),GetItemId(reagent2BagId, reagent2SlotId), reagent3itemId, timesToMake,autocraft, reference)
end

local function copy(t)
	local a = {}
	for k, v in pairs(t) do
		a[k] = v
	end
	return a
end

-- Returns a table of [slot_index] --> stack count for each bag slot that holds
-- the requested item.
--
-- ALSO includes the first empty slot in bag, since there is still a chance
-- that this crafting attempt might start a new stack.
--
local function LLC_FindSlotsContaining(itemLink)
	local wantItemName = GetItemLinkName(itemLink)

	local r = {}
	local bagId = BAG_BACKPACK
	local maxSlotId = GetBagSize(bagId)
	for slotIndex = 0, maxSlotId do
		local slotLink = GetItemLink(bagId, slotIndex, LINK_STYLE_DEFAULT)
		if GetItemLinkName(slotLink) == wantItemName then
			r[slotIndex] = GetSlotStackSize(bagId, slotIndex)
		end
	end

	local emptySlotIndex = FindFirstEmptySlotInBag(bagId)
	r[emptySlotIndex] = 0
	return r
end

-- Return the first slot index of a stack of items that grew.
-- Return nil if no stacks grew.
local function LLC_FindIncreasedSlotIndex(prevSlotsContaining, newSlotsContaining)
	for slotIndex, prevStackSize in pairs(prevSlotsContaining) do
		local new = newSlotsContaining[slotIndex]
		if new and prevStackSize < new then
			return slotIndex
		end
	end
	return nil
end

local function LLC_AlchemyCraftInteraction(event, station)
	dbug("FUNCTION:LLCAlchemyCraft")
	local earliest, addon , position = LibLazyCrafting.findEarliestRequest(CRAFTING_TYPE_ALCHEMY)
	if (not earliest) or IsPerformingCraftProcess() then return end

	-- Find bag locations of each material used in the crafting attempt.
	local solventBagId, solventSlotIndex = findItemLocationById(earliest["solventId"])
	local reagent1BagId, reagent1SlotIndex = findItemLocationById(earliest["reagentId1"])
	local reagent2BagId, reagent2SlotIndex = findItemLocationById(earliest["reagentId2"])
	local reagent3BagId, reagent3SlotIndex = nil, nil
	if earliest["reagentId3"] then
		reagent3BagId, reagent3SlotIndex = findItemLocationById(earliest["reagentId3"])
	end
	local locations = {
		solventBagId, solventSlotIndex,
		reagent1BagId, reagent1SlotIndex,
		reagent2BagId, reagent2SlotIndex,
		reagent3BagId, reagent3SlotIndex,
	}
	if not (solventSlotIndex and reagent1SlotIndex and reagent2SlotIndex and (not earliest["reagentId3"] or reagent3SlotIndex)) then return end

	dbug("CALL:ZOAlchemyCraft")
	CraftAlchemyItem(unpack(locations))

	currentCraftAttempt= copy(earliest)
	currentCraftAttempt.callback = LibLazyCrafting.craftResultFunctions[addon]

						-- ZZ: This .slot field is INCORRECT when crafting
						-- multiple copies of the same stackable item such as
						-- alchemy potions or provisioning food/dring. In such
						-- a case, we'd have to scan the entire backback
						-- looking for our expected result, and record
						-- before/after totals to see if the total jumped by at
						-- least 1.
						-- We'd also need to deal with stacking limits: maybe
						-- we just crafted the 98th, 99th, 100th, and 101th
						-- copy of a potion and so the resulting 4 potions
						-- actually straddle two slots.
						--
						-- Maybe later. For now, no slot for you!
	currentCraftAttempt.slot = nil -- FindFirstEmptySlotInBag(BAG_BACKPACK)
	currentCraftAttempt.link = GetAlchemyResultingItemLink(unpack(locations))
	currentCraftAttempt.position = position
	currentCraftAttempt.timestamp = GetTimeStamp()
	currentCraftAttempt.addon = addon
	currentCraftAttempt.prevSlots = LLC_FindSlotsContaining(currentCraftAttempt.link)
end

local function LLC_AlchemyCraftingComplete(event, station, lastCheck)
	dbug("EVENT:CraftComplete")
	if not currentCraftAttempt.addon then return end

	-- Because alchemy potions stack, cannot trust .slot field here, so
	-- just assume it worked without checking for item name matches.

	local newSlots = LLC_FindSlotsContaining(currentCraftAttempt.link)
	local grewSlotIndex = LLC_FindIncreasedSlotIndex(currentCraftAttempt.prevSlots, newSlots)
	if grewSlotIndex then
		dbug("ACTION:RemoveQueueItem")
		craftingQueue[currentCraftAttempt.addon][CRAFTING_TYPE_ALCHEMY][currentCraftAttempt.position] = nil
		sortCraftQueue()
		local resultTable =
		{
			["bag"] = BAG_BACKPACK,
			["slot"] = grewSlotIndex,
			['link'] = currentCraftAttempt.link,
			['uniqueId'] = GetItemUniqueId(BAG_BACKPACK, currentCraftAttempt.slot),
			["quantity"] = 1,
			["reference"] = currentCraftAttempt.reference,
		}
		currentCraftAttempt.callback(LLC_CRAFT_SUCCESS, CRAFTING_TYPE_ALCHEMY, resultTable)
		currentCraftAttempt = {}

	elseif lastCheck then

		-- give up on finding it.
		currentCraftAttempt = {}
	else

		-- further search
		-- search again later
		if GetCraftingInteractionType()==0 then zo_callLater(function() LLC_EnchantingCraftingComplete(event, station, true) end,100) end
	end

end

LibLazyCrafting.craftInteractionTables[CRAFTING_TYPE_ALCHEMY] =
{
	["check"] = function(station) return station == CRAFTING_TYPE_ALCHEMY end,
	['function'] = LLC_AlchemyCraftInteraction,
	["complete"] = LLC_AlchemyCraftingComplete,
	["endInteraction"] = function(station) --[[endInteraction()]] end,
	["isItemCraftable"] = function(station) if station == CRAFTING_TYPE_ALCHEMY then return true else return false end end,
}

LibLazyCrafting.functionTable.CraftAlchemyPotion = LLC_CraftAlchemyPotion
LibLazyCrafting.functionTable.CraftAlchemyItemId = LLC_CraftAlchemyPotionItemId