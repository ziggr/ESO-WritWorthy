-- Do you have enough skill points in some crafting passive?

local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Define.lua

WritWorthy.RequiredSkill = {}

RequiredSkill = WritWorthy.RequiredSkill
Log = WritWorthy.Log


function RequiredSkill:New(skill_id, function_name)
    local o = {
        skill_id       = skill_id
    ,   function_name  = function_name
    ,   _skill_index   = nil
    ,   _ability_index = nil
    ,   _name          = nil
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
                                   , self._have or -1
                                   , self._max or -1
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
    return self._name or "?"
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
    if self._name and (self._is_purchased ~= nil) then return end

                        -- Unable to fetch info about this skill for some
                        -- reason? Set fallbacks to ignore this requirement.
    self._name         = "?"
    self._is_purchased = true

    local skill_index, ability_index = self:GetIndices()
    if not (skill_index and ability_index) then return end
    local info = { GetSkillAbilityInfo(
                              SKILL_TYPE_TRADESKILL
                            , skill_index
                            , ability_index
                            ) }
    if not info and info[1] then return end
    self._name         = info[1]
    self._is_purchased = info[6]
end

function RequiredSkill:FetchUpgradeInfo()
    if (self._have ~= nil and self._max ~= nil) then return end
                        -- Unable to fetch info about this skill for some
                        -- reason? Set fallbacksto ignore this requirement.
    self._have      = 0
    self._max       = 0
    self._is_maxxed = true

    local skill_index, ability_index = self:GetIndices()
    if not (skill_index and ability_index) then return end

    local have, max = GetSkillAbilityUpgradeInfo(
                              SKILL_TYPE_TRADESKILL
                            , skill_index
                            , ability_index
                            )
    if not (have and max) then return end
    self._have      = have
    self._max       = max
    self._is_maxxed = max <= have
end

function RequiredSkill:GetIndices()
    if not RequiredSkill.id_to_indices then
                        -- Lazy-fetch a table of every crafting skill.
        RequiredSkill.id_to_indices = RequiredSkill.FindAllSkills()
    end
    local r = RequiredSkill.id_to_indices[self.skill_id]
    if not r then
        d("WritWorthy: unable to find skill_id:"..tostring(self.skill_id))
        return nil, nil
    end
    return r.skill_index, r.ability_index
end

-- O(n) scan through all skills in an attempt to find all the ones
-- that we require.
--
-- +++ I would expect this nested loop to cause a noticeable frame stutter
-- +++ upon our first Sealed Master Writ. And yet, I don't really notice it.
-- +++ If I did, I could cache the 6 or 7 interesting rows in savedVariables.
--
function RequiredSkill.FindAllSkills()
    Log:StartNewEvent()
    local t = {}
    Log:Add("Scanning all skills...")
    local skill_type = SKILL_TYPE_TRADESKILL
    local num_lines = GetNumSkillLines(skill_type)
    Log:Add("t:"..tostring(skill_type).."  num_lines:"..tostring(num_lines))
    for skill_index = 1, num_lines do
        local num_abilities = GetNumSkillAbilities(skill_type, skill_index)
        Log:Add("t:"..tostring(skill_type).." i:"..tostring(skill_index)
            .."  num_abilities:"..tostring(num_abilities))
        for ability_index = 1, num_abilities do
            local info = { GetSkillAbilityInfo(skill_type, skill_index, ability_index) }
            local id   =   GetSkillAbilityId(skill_type, skill_index, ability_index, false)
            Log:Add("t i a:"..tostring(skill_type).." "..tostring(skill_index)
                .." "..tostring(ability_index)
                .." id:"..tostring(id)
                .." name:"..tostring(info[1])
                .." tex:"  ..tostring(info[2])
                .." earnedRank:"..tostring(info[3])
                .." passive:"..tostring(info[4])
                .." ultimate:"..tostring(info[5])
                .." purchased:"..tostring(info[6])
                .." progression:"..tostring(info[7])
                )
            t[id] = { id            = id
                    , name          = info[1]
                    , skill_index   = skill_index
                    , ability_index = ability_index
                    }
        end
    end
    return t
end


local R = WritWorthy.RequiredSkill  -- for less typing

R.BS_TEMPER_EXPERTISE = R:New(48168, "IsMaxxed"   ) -- 2, 6, Temper Expertise
R.CL_TEMPER_EXPERTISE = R:New(48198, "IsMaxxed"   ) -- 3, 6, Tannin Expertise
R.WW_TEMPER_EXPERTISE = R:New(48177, "IsMaxxed"   ) -- 6, 6, Resin Expertise
R.EN_ASPECT_GOLD      = R:New(46763, "IsMaxxed"   ) -- 4, 1, Aspect Improvement
R.PR_FOOD_4X          = R:New(44619, "IsMaxxed"   ) -- 5, 5, Chef
R.PR_DRINK_4X         = R:New(44624, "IsMaxxed"   ) -- 5, 6, Brewer
R.AL_POTION_4X        = R:New(45579, "IsMaxxed"   ) -- 1, 4, Chemistry
R.AL_LABORATORY_USE   = R:New(45555, "IsPurchased") -- 1, 5, Laboratory Use, 3 reagents

