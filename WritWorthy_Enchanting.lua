-- Parse a potion or poison request.

local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Define.lua

WritWorthy.Enchanting = {
    Glyphs = {} -- "Absorb Health"  --> Glyph("Absorb Health", OKO, SUB)
                -- 43573 (glyph_id) --> same
}

local Enchanting = WritWorthy.Enchanting
local Util       = WritWorthy.Util
local Fail       = WritWorthy.Util.Fail

-- Runes
Enchanting.REJERA   = { name="Rejera"  , item_id = 64509 }
Enchanting.REPORA   = { name="Repora"  , item_id = 68341 }
Enchanting.JEHADE   = { name="Jehade"  , item_id = 64508 }
Enchanting.ITADE    = { name="Itade"   , item_id = 68340 }
Enchanting.DEKEIPA  = { name="Dekeipa" , item_id = 45839 }
Enchanting.DENI     = { name="Deni"    , item_id = 45833 }
Enchanting.DENIMA   = { name="Denima"  , item_id = 45836 }
Enchanting.DETERI   = { name="Deteri"  , item_id = 45842 }
Enchanting.HAOKO    = { name="Haoko"   , item_id = 45841 }
Enchanting.HAKEIJO  = { name="Hakeijo" , item_id = 68342 }
Enchanting.KADERI   = { name="Kaderi"  , item_id = 45849 }
Enchanting.KUOKO    = { name="Kuoko"   , item_id = 45837 }
Enchanting.MAKDERI  = { name="Makderi" , item_id = 45848 }
Enchanting.MAKKO    = { name="Makko"   , item_id = 45832 }
Enchanting.MAKKOMA  = { name="Makkoma" , item_id = 45835 }
Enchanting.MEIP     = { name="Meip"    , item_id = 45840 }
Enchanting.OKO      = { name="Oko"     , item_id = 45831 }
Enchanting.OKOMA    = { name="Okoma"   , item_id = 45834 }
Enchanting.OKORI    = { name="Okori"   , item_id = 45843 }
Enchanting.ORU      = { name="Oru"     , item_id = 45846 }
Enchanting.RAKEIPA  = { name="Rakeipa" , item_id = 45838 }
Enchanting.TADERI   = { name="Taderi"  , item_id = 45847 }
Enchanting.REKUTA   = { name="Rekuta"  , item_id = 45853 }
Enchanting.KUTA     = { name="Kuta"    , item_id = 45854 }

local ADD   = "add"
local SUB   = "sub"
-- item_link writ2 values
local CP150 = 207
local CP160 = 225
-- item_link writ3 values
local PURPLE  = 4
local GOLD    = 5
Enchanting.POTENCY_RUNES = {
    [ADD] = { [CP150] = Enchanting.REJERA
            , [CP160] = Enchanting.REPORA
            }
,   [SUB] = { [CP150] = Enchanting.JEHADE
            , [CP160] = Enchanting.ITADE
            }
}

Enchanting.ASPECT_RUNES = {
    [PURPLE]    = Enchanting.REKUTA
,   [GOLD]      = Enchanting.KUTA
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

Enchanting.Parser = {
    class = "enchanting"
}
local Parser = Enchanting.Parser

function Parser:New()
    local o = {
        glyph           = nil   -- Glyph
    ,   aspect_rune     = nil   -- REKUTA
    ,   potency_rune    = nil   -- REJERA
    ,   level           = 0     -- 150 or 160
    ,   quality_num     = 0     -- 4 or 5
    ,   mat_list        = {}    -- of MatRow
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Parser:ParseItemLink(item_link)
    local fields      = Util.ToWritFields(item_link)
    local glyph_id    = fields.writ1
    local level_num   = fields.writ2
    local quality_num = fields.writ3

    if level_num == CP150 then
        self.level = 150
    else
        self.level = 160
    end
    self.quality_num = quality_num

    self.glyph        = Enchanting.Glyphs[glyph_id]
    if not (    self.glyph
            and self.glyph.add_sub
            and Enchanting.POTENCY_RUNES[self.glyph.add_sub]
            and level_num
            and Enchanting.POTENCY_RUNES[self.glyph.add_sub][level_num]
            and quality_num
            and Enchanting.ASPECT_RUNES[quality_num]) then
        return Fail("Glyph not found:"..tostring(glyph_id))
    end
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

function Parser:ToDolRequest()
    local o = {}
    o[1] = self.potency_rune.item_id        -- potency_item_id
    o[2] = self.glyph.essence_rune.item_id  -- essence_item_id
    o[3] = self.aspect_rune.item_id         -- aspect_item_id
    o[4] = true                             -- autocraft
    o[5] = nil                              -- reference

    return { ["function"        ] = "CraftEnchantingItemId"
           , ["args"            ] = o
           , ["request_ct"      ] = 1
           , ["reference_index" ] = 5  -- where in args[n] to store unique_id
           }
end


