-- Do you have enough skill points in some crafting passive?

local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Define.lua

WritWorthy.RequiredSkill = {}

RequiredSkill = WritWorthy.RequiredSkill

function RequiredSkill:New(skill_index, ability_index, function_name)
    local o = {
        skill_index    = skill_index
    ,   ability_index  = ability_index
    ,   function_name  = function_name
    ,   _name          = nil  -- lazy fetched
    ,   _is_purchased  = nil
    ,   _is_maxxed     = nil
    ,   _have          = nil
    ,   _max           = nil
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function RequiredSkill:ToKnow()
    if self.function_name == "IsMaxxed" then
        local known = self:IsKnown()
        local text  = string.format( "Insufficient skill '%s': %d/%d"
                                   , self:Name()
                                   , self._have
                                   , self._max
                                   )
        return WritWorthy.Know:New(
            { name     = "Skill: "..self:Name()
            , is_known = known
            , lack_msg = text
            })
    else
        local known = self:IsKnown()
        local text  = string.format("Missing skill: %s", self:Name())
        return WritWorthy.Know:New({ name = "Skill: "..self:Name()
                                   , is_known = known
                                   , lack_msg = text
                                   })
    end
end

function RequiredSkill:IsKnown()
    return self[self.function_name](self)
end

-- This lazy-fetch and then latch idiom means that if the player acquires the
-- skill after we latch, only a /reloadui will update us. I'm fine with that. I
-- don't feel like wasting network time polling the server every time we need a
-- tooltip, especially when called in a loop for WritWorthyInventoryList.

function RequiredSkill:Name()
    if self._name == nil then
        self:FetchInfo()
    end
    return self._name
end

function RequiredSkill:IsPurchased()
    if self._is_purchsed == nil then
        self:FetchInfo()
    end
    return self._is_purchased
end

function RequiredSkill:IsMaxxed()
    if self._is_maxxed == nil then
        self:FetchUpgradeInfo()
    end
    return self._is_maxxed
end

function RequiredSkill:FetchInfo()
    local info = { GetSkillAbilityInfo(
                              SKILL_TYPE_TRADESKILL
                            , self.skill_index
                            , self.ability_index
                            ) }
    if self._name ~= nil and self._is_purchased ~= nil then
        self._name         = info[1]
        self._is_purchased = info[6]
    else
                        -- Unable to fetch info about this skill for some
                        -- reason. Give up and ignore this requirement.
        self._name         = "?"
        self._is_purchased = true
    end
end

function RequiredSkill:FetchUpgradeInfo()
    self._have, self._max = GetSkillAbilityUpgradeInfo(
                              SKILL_TYPE_TRADESKILL
                            , self.skill_index
                            , self.ability_index
                            )
    if self._max ~= nil and self._have ~= nil then
        self._is_maxxed = self._max <= self._have
    else
                        -- Unable to fetch info about this skill for some
                        -- reason. Give up and ignore this requirement.
        self._is_maxxed = true
    end
end

local R = WritWorthy.RequiredSkill  -- for less typing

R.BS_TEMPER_EXPERTISE = R:New( 2, 6, "IsMaxxed"    ) -- Temper Expertise
R.CL_TEMPER_EXPERTISE = R:New( 3, 6, "IsMaxxed"    ) -- Tannin Expertise
R.WW_TEMPER_EXPERTISE = R:New( 6, 6, "IsMaxxed"    ) -- Resin Expertise
R.EN_ASPECT_GOLD      = R:New( 4, 1, "IsMaxxed"    ) -- Aspect Improvement
R.PR_FOOD_4X          = R:New( 5, 5, "IsMaxxed"    ) -- Chef
R.PR_DRINK_4X         = R:New( 5, 6, "IsMaxxed"    ) -- Brewer
R.AL_POTION_4X        = R:New( 1, 4, "IsMaxxed"    ) -- Chemistry
R.AL_LABORATORY_USE   = R:New( 1, 5, "IsPurchased" ) -- Laboratory Use, 3 reagents

