-- Parse a potion or poison request.

local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Util.lua

WritWorthy.Enchanting = {
    Glyphs = {} -- "Absorb Health"  --> Glyph("Absorb Health", OKO, SUB)
                -- 43573 (glyph_id) --> same
}


local Enchanting = WritWorthy.Enchanting
local Util       = WritWorthy.Util
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
            , [207]   = Enchanting.REJERA
            , [225]   = Enchanting.REPORA
            }
,   [SUB] = { [CP150] = Enchanting.JEHADE
            , [CP160] = Enchanting.ITADE
            , [207]   = Enchanting.JEHADE
            , [225]   = Enchanting.ITADE
            }
}

Enchanting.ASPECT_RUNES = {
    ["Epic"]      = Enchanting.REKUTA
,   ["Legendary"] = Enchanting.KUTA
,   [4]           = Enchanting.REKUTA
,   [5]           = Enchanting.KUTA
}


Enchanting.Glyph  = {}
function Enchanting.Glyph:New(name, essence_rune, add_sub, glyph_id)
    local o = {
        name         = name         -- "Absorb Health"
    ,   essence_rune = essence_rune -- OKO
    ,   add_sub      = add_sub      -- SUB
    ,   glyph_id     = glyph_id
    }

                        -- Register this effect in our list of effects.
    Enchanting.Glyphs[name]     = o
    Enchanting.Glyphs[glyph_id] = o

    setmetatable(o, self)
    self.__index = self
    return o
end

local Glyph = Enchanting.Glyph
local E = Enchanting -- for shorter tables

-- Fill Enchanting.Glyphs{} with instances that self-register
-- in their constructors.
--
-- Glyph item_ids from CraftStore internal tables.
--
--        glyph name                 essence        potency_type  glyph
--                                                                item_id
-- armor
Glyph:New("Magicka"                , E.MAKKO      , ADD ,         26582 )
Glyph:New("Stamina"                , E.DENI       , ADD ,         26588 )
Glyph:New("Health"                 , E.OKO        , ADD ,         26580 )
Glyph:New("Prismatic Defense"      , E.HAKEIJO    , ADD ,         68343 )
-- weapons
Glyph:New("Flame"                  , E.RAKEIPA    , ADD ,         26848 )
Glyph:New("Decrease Health"        , E.OKOMA      , SUB ,         45869 )
Glyph:New("Weapon Damage"          , E.OKORI      , ADD ,         54484 )
Glyph:New("Foulness"               , E.HAOKO      , ADD ,         26841 )
Glyph:New("Poison"                 , E.KUOKO      , ADD ,         26587 )
Glyph:New("Frost"                  , E.DEKEIPA    , ADD ,          5365 )
Glyph:New("Shock"                  , E.MEIP       , ADD ,         26844 )
Glyph:New("Hardening"              , E.DETERI     , ADD ,          5366 )
Glyph:New("Crushing"               , E.DETERI     , SUB ,         26845 )
Glyph:New("Weakening"              , E.OKORI      , SUB ,         26591 )
Glyph:New("Absorb Health"          , E.OKO        , SUB ,         43573 )
Glyph:New("Absorb Stamina"         , E.DENI       , SUB ,         45867 )
Glyph:New("Absorb Magicka"         , E.MAKKO      , SUB ,         45868 )
Glyph:New("Prismatic Onslaught"    , E.HAKEIJO    , SUB ,         68344 )
-- jewelry
Glyph:New("Frost Resist"           , E.DEKEIPA    , SUB ,          5364 )
Glyph:New("Stamina Recovery"       , E.DENIMA     , ADD ,         26589 )
Glyph:New("Reduce Feat Cost"       , E.DENIMA     , SUB ,         45871 )
Glyph:New("Disease Resist"         , E.HAOKO      , SUB ,         26847 )
Glyph:New("Bashing"                , E.KADERI     , ADD ,         45872 )
Glyph:New("Shielding"              , E.KADERI     , SUB ,         45873 )
Glyph:New("Poison Resist"          , E.KUOKO      , SUB ,         26586 )
Glyph:New("Increase Magical Harm"  , E.MAKDERI    , ADD ,         45884 )
Glyph:New("Decrease Spell Harm"    , E.MAKDERI    , SUB ,         45886 )
Glyph:New("Magicka Recovery"       , E.MAKKOMA    , ADD ,         26583 )
Glyph:New("Reduce Spell Cost"      , E.MAKKOMA    , SUB ,         45870 )
Glyph:New("Shock Resist"           , E.MEIP       , SUB ,         43570 )
Glyph:New("Health Recovery"        , E.OKOMA      , ADD ,         26581 )
Glyph:New("Potion Boost"           , E.ORU        , ADD ,         45874 )
Glyph:New("Potion Speed"           , E.ORU        , SUB ,         45875 )
Glyph:New("Flame Resist"           , E.RAKEIPA    , SUB ,         26849 )
Glyph:New("Increase Physical Harm" , E.TADERI     , ADD ,         45883 )
Glyph:New("Decrease Physical Harm" , E.TADERI     , SUB ,         45885 )

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

function Parser:ParseItemLink(item_link)
    local fields      = Util.ToWritFields(item_link)
    local glyph_id    = fields.writ1
    local level_num   = fields.writ2
    local quality_num = fields.writ3

    self.glyph        = Enchanting.Glyphs[glyph_id]
    self.potency_rune = Enchanting.POTENCY_RUNES[self.glyph.add_sub][level_num]
    self.aspect_rune  = Enchanting.ASPECT_RUNES[quality_num]

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
