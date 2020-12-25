-- Do you have enough skill points in some crafting passive?

local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Define.lua
local WW = WritWorthy

WritWorthy.RequiredSkill = {}

local RequiredSkill = WritWorthy.RequiredSkill
local Log  = WritWorthy.Log
local Util = WritWorthy.Util

function RequiredSkill:New(function_name, skill_name_list, is_reduction)
    local o = {
        function_name   = function_name
    ,   skill_name_list = skill_name_list -- {en, es, fr, etc...}
    ,   _skill_index    = nil
    ,   _ability_index  = nil
    ,   _name           = nil
    ,   _is_purchased   = nil
    ,   _is_maxxed      = nil
    ,   _have           = nil
    ,   _max            = nil
    ,   _is_reduction   = is_reduction
    }
    setmetatable(o, self)
    self.__index = self

    RequiredSkill.ALL = RequiredSkill.ALL or {}
    table.insert(RequiredSkill.ALL, o)
    return o
end

function RequiredSkill.ResetCache()
    for _,r in ipairs(RequiredSkill.ALL or {}) do
        r._name           = nil
        r._is_purchased   = nil
        r._is_maxxed      = nil
        r._have           = nil
        r._max            = nil
    end
end

function RequiredSkill:ToKnow()
    local how = WritWorthy.Know.KNOW.SKILL_REQUIRED
    if self._is_reduction then
        how = WritWorthy.Know.KNOW.SKILL_COST_REDUCTION
    end
    if self.function_name == "IsMaxxed" then
        local known = self:IsKnown()
        local text  = string.format( WW.Str("know_err_skill_not_maxed")
                                   , self:Name()
                                   , self._have or -1
                                   , self._max or -1
                                   )
        return WritWorthy.Know:New(
            { name     = "Skill: "..self:Name()
            , is_known = known
            , lack_msg = text
            , how      = how
            })
    else
        local known = self:IsKnown()
        local text  = string.format(WW.Str("know_err_skill_missing"), self:Name())
        return WritWorthy.Know:New({ name = "Skill: "..self:Name()
                                   , is_known = known
                                   , lack_msg = text
                                   , how      = how
                                   })
    end
end

function RequiredSkill:IsKnown()
    return self[self.function_name](self) -- and false
end

-- This lazy-fetch and then latch idiom means that if the player acquires the
-- skill after we latch, only a /reloadui will update us. I'm fine with that. I
-- don't feel like wasting network time polling the server every time we need a
-- tooltip, especially when called in a loop for WritWorthyInventoryList.

function RequiredSkill:Name()
    if self._name == nil then
        self:FetchInfo()
    end
    return Util.decaret(self._name) or "?"
end

function RequiredSkill:IsPurchased()
    if self._is_purchsed == nil then
        self:FetchInfo()            -- For localized name and purchased state
    end
    return self._is_purchased
end

function RequiredSkill:IsMaxxed()
    if self._is_maxxed == nil then
        self:FetchInfo()            -- For localized name
        self:FetchUpgradeInfo()     -- for 3/3 skill rank
    end
    return self._is_maxxed
end

function RequiredSkill:FetchInfo()
    if self._name and (self._is_purchased ~= nil) then return end

                        -- Unable to fetch info about this skill for some
                        -- reason? Set fallbacks to ignore this requirement.
    self._name         = self.skill_name_list[1]
    self._is_purchased = true

    local skill_index, ability_index = self:GetIndices()
    if not (skill_index and ability_index) then return end
    local info = { GetSkillAbilityInfo(
                              SKILL_TYPE_TRADESKILL
                            , skill_index
                            , ability_index
                            ) }
    if not (info and info[1]) then return end
    self._name         = info[1]
    self._is_purchased = info[6]
end

function RequiredSkill:FetchUpgradeInfo()
    if (self._have ~= nil and self._max ~= nil) then return end
                        -- Unable to fetch info about this skill for some
                        -- reason? Set fallbacks to ignore this requirement.
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
    if (self._skill_index and self._ability_index) then
        return self._skill_index, self._ability_index
    end

    if not RequiredSkill.name_to_indices then
                        -- Lazy-fetch a table of every crafting skill.
        RequiredSkill.name_to_indices = RequiredSkill.FindAllSkills()
    end

    for _,name in ipairs(self.skill_name_list) do
        local r = RequiredSkill.name_to_indices[Util.decaret(name)]
        if r then
            self._skill_index   = r.skill_index
            self._ability_index = r.ability_index
            break
        end
    end
    if not self._skill_index and self._ability_index then
        d("WritWorthy: unable to find skill indices for name:"..tostring(self.skill_name_list[1]))
    end
    return  self._skill_index, self._ability_index
end

-- O(n) scan through all skills in an attempt to find all the ones
-- that we require.
--
-- +++ I would expect this nested loop to cause a noticeable frame stutter
-- +++ upon our first Sealed Master Writ. And yet, I don't really notice it.
-- +++ If I did, I could cache the 6 or 7 interesting rows in savedVariables.
--
function RequiredSkill.FindAllSkills()
    Log:StartNewEvent("FindAllSkills")
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
            local name = info[1]
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
            t[Util.decaret(name)] = { id            = id
                                    , name          = info[1]
                                    , skill_index   = skill_index
                                    , ability_index = ability_index
                                    }
        end
    end
    Log:EndEvent()
    return t
end


local R = WritWorthy.RequiredSkill  -- for less typing

R.BS_TEMPER_EXPERTISE = R:New("IsMaxxed"   , {"Temper Expertise"   , "Härterkenntnis"    , "Expertise de la trempe^f"    }, true )
R.CL_TEMPER_EXPERTISE = R:New("IsMaxxed"   , {"Tannin Expertise"   , "Gerberkunde"       , "Expertise en tanins^f"       }, true )
R.WW_TEMPER_EXPERTISE = R:New("IsMaxxed"   , {"Resin Expertise"    , "Harzkenntnis"      , "Expertise en résines^f"      }, true )
R.JW_TEMPER_EXPERTISE = R:New("IsMaxxed"   , {"Platings Expertise"                                                       }, true )
R.EN_ASPECT_GOLD      = R:New("IsMaxxed"   , {"Aspect Improvement" , "Aspektverbesserung", "Amélioration d'aspect^f"     }       )
R.PR_FOOD_4X          = R:New("IsMaxxed"   , {"Chef"               , "Kochkunst"         , "Chef^m"                      }, true )
R.PR_DRINK_4X         = R:New("IsMaxxed"   , {"Brewer"             , "Braukunst"         , "Brasserie^f"                 }, true )
R.AL_POTION_4X        = R:New("IsMaxxed"   , {"Chemistry"          , "Chemie"            , "Chimie"                      }, true )
R.AL_LABORATORY_USE   = R:New("IsPurchased", {"Laboratory Use"     , "Laborkenntnis"     , "Utilisation du laboratoire^f"})

R = nil

-- ESO API lacks a constant for each skill. skill_index+ability_index varies
-- from player to player. skill_id varies from character to character.
-- The closest things we have are either icon and name. Name is user-visible
-- and changes from language to language.
--
-- [44] = "t i a:8 6 6 id:48175 name:Resin Expertise    tex:/esoui/art/icons/ability_tradecraft_001.dds  earnedRank:10 passive:true ultimate:false purchased:false progression:nil",
-- [36] = "t i a:8 5 6 id:44620 name:Brewer             tex:/esoui/art/icons/ability_provisioner_003.dds earnedRank:9  passive:true ultimate:false purchased:false progression:nil",
-- [35] = "t i a:8 5 5 id:44616 name:Chef               tex:/esoui/art/icons/ability_provisioner_002.dds earnedRank:7  passive:true ultimate:false purchased:false progression:nil",
-- [25] = "t i a:8 4 1 id:46758 name:Aspect Improvement tex:/esoui/art/icons/ability_enchanter_002b.dds  earnedRank:1  passive:true ultimate:false purchased:true  progression:nil",
-- [23] = "t i a:8 3 6 id:48196 name:Tannin Expertise   tex:/esoui/art/icons/ability_tradecraft_004.dds  earnedRank:10 passive:true ultimate:false purchased:false progression:nil",
-- [16] = "t i a:8 2 6 id:48166 name:Temper Expertise   tex:/esoui/art/icons/ability_smith_004.dds       earnedRank:10 passive:true ultimate:false purchased:false progression:nil",
-- [ 8] = "t i a:8 1 5 id:45555 name:Laboratory Use     tex:/esoui/art/icons/ability_alchemy_002.dds     earnedRank:15 passive:true ultimate:false purchased:true  progression:nil",
-- [ 7] = "t i a:8 1 4 id:45577 name:Chemistry          tex:/esoui/art/icons/ability_alchemy_006.dds     earnedRank:12 passive:true ultimate:false purchased:false progression:nil",
