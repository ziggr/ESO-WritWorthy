-- Parse a food or dring request.

local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Util.lua

WritWorthy.Provisioning = {
    NAMES = nil     -- lazy-loaded in LoadData()
}

local Provisioning = WritWorthy.Provisioning
local Fail         = WritWorthy.Util.Fail

-- Lazy-fetch all 554 recipe names from ZOScode, cache them and their
-- double-indices in Provisioning.NAMES.
--
-- There's no reason to load this amount of data EVERY time you launch
-- ESO, you often go days between hovering a cursor over a
-- Provisioning Master Writ.
--
-- But you DEFINITELY want to cache this. It takes ~1 second to scan all
-- 554 recipes, not something you want to do repeatedly if you ARE hovering
-- a cursor over master writs.
--
function Provisioning.LoadData()
    if Provisioning.NAMES then return Provisioning.NAMES end
    local names = {}
    local recipe_list_ct = GetNumRecipeLists()
    for rl_index = 1,recipe_list_ct do
        local rl_name, rl_recipe_ct = GetRecipeListInfo(rl_index)
        for recipe_index = 1,rl_recipe_ct do
            local _, fooddrink_name, mat_ct
                = GetRecipeInfo(rl_index, recipe_index)
                        -- Some recipe slots in the list are blanked out.
                        -- Skip 'em.
            if 0 < mat_ct then
                names[fooddrink_name] = { rl_index, recipe_index }
            end
        end
    end
    d("WritWorthy: "..tostring(#names).." recipe names loaded.")
    Provisioning.NAMES = names
    return Provisioning.NAMES
end

-- Find a recipe by name.
--
-- First time this runs, we cache a list of all 554 recipe names.
-- Takes 1+ second!
--
-- Second-and-later times this runs, it's O(1) instantaneous.
--
-- returns a 3-tuple:
--   recipe_list_index : 1..28  which of 28 lists
--   recipe_index      : 1..36  recipe's index with the above recipe list
--   mat_ct            : 1..5   number of different ingredients in recipe
--
function Provisioning.FindRecipe(fooddrink_name)
    local data  = Provisioning.LoadData()
    local found = data[fooddrink_name]
    if not found then return Fail("recipe not found:\""..tostring(fooddrink_name).."\"") end
    local rl_index     = found[1]
    local recipe_index = found[2]
    local _, r_fooddrink_name, mat_ct
        = GetRecipeInfo(rl_index, recipe_index)
    return rl_index, recipe_index, mat_ct
end

Provisioning.Parser = {}
local Parser = Provisioning.Parser

function Parser:New()
    local o = {
        base_text         = nil -- "Consume to start quest"
                                -- "\nCraft a Chicken Breast"

    ,   recipe_list_index = nil -- 1..28 separate recipe lists
    ,   recipe_index      = nil -- sub-index within the above list
    ,   fooddrink_name    = nil -- "Chicken Breast"
    ,   mat_ct            = nil -- 1..5+ number of ingredients

    ,   mat_list          = {}  -- of MatRow
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Parser:ParseBaseText(base_text)
    self.fooddrink_name = base_text:match("Craft an? (.+)")
    if not self.fooddrink_name then return Fail("unable to regex food/drink") end
    self.recipe_list_index, self.recipe_index, self.mat_ct
        = Provisioning.FindRecipe(self.fooddrink_name)
    if not self.mat_ct then return nil end
    return self
end

function Parser:ToMatList()
    local MatRow = WritWorthy.MatRow
    local ml     = {}
    for ingr_index = 1,self.mat_ct do
        local ingr_name, _, ingr_ct = GetRecipeIngredientItemInfo(
                                          self.recipe_list_index
                                        , self.recipe_index
                                        , ingr_index)
        local ingr_link = GetRecipeIngredientItemLink(
                                          self.recipe_list_index
                                        , self.recipe_index
                                        , ingr_index)
        table.insert(ml, MatRow:FromLink(ingr_link, ingr_ct))
    end
    self.mat_list = ml
    return ml
end

