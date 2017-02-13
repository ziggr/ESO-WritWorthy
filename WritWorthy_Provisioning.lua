-- Parse a food or dring request.

local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Util.lua

WritWorthy.Provisioning = {
}


local Provisioning = WritWorthy.Provisioning
local Fail         = WritWorthy.Util.Fail

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
                        -- This is noticeably slow, takes almost 1 second
                        -- on my machine. Jarring. Future ideas:
                        -- 1. Cache recent hits so that re-touching the same
                        --    writ over and over doesn't lock up the world.
                        -- 2. Preload a "name"->{ rl_index, recipe_index }
                        --    2-tuple hashtable makes it an O(1) lookup once you
                        --    regex out the key from the base_text.
                        -- I prefer #2. Could lazy-build that ONCE per launch,
                        -- don't even need a 554-entry hashtable unless you
                        -- mouseover a provisioning writ.

    local recipe_list_ct = GetNumRecipeLists()
    for rl_index = 1,recipe_list_ct do
        local rl_name, rl_recipe_ct = GetRecipeListInfo(rl_index)
        for recipe_index = 1,rl_recipe_ct do
            local _, fooddrink_name, mat_ct
                = GetRecipeInfo(rl_index, recipe_index)
                        -- Some recipe slots in the list are blanked out.
                        -- Skip 'em.
            if 0 < mat_ct then
                d("rl:"..tostring(rl_index).." ri:"..tostring(recipe_index)
                    .." name:"..tostring(fooddrink_name)
                    .." mat_ct:"..tostring(mat_ct))
                if base_text:find(fooddrink_name) then
                    self.recipe_list_index = rl_index
                    self.recipe_index      = recipe_index

                    self.fooddrink_name    = fooddrink_name
                    self.mat_ct            = mat_ct
                    d("found:"..fooddrink_name)
                    break
                end
            end
        end
        if self.fooddrink_name then break end
    end
    if not self.fooddrink_name then return Fail("recipe not found") end
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

