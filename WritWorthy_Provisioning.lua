-- Parse a food or dring request.

local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Util.lua

WritWorthy.Provisioning = {
}


local Provisioning = WritWorthy.Provisioning
local Fail         = WritWorthy.Util.Fail

-- Find a recipe by name.
--
-- First time this runs, we cache a list of all 554 recipe names.
-- Takes almost 1 second!
--
-- returns a 2-tuple:
--   recipe_list_index : 1..28  which of 28 lists
--   recipe_index      : 1..36  recipe's index with the above recipe list
--   mat_ct            : 1..5   number of different ingredients in recipe
function Provisioning.FindRecipe(fooddrink_name)
    local recipe_list_ct = GetNumRecipeLists()
    for rl_index = 1,recipe_list_ct do
        local rl_name, rl_recipe_ct = GetRecipeListInfo(rl_index)
        for recipe_index = 1,rl_recipe_ct do
            local _, r_fooddrink_name, mat_ct
                = GetRecipeInfo(rl_index, recipe_index)
                        -- Some recipe slots in the list are blanked out.
                        -- Skip 'em.
            if 0 < mat_ct then
                if fooddrink_name:find(r_fooddrink_name) then
                    d("found:"..fooddrink_name)
                    return rl_index, recipe_index, mat_ct
                end
            end
        end
    end
    return Fail("recipe not found:"..fooddrink_name)
end

Provisioning.Parser = {}
local Parser = Provisioning.Parser

function Parser:New()
    local o = {
        base_text         = nil   -- "Consume to start quest"
                                  -- "\nCraft a Chicken Breast"

    ,   recipe_list_index = nil   -- 1..28 separate recipe lists
    ,   recipe_index      = nil   -- sub-index within the above list
    ,   fooddrink_name    = nil  -- "Chicken Breast"
    ,   mat_ct            = nil   -- 1..5+ number of ingredients

    ,   mat_list        = {}    -- of MatRow
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Parser:ParseBaseText(base_text)
    self.recipe_list_index, self.recipe_index, self.mat_ct
        = Provisioning.FindRecipe(base_text)
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

