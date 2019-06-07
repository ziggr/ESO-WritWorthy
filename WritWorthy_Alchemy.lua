-- Parse an alchemy request

local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Define.lua

WritWorthy.Alchemy = {
    Effects  = {} -- "Speed" --> SPEED
,   Reagents = {} -- "Luminous Russula" --> LUMINOUS_RUSSULA
}

local Alchemy = WritWorthy.Alchemy
local Util    = WritWorthy.Util
local Fail    = WritWorthy.Util.Fail
local Log     = WritWorthy.Log

WritWorthy.Alchemy.Effect  = {}
WritWorthy.Alchemy.Reagent = {}
local Effect  = WritWorthy.Alchemy.Effect
local Reagent = WritWorthy.Alchemy.Reagent

-- I'm not a fan of constructors that do more than construct a single instance.
--
-- But it is handy here to let this constructor also interconnect two negating
-- effects, as well as register this effect in Alchemy.Effect{}

function Effect:New(effect_id, name, negates)
    local o = {
        effect_id = effect_id  -- 23
    ,   name      = name       -- "Speed"
    ,   negates   = nil        -- HINDER
    ,   reagents  = {}         -- { "Blessed Thistle" --> BLESSED_THISTLE
                               -- , "Namira's Rot"    --> NAMIRAS_ROT
                               -- , "Scrib Jelly"     --> SCRIB_JELLY
                               -- , }
    }

                        -- Register this effect in our list of effects.
    Alchemy.Effects[name]      = o
    Alchemy.Effects[effect_id] = o

                        -- Interconnect two negating effects
    if negates then
        o.negates = negates
        negates.negates = o
    end

    setmetatable(o, self)
    self.__index = self
    return o
end

function Reagent:New(name, effects)
    local o = {
        name    = name    -- "Luminous Russula"
    ,   effects = {}      -- { "Ravage Stamina" --> RAVAGE_STAMINA
                          -- , "Restore Health" --> RESTORE_HEALTH
                          -- , "Maim"           --> MAIM
                          -- , "Hindrance"      --> HINDRANCE
                          -- }
    }

                          -- Register
    Alchemy.Reagents[name] = o

                           -- Interconnect Effect <-> Reagents
    for _,effect in pairs(effects) do
        o.effects[effect.name] = effect
        effect.reagents[o.name] = o
    end

    setmetatable(o, self)
    self.__index = self
    return o
end

-- Connect each Effect's pointer to us as a Reagent
function Reagent:Connect()
    for _, effect in ipairs(self.effects) do
        table.insert(effect.reagents, self)
    end
end

-- Return the number of requested effects that this reagent includes.
function Reagent:EffectCount(effect1, effect2, effect3)
    local ct = 0
    if self.effects[effect1.name] then ct = ct + 1 end
    if self.effects[effect2.name] then ct = ct + 1 end
    if self.effects[effect3.name] then ct = ct + 1 end
    return ct
end

-- Return the number of supplied reagents that include this effect.
function Effect:ReagentCount(reagent1, reagent2, reagent3)
    local ct = 0
    if self.reagents[reagent1.name] then ct = ct + 1 end
    if self.reagents[reagent2.name] then ct = ct + 1 end
    if self.reagents[reagent3.name] then ct = ct + 1 end
    return ct
end

-- Is this effect possible with these reagents?
-- Requires 2+ effect and no negation
function Effect:Possible(reagent1, reagent2, reagent3)
    local ct = 0
    if self.reagents[reagent1.name] then ct = ct + 1 end
    if self.reagents[reagent2.name] then ct = ct + 1 end
    if self.reagents[reagent3.name] then ct = ct + 1 end
    if ct < 2 then return false end

    local negate_name = self.negates.name
    if     reagent1.effects[negate_name]
        or reagent2.effects[negate_name]
        or reagent3.effects[negate_name] then
        return false
    end

    return ct
end

local A = Alchemy       -- For shorter tables

-- Effects and Reagents are interconnected.
-- First forward-declare the effects with actual symbol names so that we can
-- directly connect to them as we build this table.
--
-- instance                            name              negates (only need 1 of the 2)
A.BREACH                = Effect:New(  8, "Breach"                                          )
A.COWARDICE             = Effect:New( 12, "Cowardice"                                       )
A.DEFILE                = Effect:New( 30, "Defile"                                          )
A.DETECTION             = Effect:New( 21, "Detection"                                       )
A.ENERVATION            = Effect:New( 18, "Enervation"                                      )
A.ENTRAPMENT            = Effect:New( 20, "Entrapment"                                      )
A.FRACTURE              = Effect:New( 10, "Fracture"                                        )
A.GRADUAL_RAVAGE_HEALTH = Effect:New( 28, "Gradual Ravage Health"                           )
A.HINDRANCE             = Effect:New( 24, "Hindrance"                                       )
A.INCREASE_ARMOR        = Effect:New(  9, "Increase Armor"        , A.FRACTURE              )
A.INCREASE_SPELL_POWER  = Effect:New( 11, "Increase Spell Power"  , A.COWARDICE             )
A.INCREASE_SPELL_RESIST = Effect:New(  7, "Increase Spell Resist" , A.BREACH                )
A.INCREASE_WEAPON_POWER = Effect:New( 13, "Increase Weapon Power"                           )
A.INVISIBLE             = Effect:New( 22, "Invisible"             , A.DETECTION             )
A.LINGERING_HEALTH      = Effect:New( 27, "Lingering Health"      , A.GRADUAL_RAVAGE_HEALTH )
A.MAIM                  = Effect:New( 14, "Maim"                  , A.INCREASE_WEAPON_POWER )
A.PROTECTION            = Effect:New( 25, "Protection"                                      )
A.RAVAGE_HEALTH         = Effect:New(  2, "Ravage Health"                                   )
A.RAVAGE_MAGICKA        = Effect:New(  4, "Ravage Magicka"                                  )
A.RAVAGE_STAMINA        = Effect:New(  6, "Ravage Stamina"                                  )
A.RESTORE_HEALTH        = Effect:New(  1, "Restore Health"        , A.RAVAGE_HEALTH         )
A.RESTORE_MAGICKA       = Effect:New(  3, "Restore Magicka"       , A.RAVAGE_MAGICKA        )
A.RESTORE_STAMINA       = Effect:New(  5, "Restore Stamina"       , A.RAVAGE_STAMINA        )
A.SPEED                 = Effect:New( 23, "Speed"                 , A.HINDRANCE             )
A.SPELL_CRITICAL        = Effect:New( 15, "Spell Critical"                                  )
A.UNCERTAINTY           = Effect:New( 16, "Uncertainty"           , A.SPELL_CRITICAL        )
A.UNSTOPPABLE           = Effect:New( 19, "Unstoppable"           , A.ENTRAPMENT            )
A.VITALITY              = Effect:New( 29, "Vitality"              , A.DEFILE                )
A.VULNERABILITY         = Effect:New( 26, "Vulnerability"         , A.PROTECTION            )
A.WEAPON_CRITICAL       = Effect:New( 17, "Weapon Critical"       , A.ENERVATION            )

-- Reagents
A.BLESSED_THISTLE  = Reagent:New("Blessed Thistle" , { A.RESTORE_STAMINA       , A.INCREASE_WEAPON_POWER , A.RAVAGE_HEALTH        , A.SPEED             } )
A.BLUE_ENTOLOMA    = Reagent:New("Blue Entoloma"   , { A.RAVAGE_MAGICKA        , A.COWARDICE             , A.RESTORE_HEALTH       , A.INVISIBLE         } )
A.BUGLOSS          = Reagent:New("Bugloss"         , { A.INCREASE_SPELL_RESIST , A.COWARDICE             , A.RESTORE_HEALTH       , A.RESTORE_MAGICKA   } )
A.COLUMBINE        = Reagent:New("Columbine"       , { A.RESTORE_HEALTH        , A.RESTORE_STAMINA       , A.RESTORE_MAGICKA      , A.UNSTOPPABLE       } )
A.CORN_FLOWER      = Reagent:New("Corn Flower"     , { A.RESTORE_MAGICKA       , A.RAVAGE_HEALTH         , A.INCREASE_SPELL_POWER , A.DETECTION         } )
A.DRAGONTHORN      = Reagent:New("Dragonthorn"     , { A.INCREASE_WEAPON_POWER , A.FRACTURE              , A.RESTORE_STAMINA      , A.WEAPON_CRITICAL   } )
A.EMETIC_RUSSULA   = Reagent:New("Emetic Russula"  , { A.RAVAGE_HEALTH         , A.RAVAGE_STAMINA        , A.RAVAGE_MAGICKA       , A.ENTRAPMENT        } )
A.IMP_STOOL        = Reagent:New("Imp Stool"       , { A.MAIM                  , A.INCREASE_ARMOR        , A.RAVAGE_STAMINA       , A.ENERVATION        } )
A.LADYS_SMOCK      = Reagent:New("Lady's Smock"    , { A.INCREASE_SPELL_POWER  , A.BREACH                , A.RESTORE_MAGICKA      , A.SPELL_CRITICAL    } )
A.LUMINOUS_RUSSULA = Reagent:New("Luminous Russula", { A.RAVAGE_STAMINA        , A.RESTORE_HEALTH        , A.MAIM                 , A.HINDRANCE         } )
A.MOUNTAIN_FLOWER  = Reagent:New("Mountain flower" , { A.INCREASE_ARMOR        , A.MAIM                  , A.RESTORE_HEALTH       , A.RESTORE_STAMINA   } )
A.NAMIRAS_ROT      = Reagent:New("Namira's Rot"    , { A.SPELL_CRITICAL        , A.INVISIBLE             , A.SPEED                , A.UNSTOPPABLE       } )
A.NIRNROOT         = Reagent:New("Nirnroot"        , { A.RAVAGE_HEALTH         , A.ENERVATION            , A.UNCERTAINTY          , A.INVISIBLE         } )
A.STINKHORN        = Reagent:New("Stinkhorn"       , { A.FRACTURE              , A.INCREASE_WEAPON_POWER , A.RAVAGE_HEALTH        , A.RAVAGE_STAMINA    } )
A.VIOLET_COPRINUS  = Reagent:New("Violet Coprinus" , { A.BREACH                , A.INCREASE_SPELL_POWER  , A.RAVAGE_HEALTH        , A.RAVAGE_MAGICKA    } )
A.WATER_HYACINTH   = Reagent:New("Water Hyacinth"  , { A.RESTORE_HEALTH        , A.WEAPON_CRITICAL       , A.SPELL_CRITICAL       , A.ENTRAPMENT        } )
A.WHITE_CAP        = Reagent:New("White Cap"       , { A.COWARDICE             , A.INCREASE_SPELL_RESIST , A.RAVAGE_MAGICKA       , A.DETECTION         } )
A.WORMWOOD         = Reagent:New("Wormwood"        , { A.WEAPON_CRITICAL       , A.DETECTION             , A.HINDRANCE            , A.UNSTOPPABLE       } )
A.BEETLE_SCUTTLE   = Reagent:New("Beetle Scuttle"  , { A.BREACH                , A.PROTECTION            , A.INCREASE_ARMOR       , A.VITALITY          } )
A.BUTTERFLY_WING   = Reagent:New("Butterfly Wing"  , { A.RESTORE_HEALTH        , A.LINGERING_HEALTH      , A.UNCERTAINTY          , A.VITALITY          } )
A.FLESHFLY_LARVA   = Reagent:New("Fleshfly Larva"  , { A.RAVAGE_STAMINA        , A.GRADUAL_RAVAGE_HEALTH , A.VULNERABILITY        , A.VITALITY          } )
A.MUDCRAB_CHITIN   = Reagent:New("Mudcrab Chitin"  , { A.INCREASE_SPELL_RESIST , A.PROTECTION            , A.INCREASE_ARMOR       , A.DEFILE            } )
A.NIGHTSHADE       = Reagent:New("Nightshade"      , { A.RAVAGE_HEALTH         , A.GRADUAL_RAVAGE_HEALTH , A.PROTECTION           , A.DEFILE            } )
A.SCRIB_JELLY      = Reagent:New("Scrib Jelly"     , { A.RAVAGE_MAGICKA        , A.VULNERABILITY         , A.SPEED                , A.LINGERING_HEALTH  } )
A.SPIDER_EGG       = Reagent:New("Spider Egg"      , { A.HINDRANCE             , A.LINGERING_HEALTH      , A.INVISIBLE            , A.DEFILE            } )
A.TORCHBUG_THORAX  = Reagent:New("Torchbug Thorax" , { A.FRACTURE              , A.DETECTION             , A.ENERVATION           , A.VITALITY          } )

-- If a permutation of three reagents produces the requested three effects,
-- return true. If not, false.
function Alchemy.Winner( effect1,  effect2,  effect3
                       , reagent1, reagent2, reagent3 )
                        -- Reagents appear in both pool1 and pool23, so expect
                        -- and skip duplicates. We MUST include pool1's
                        -- reagents in pool23 because sometimes the only
                        -- winning combination requires two from pool1.
    if reagent1 == reagent2
        or reagent2 == reagent3
        or reagent3 == reagent1 then
        return false
    end

    -- d("Testing r3: "..reagent1.name .." + ".. reagent2.name .." + ".. reagent3.name
    --  .. " " .. effect1.name ..":" ..tostring(effect1:Possible( reagent1, reagent2, reagent3 ))
    --  .. " " .. effect2.name ..":" ..tostring(effect2:Possible( reagent1, reagent2, reagent3 ))
    --  .. " " .. effect3.name ..":" ..tostring(effect3:Possible( reagent1, reagent2, reagent3 ))
    --  )
    if      effect1:Possible( reagent1, reagent2, reagent3 )
        and effect2:Possible( reagent1, reagent2, reagent3 )
        and effect3:Possible( reagent1, reagent2, reagent3 ) then
        -- d("WINNER: " .. reagent1.name .." + ".. reagent2.name .." + ".. reagent3.name)
        return true
    end
    return false
end

-- Return a list of three reagents, sorted by name
function Alchemy.NameLessThan(a, b)
    if a and b then
        return a.name < b.name
    end
    if b then           -- nil < non-nil
        return true
    end
    if a then           -- non-nil > nil
        return false
    end
    return false        -- nil == nil
end

-- A "reagent_three" or "r3" is a 3-tuple of Reagent.

function Alchemy.ToReagentThreeList(effect1, effect2, effect3)
    -- First reagent must have effect1.
    local pool1 = {}
    -- d("Effects: 1:"..effect1.name.."   2:"..effect2.name.."   3:"..effect3.name)
    for _, reagent in pairs(effect1.reagents) do
        pool1[reagent.name] = reagent
        -- d("Pool1: " .. reagent.name )
    end

    -- Second and third reagents must have any of the three effects.
    local pool23 = {}
    for _, reagents in pairs({ effect1.reagents
                             , effect2.reagents
                             , effect3.reagents
                             }) do
        for _, reagent in pairs(reagents) do
            pool23[reagent.name] = reagent
            -- d("Pool23: " .. reagent.name )
        end
    end

    local r3list = {}
    local seen   = {}
    for _, reagent1 in pairs(pool1) do
        for i, reagent2 in pairs(pool23) do
            for j, reagent3 in pairs(pool23) do
                if i < j then   -- avoid duplicate work between 2+3
                    -- Avoid different permuations of the same 3 reagents
                    -- by canonicalizing their names into a single sorted
                    -- sequence and using that as the insertion key
                    -- for the resulting r3list.
                    local rnames = { reagent1.name
                                   , reagent2.name
                                   , reagent3.name
                                   }
                    table.sort(rnames)
                    rkey = rnames[1] .."+".. rnames[2] .."+".. rnames[3]
                    if not seen[rkey] then
                        seen[rkey] = true
                        if Alchemy.Winner( effect1,  effect2,  effect3
                                         , reagent1, reagent2, reagent3 ) then
                                    -- Sorting here not required, just makes
                                    -- display a bit tidier.
                            local r3 = { reagent1, reagent2, reagent3 }
                            table.sort(r3, Alchemy.NameLessThan)
                            Log:Add("r3list:"..r3[1].name
                                       .."  "..r3[2].name
                                       .."  "..r3[3].name)
                            table.insert(r3list, r3 )
                        end
                    end
                end
            end
        end
    end
    return r3list
end

-- Parser ====================================================================

Alchemy.Parser = {
    class = "alchemy"
}
local Parser = Alchemy.Parser

function Parser:New()
    local o = {
        is_poison       = nil   -- if false, "Potion". If true, "Poison"
    ,   effects         = {}    -- { VITALITY, INCREASE_ARMOR, RAVAGE_STAMINA }
    ,   r3list          = {}    -- { list of { Reagent 3-tuple }, { Reagent 3-tuple} ... }
    ,   mat_list        = {}    -- of MatRow
    ,   crafting_type   = CRAFTING_TYPE_ALCHEMY
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Parser:ParseItemLink(item_link)
    Log:StartNewEvent("ParseItemLink: %s %s", self.class, item_link)
    local fields      = Util.ToWritFields(item_link)
    local solvent_id  = fields.writ1
    self.is_poison    = solvent_id == 239 -- Lorkhan's Tears
    local log_t = {}
    log_t.solvent_id = solvent_id
    log_t.is_poison  = self.is_poison
    log_t.effects    = {}
    for i, effect_id in ipairs({ fields.writ2
                               , fields.writ3
                               , fields.writ4 }) do
        local effect = Alchemy.Effects[effect_id]
        if not effect then
            return Fail("Unknown potion effect:"..tostring(effect_id))
        end
        log_t.effects[i] = tostring(effect_id).." "..tostring(effect.name)
        table.insert(self.effects, effect)
    end
    log_t.effects = Log:Flatten("",log_t.effects)
    Log:Add(log_t)
    self.r3list = Alchemy.ToReagentThreeList( self.effects[1]
                                            , self.effects[2]
                                            , self.effects[3]
                                            )
    return self
end


function Parser:GetRequiredCraftCt()
                -- Update 21/4.3.0/100026/Wrathbone 2019-01 reduced
                -- required potion/poison counts.
                --
                -- 20x potions or poisons before 4.3.0
                -- 16x potions or poisons after.
    local api_version = GetAPIVersion()
    local result_ct   = 20
    if 100026 <= api_version then
        result_ct = 16
    end

    local result_per_craft = 4
    if self.is_poison then result_per_craft = 16 end
    return math.ceil(result_ct / result_per_craft)
end

function Parser:ToMatList()
    -- d("self.r3list ct:"..tostring(#self.r3list))

                        -- Find the cheapest of multiple possible 3-tuples.
    local MatRow = WritWorthy.MatRow
    local min_gold = 9999999999
    local min_r3   = nil
    local mat_ct   = self:GetRequiredCraftCt()
    for _, r3 in pairs(self.r3list) do
        r3[1].mat = MatRow:FromName(r3[1].name, mat_ct)
        r3[2].mat = MatRow:FromName(r3[2].name, mat_ct)
        r3[3].mat = MatRow:FromName(r3[3].name, mat_ct)

                        -- If we cannot get MM prices, then WHICH three
                        -- reagents we pick doesn't really matter. We're done
                        -- trying to find the cheapest.
        local mat_list = { r3[1].mat, r3[2].mat, r3[3].mat }
        local mat_total = MatRow.ListTotal(mat_list)
        if not mat_total then
            Log:Add("no total")
            min_gold = WritWorthy.GOLD_UNKNOWN
            min_r3   = r3
            break
        end
                        -- If we can get MM prices, keep checking for the
                        -- cheapest combination of three reagents.
        if mat_total and min_gold and mat_total < min_gold then
            min_gold = mat_total
            min_r3   = r3
        end
    end
                        -- Return materials for one batch of potion or poison.
    self.mat_list = {}
    if self.is_poison then
        table.insert(self.mat_list, MatRow:FromName("Alkahest", mat_ct))
    else
        table.insert(self.mat_list, MatRow:FromName("Lorkhan's Tears", mat_ct))
    end
    table.insert(self.mat_list, min_r3[1].mat)
    table.insert(self.mat_list, min_r3[2].mat)
    table.insert(self.mat_list, min_r3[3].mat)

    return self.mat_list
end

function Parser:ToKnowList()
    Log:StartNewEvent("ToKnowList: %s", self.class)
    local three_reagents = WritWorthy.RequiredSkill.AL_LABORATORY_USE:ToKnow()
    local four_pots_per  = WritWorthy.RequiredSkill.AL_POTION_4X:ToKnow()
    four_pots_per.is_warn = true
    local r = { three_reagents, four_pots_per }
    return r
end

-- From Dolgubon's LLC functions.lua
local function GetItemIDFromLink(itemLink) return tonumber(string.match(itemLink,"|H%d:item:(%d+)")) end

function Parser:ToDolRequest(unique_id)
    local mat_list = self:ToMatList()
    local o = {}
    o[1] = GetItemIDFromLink(mat_list[1].link) -- solvent
    o[2] = GetItemIDFromLink(mat_list[2].link) -- reagent1
    o[3] = GetItemIDFromLink(mat_list[3].link) -- reagent2
    o[4] = GetItemIDFromLink(mat_list[4].link) -- reagent3 (optional, nilable)
    o[5] = mat_list[1].ct                      -- timesToMake
    o[6] = true                                -- autocraft
    o[7] = unique_id                           -- reference
    return { ["function"       ] = "CraftAlchemyItemId"
           , ["args"           ] = o
           }
end
