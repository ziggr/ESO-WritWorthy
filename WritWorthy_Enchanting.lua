-- Parse a potion or poison request.

local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Util.lua

WritWorthy.Enchanting = {
    Glyphs = {} -- "Absorb Health" --> Glyph("Absorb Health", OKO, SUB)
}


local Enchanting = WritWorthy.Enchanting
local Fail       = WritWorthy.Util.Fail

-- Runes
Enchanting.REJERA   = { name="Rejera"  }
Enchanting.REPORA   = { name="Repora"  }
Enchanting.JEHADE   = { name="Jehade"  }
Enchanting.ITADE    = { name="Itade"   }
Enchanting.DEKEIPA  = { name="Dekeipa" }
Enchanting.DENI     = { name="Deni"    }
Enchanting.DENIMA   = { name="Denima"  }
Enchanting.DETERI   = { name="Deteri"  }
Enchanting.HAOKO    = { name="Haoko"   }
Enchanting.HAKEIJO  = { name="Hakeijo" }
Enchanting.KADERI   = { name="Kaderi"  }
Enchanting.KUOKO    = { name="Kuoko"   }
Enchanting.MAKDERI  = { name="Makderi" }
Enchanting.MAKKO    = { name="Makko"   }
Enchanting.MAKKOMA  = { name="Makkoma" }
Enchanting.MEIP     = { name="Meip"    }
Enchanting.OKO      = { name="Oko"     }
Enchanting.OKOMA    = { name="Okoma"   }
Enchanting.OKORI    = { name="Okori"   }
Enchanting.ORU      = { name="Oru"     }
Enchanting.RAKEIPA  = { name="Rakeipa" }
Enchanting.TADERI   = { name="Taderi"  }
Enchanting.REKUTA   = { name="Rekuta"  }
Enchanting.KUTA     = { name="Kuta"    }

local ADD   = "add"
local SUB   = "sub"
local CP150 = "CP150"
local CP160 = "CP160"

Enchanting.POTENCY_RUNES = {
    [ADD] = { [CP150] = Enchanting.REJERA
            , [CP160] = Enchanting.REPORA
            }
,   [SUB] = { [CP150] = Enchanting.JEHADE
            , [CP160] = Enchanting.ITADE
            }
}

Enchanting.ASPECT_RUNES = {
    ["Epic"]      = Enchanting.REKUTA
,   ["Legendary"] = Enchanting.KUTA
}


Enchanting.Glyph  = {}
function Enchanting.Glyph:New(name, essence_rune, add_sub)
    local o = {
        name         = name         -- "Absorb Health"
    ,   essence_rune = essence_rune -- OKO
    ,   add_sub      = add_sub      -- SUB
    }

                        -- Register this effect in our list of effects.
    Enchanting.Glyphs[name] = o

    setmetatable(o, self)
    self.__index = self
    return o
end

local Glyph = Enchanting.Glyph
local E = Enchanting -- for shorter tables

-- Fill Enchanting.Glyphs{} with instances that self-register
-- in their constructors.
--
--        glyph name                 essence        potency_type
-- armor
Glyph:New("Magicka"                , E.MAKKO      , ADD )
Glyph:New("Stamina"                , E.DENI       , ADD )
Glyph:New("Health"                 , E.OKO        , ADD )
Glyph:New("Prismatic Defense"      , E.HAKEIJO    , ADD )
-- weapons
Glyph:New("Flame"                  , E.RAKEIPA    , ADD )
Glyph:New("Decrease Health"        , E.OKOMA      , SUB )
Glyph:New("Weapon Damage"          , E.OKORI      , ADD )
Glyph:New("Foulness"               , E.HAOKO      , ADD )
Glyph:New("Poison"                 , E.KUOKO      , ADD )
Glyph:New("Frost"                  , E.DEKEIPA    , ADD )
Glyph:New("Shock"                  , E.MEIP       , ADD )
Glyph:New("Hardening"              , E.DETERI     , ADD )
Glyph:New("Crushing"               , E.DETERI     , SUB )
Glyph:New("Weakening"              , E.OKORI      , SUB )
Glyph:New("Absorb Health"          , E.OKO        , SUB )
Glyph:New("Absorb Stamina"         , E.DENI       , SUB )
Glyph:New("Absorb Magicka"         , E.MAKKO      , SUB )
Glyph:New("Prismatic Onslaught"    , E.HAKEIJO    , SUB )
-- jewelry
Glyph:New("Frost Resist"           , E.DEKEIPA    , SUB )
Glyph:New("Stamina Recovery"       , E.DENIMA     , ADD )
Glyph:New("Reduce Feat Cost"       , E.DENIMA     , SUB )
Glyph:New("Disease Resist"         , E.HAOKO      , SUB )
Glyph:New("Bashing"                , E.KADERI     , ADD )
Glyph:New("Shielding"              , E.KADERI     , SUB )
Glyph:New("Poison Resist"          , E.KUOKO      , SUB )
Glyph:New("Increase Magical Harm"  , E.MAKDERI    , ADD )
Glyph:New("Decrease Spell Harm"    , E.MAKDERI    , SUB )
Glyph:New("Magicka Recovery"       , E.MAKKOMA    , ADD )
Glyph:New("Reduce Spell Cost"      , E.MAKKOMA    , SUB )
Glyph:New("Shock Resist"           , E.MEIP       , SUB )
Glyph:New("Health Recovery"        , E.OKOMA      , ADD )
Glyph:New("Potion Boost"           , E.ORU        , ADD )
Glyph:New("Potion Speed"           , E.ORU        , SUB )
Glyph:New("Flame Resist"           , E.RAKEIPA    , SUB )
Glyph:New("Increase Physical Harm" , E.TADERI     , ADD )
Glyph:New("Decrease Physical Harm" , E.TADERI     , SUB )

Enchanting.Parser = {}
local Parser = Enchanting.Parser

function Parser:New()
    local o = {
        base_text       = nil   -- "Consume to start quest"
                                -- "\nCraft a Superb Glyph of Absorb Health;"
                                -- " Quality: Epic"
    ,   glyph           = nil   -- Glyph
    ,   aspect_rune     = nil   -- REKUTA
    ,   potency_rune    = nil   -- REJERA

    ,   mat_list        = {}    -- of MatRow
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Parser:ParseBaseText(base_text)
    self.base_text = base_text

    for key, aspect_rune in pairs(Enchanting.ASPECT_RUNES) do
        if base_text:find("Quality: "..key) then
            self.aspect_rune = aspect_rune
            break
        end
    end
    if not self.aspect_rune then return Fail("quality not found") end

    for key, glyph in pairs(Enchanting.Glyphs) do
        if base_text:find("Glyph of "..glyph.name) then
            self.glyph = glyph
        end
    end
    if not self.glyph then return Fail("glyph not found") end

                        -- Since string "Superb" appears in both
                        -- CP160 "Truly Superb" and CP150 "Superb",
                        -- search for "Truply Superb" first.
    local level_txt = nil
    if base_text:find("Truly Superb") then
        level_txt = CP160
    elseif base_text:find("Superb") then
        level_txt = CP150
    else
        return Fail("level not found")
    end
    self.potency_rune = Enchanting.POTENCY_RUNES[self.glyph.add_sub][level_txt]
    if not self.potency_rune then return Fail("potency not found "
        .." add_sub:"..tostring(self.glyph.add_sub)
        .." level_txt:"..tostring(level_txt)) end

    return self
end

function Parser:ToMatList()
    local MatRow = WritWorthy.MatRow
    local ml = {
            MatRow:FromName(self.potency_rune.name)
        ,   MatRow:FromName(self.glyph.essence_rune.name)
        ,   MatRow:FromName(self.aspect_rune.name)
    }
    return ml
end
