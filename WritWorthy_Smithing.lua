-- Parse a Blacksmithing/Clothier/Woodworking master writ.

local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Util.lua

WritWorthy.Smithing = {}

local Smithing = WritWorthy.Smithing
local Util     = WritWorthy.Util
local Fail     = WritWorthy.Util.Fail

-- Schools: HVY MED LGT WOOD -------------------------------------------------
--
-- Clothing split into two since base mats differ (silk vs. leather).
--
Smithing.SCHOOL_HEAVY =  {
    base_mat_name       = "rubedite"
,   green_mat_name      = "honing stone"
,   blue_mat_name       = "dwarven oil"
,   purple_mat_name     = "grain solvent"
,   gold_mat_name       = "tempering alloy"
}

Smithing.SCHOOL_MEDIUM = {
    base_mat_name       = "rubedo leather"
,   green_mat_name      = "hemming"
,   blue_mat_name       = "embroidery"
,   purple_mat_name     = "elegant lining"
,   gold_mat_name       = "dreugh wax"
}

Smithing.SCHOOL_LIGHT  = {
    base_mat_name       = "ancestor silk"
,   green_mat_name      = "hemming"
,   blue_mat_name       = "embroidery"
,   purple_mat_name     = "elegant lining"
,   gold_mat_name       = "dreugh wax"
}

Smithing.SCHOOL_WOOD   = {
    base_mat_name       = "ruby ash"
,   green_mat_name      = "pitch"
,   blue_mat_name       = "turpen"
,   purple_mat_name     = "mastic"
,   gold_mat_name       = "rosin"
}

-- Traits --------------------------------------------------------------------
--
-- Weapon and Armor must be separate sets because "Nirnhoned" mats differ
-- (potent vs. fortified nirncrux)
--
Smithing.TRAITS_WEAPON = {
    ["Powered"]         = "chysolite"
,   ["Charged"]         = "amethyst"
,   ["Precise"]         = "ruby"
,   ["Infused"]         = "jade"
,   ["Defending"]       = "turquoise"
,   ["Training"]        = "carnelian"
,   ["Sharpened"]       = "fire opal"
,   ["Decisive"]        = "citrine"
,   ["Nirnhoned"]       = "potent nirncrux"
,   [ 1]                = "chysolite"
,   [ 2]                = "amethyst"
,   [ 3]                = "ruby"
,   [ 4]                = "jade"
,   [ 5]                = "turquoise"
,   [ 6]                = "carnelian"
,   [ 7]                = "fire opal"
,   [ 8]                = "citrine"
,   [26]                = "potent nirncrux"


}
Smithing.TRAITS_ARMOR    = {
    ["Sturdy"]          = "quartz"
,   ["Impenetrable"]    = "diamond"
,   ["Reinforced"]      = "sardonyx"
,   ["Well-"]           = "almandine"   -- Well-fitted does not match. Again with the non-printing char after the hyphen?
,   ["Training"]        = "emerald"
,   ["Infused"]         = "bloodstone"
,   ["Prosperous"]      = "garnet"
,   ["Divines"]         = "sapphire"
,   ["Nirnhoned"]       = "fortified nirncrux"
,   [11]                = "quartz"
,   [12]                = "diamond"
,   [13]                = "sardonyx"
,   [14]                = "almandine"
,   [15]                = "emerald"
,   [16]                = "bloodstone"
,   [17]                = "garnet"
,   [18]                = "sapphire"
,   [25]                = "fortified nirncrux"

}

-- Motifs --------------------------------------------------------------------
--
-- Surprise: "Soul-Shriven" does not match "Style: Soul-Shriven" in base_text.
-- I suspect there's some non-printing character after the hyphen.
--
Smithing.MOTIF = {
    ["Altmer"]                  = "adamantite"
,   ["Dunmer"]                  = "obsidian"
,   ["Bosmer"]                  = "bone"
,   ["Nord"]                    = "corundum"
,   ["Breton"]                  = "molybdenum"
,   ["Redguard"]                = "starmetal"
,   ["Khajiit"]                 = "moonstone"
,   ["Orc"]                     = "manganese"
,   ["Argonian"]                = "flint"
,   ["Imperial"]                = "nickel"
,   ["Ancient Elf"]             = "palladium"
,   ["Barbaric"]                = "copper"
,   ["Primal"]                  = "argentum"
,   ["Daedric"]                 = "daedra heart"
,   ["Dwemer"]                  = "dwemer frame"
,   ["Glass"]                   = "malachite"
,   ["Xivkyn"]                  = "charcoal of remorse"
,   ["Akaviri"]                 = "goldscale"
,   ["Mercenary"]               = "laurel"
,   ["Ancient Orc"]             = "cassiterite"
,   ["Trinimac"]                = "auric tusk"
,   ["Malacath"]                = "potash"
,   ["Outlaw"]                  = "rogue's soot"
,   ["Aldmeri Dominion"]        = "eagle feather"
,   ["Daggerfall Covenant"]     = "lion fang"
,   ["Ebonheart Pact"]          = "dragon scute"
,   ["Soul-"]                   = "azure plasm" -- "Soul-Shriven" does not match
,   ["Abah's Watch"]            = "polished shilling"
,   ["Thieves Guild"]           = "fine chalk"
,   ["Assassins League"]        = "tainted blood"
,   ["Dro-m'athra"]             = "defiled whiskers"
,   ["Dark Brotherhood"]        = "black beeswax"
,   ["Minotaur"]                = "oxblood fungus"
,   ["Order of the Hour"]       = "pearl sand"
,   ["Yokudan"]                 = "ferrous salts"
,   ["Celestial"]               = "star sapphire"
,   ["Draugr"]                  = "pristine shroud"
,   ["Hollowjack"]              = "amber marble"
,   ["Grim Harlequin"]          = "grinstones"
,   ["Stahlrim Frostcaster"]    = "stahlrim shard"
,   ["Skinchanger"]             = "wolfsbane incense"

,   [ 1]  = "molybdenum"          -- Breton
,   [ 2]  = "starmetal"           -- Redguard
,   [ 3]  = "manganese"           -- Orc
,   [ 4]  = "obsidian"            -- Dunmer
,   [ 5]  = "corundum"            -- Nord
,   [ 6]  = "flint"               -- Argonian
,   [ 7]  = "adamantite"          -- Altmer
,   [ 8]  = "bone"                -- Bosmer
,   [ 9]  = "moonstone"           -- Khajiit
,   [10]  = nil                   -- Unique
,   [11]  = "fine chalk"          -- Thieves Guild
,   [12]  = "black beeswax"       -- Dark Brotherhood
,   [13]  = "potash"              -- Malacath
,   [14]  = "dwemer frame"        -- Dwemer
,   [15]  = "palladium"           -- Ancient Elf
,   [16]  = "pearl sand"          -- Order of the Hour
,   [17]  = "copper"              -- Barbaric
,   [18]  = nil                   -- Bandit
,   [19]  = "argentum"            -- Primal
,   [20]  = "daedra heart"        -- Daedric
,   [21]  = "auric tusk"          -- Trinimac
,   [22]  = "cassiterite"         -- Ancient Orc
,   [23]  = "lion fang"           -- Daggerfall Covenant
,   [24]  = "dragon scute"        -- Ebonheart Pact
,   [25]  = "eagle feather"       -- Aldmeri Dominion
,   [26]  = "laurel"              -- Mercenary
,   [27]  = "star sapphire"       -- Celestial
,   [28]  = "malachite"           -- Glass
,   [29]  = "charcoal of remorse" -- Xivkyn
,   [30]  = "azure plasm"         -- Soul-Shriven
,   [31]  = "pristine shroud"     -- Draugr
,   [32]  = nil                   -- Maormer
,   [33]  = "goldscale"           -- Akaviri
,   [34]  = "nickel"              -- Imperial
,   [35]  = "ferrous salts"       -- Yokudan
,   [36]  = nil                   -- unused
,   [37]  = nil                   -- Reach Winter
,   [38]  = nil                   -- Worm Cult
,   [39]  = "oxblood fungus"      -- Minotaur
,   [40]  = nil                   -- Ebony        HEY THIS EXISTS NOW 2.7
,   [41]  = "polished shilling"   -- Abah's Watch
,   [42]  = "wolfsbane incense"   -- Skinchanger
,   [43]  = nil                   -- Morag Tong
,   [44]  = nil                   -- Ra Gada      HEY THIS EXISTS NOW 2.7
,   [45]  = "defiled whiskers"    -- Dro-m'Athra
,   [46]  = "tainted blood"       -- Assassins League
,   [47]  = "rogue's soot"        -- Outlaw
,   [48]  = nil                   -- Unused 11
,   [49]  = nil                   -- Unused 12
,   [50]  = nil                   -- Unused 13
,   [51]  = nil                   -- Unused 14
,   [52]  = nil                   -- Unused 15
,   [53]  = "stahlrim shard"      -- Stalhrim Frostcaster
,   [54]  = nil                   -- Unused 17
,   [55]  = nil                   -- Unused 18
,   [56]  = nil                   -- Silken Ring  HEY THIS EXISTS NOW 2.7
,   [57]  = nil                   -- Mazzatun     HEY THIS EXISTS NOW 2.7
,   [58]  = "grinstones"          -- Grim Harlequin
,   [59]  = "amber marble"        -- Hollowjack
,   [60]  = nil                   --
}

-- Requestable items ---------------------------------------------------------
--
-- Material requirements for each possitble Master Write BS/CL/WW item.
--

                        -- abbreviations to make the table more concise.
local HVY    = Smithing.SCHOOL_HEAVY
local MED    = Smithing.SCHOOL_MEDIUM
local LGT    = Smithing.SCHOOL_LIGHT
local WW     = Smithing.SCHOOL_WOOD
local WEAPON = Smithing.TRAITS_WEAPON
local ARMOR  = Smithing.TRAITS_ARMOR

Smithing.REQUEST_ITEMS = {
  [53] = { item_id = 53, item_name = "Rubedite Axe",                school = HVY, base_mat_ct = 11, trait_set = WEAPON }
, [56] = { item_id = 56, item_name = "Rubedite Mace",               school = HVY, base_mat_ct = 11, trait_set = WEAPON }
, [59] = { item_id = 59, item_name = "Rubedite Sword",              school = HVY, base_mat_ct = 11, trait_set = WEAPON }
, [68] = { item_id = 68, item_name = "Rubedite Greataxe",           school = HVY, base_mat_ct = 14, trait_set = WEAPON }
, [67] = { item_id = 67, item_name = "Rubedite Greatsword",         school = HVY, base_mat_ct = 14, trait_set = WEAPON }
, [69] = { item_id = 69, item_name = "Rubedite Maul",               school = HVY, base_mat_ct = 14, trait_set = WEAPON }
, [62] = { item_id = 62, item_name = "Rubedite Dagger",             school = HVY, base_mat_ct = 10, trait_set = WEAPON }

, [46] = { item_id = 46, item_name = "Rubedite Cuirass",            school = HVY, base_mat_ct = 15, trait_set = ARMOR  }
, [50] = { item_id = 50, item_name = "Rubedite Sabatons",           school = HVY, base_mat_ct = 13, trait_set = ARMOR  }
, [52] = { item_id = 52, item_name = "Rubedite Gauntlets",          school = HVY, base_mat_ct = 13, trait_set = ARMOR  }
, [44] = { item_id = 44, item_name = "Rubedite Helm",               school = HVY, base_mat_ct = 13, trait_set = ARMOR  }
, [49] = { item_id = 49, item_name = "Rubedite Greaves",            school = HVY, base_mat_ct = 14, trait_set = ARMOR  }
, [47] = { item_id = 47, item_name = "Rubedite Pauldron",           school = HVY, base_mat_ct = 13, trait_set = ARMOR  }
, [48] = { item_id = 48, item_name = "Rubedite Girdle",             school = HVY, base_mat_ct = 13, trait_set = ARMOR  }

, [28] = { item_id = 28, item_name = "Ancestor Silk Robe",          school = LGT, base_mat_ct = 15, trait_set = ARMOR  }
, [ 0] = { item_id =  0, item_name = "Ancestor Silk Jerkin",        school = LGT, base_mat_ct = 15, trait_set = ARMOR  }
, [32] = { item_id = 32, item_name = "Ancestor Silk Shoes",         school = LGT, base_mat_ct = 13, trait_set = ARMOR  }
, [34] = { item_id = 34, item_name = "Ancestor Silk Gloves",        school = LGT, base_mat_ct = 13, trait_set = ARMOR  }
, [26] = { item_id = 26, item_name = "Ancestor Silk Hat",           school = LGT, base_mat_ct = 13, trait_set = ARMOR  }
, [31] = { item_id = 31, item_name = "Ancestor Silk Breeches",      school = LGT, base_mat_ct = 14, trait_set = ARMOR  }
, [29] = { item_id = 29, item_name = "Ancestor Silk Epaulets",      school = LGT, base_mat_ct = 13, trait_set = ARMOR  }
, [30] = { item_id = 30, item_name = "Ancestor Silk Sash",          school = LGT, base_mat_ct = 13, trait_set = ARMOR  }

, [37] = { item_id = 37, item_name = "Rubedo Leather Jack",         school = MED, base_mat_ct = 15, trait_set = ARMOR  }
, [41] = { item_id = 41, item_name = "Rubedo Leather Boots",        school = MED, base_mat_ct = 13, trait_set = ARMOR  }
, [43] = { item_id = 43, item_name = "Rubedo Leather Bracers",      school = MED, base_mat_ct = 13, trait_set = ARMOR  }
, [35] = { item_id = 35, item_name = "Rubedo Leather Helmet",       school = MED, base_mat_ct = 13, trait_set = ARMOR  }
, [40] = { item_id = 40, item_name = "Rubedo Leather Guards",       school = MED, base_mat_ct = 14, trait_set = ARMOR  }
, [38] = { item_id = 38, item_name = "Rubedo Leather Arm Cops",     school = MED, base_mat_ct = 13, trait_set = ARMOR  }
, [39] = { item_id = 39, item_name = "Rubedo Leather Belt",         school = MED, base_mat_ct = 13, trait_set = ARMOR  }

, [70] = { item_id = 70, item_name = "Ruby Ash Bow",                school = WW,  base_mat_ct = 12, trait_set = WEAPON }
, [72] = { item_id = 72, item_name = "Ruby Ash Inferno Staff",      school = WW,  base_mat_ct = 12, trait_set = WEAPON }
, [73] = { item_id = 73, item_name = "Ruby Ash Frost Staff",        school = WW,  base_mat_ct = 12, trait_set = WEAPON }
, [74] = { item_id = 74, item_name = "Ruby Ash Lightning Staff",    school = WW,  base_mat_ct = 12, trait_set = WEAPON }
, [71] = { item_id = 71, item_name = "Ruby Ash Healing Staff",      school = WW,  base_mat_ct = 12, trait_set = WEAPON }

, [65] = { item_id = 65, item_name = "Ruby Ash Shield",             school = WW,  base_mat_ct = 14, trait_set = ARMOR  }
}

-- Improvement Material Counts -----------------------------------------------
--
-- Material counts for improving to purple or gold.
--
Smithing.PURPLE = {
    green_mat_ct   = 2
,   blue_mat_ct    = 3
,   purple_mat_ct  = 4
,   gold_mat_ct    = 0
}

Smithing.GOLD = {
    green_mat_ct   = 2
,   blue_mat_ct    = 3
,   purple_mat_ct  = 4
,   gold_mat_ct    = 8
}

Smithing.QUALITY = {
    [4] = Smithing.PURPLE
,   [5] = Smithing.GOLD
}

-- Parser ====================================================================

Smithing.Parser = {}
local Parser = Smithing.Parser

function Parser:New()
    local o = {
        base_text       = nil   -- "Consume to start quest"
                                -- "\nCraft a Rubedite Sword;"
                                -- " Quality: Legendary;"
                                -- " Trait: Defending;"
                                -- " Set: Way of the Arena;"
                                -- " Style: Primal"
    ,   request_item    = nil   -- Smithing.REQUEST_ITEMS[x]
    ,   trait_mat_name  = nil   -- "turquoise"
    ,   motif_mat_name  = nil   -- "argentum"
    ,   improve_level   = nil   -- PURPLE, GOLD
    ,   mat_list        = {}    -- of MatRow
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Parser:ParseBaseText(base_text)
    self.base_text = base_text

    -- "Rubedite Sword" ==> blacksmithing, 11 Rubedite Ingot
    for _, request_item in pairs(Smithing.REQUEST_ITEMS) do
        if base_text:find(request_item.item_name) then
            self.request_item = request_item
            break
        end
    end
    if not self.request_item then return Fail("base not found") end

    -- "Trait: Defending" ==> [Turquoise]
    for trait_name, trait_mat_name in pairs(self.request_item.trait_set) do
        if base_text:find("Trait: "..tostring(trait_name)) then
            self.trait_mat_name = trait_mat_name
            break
        end
    end
    if not self.trait_mat_name then return Fail("trait not found") end

    -- "Style: Primal" ==> [Argentum]
    for motif_name, motif_mat_name in pairs(Smithing.MOTIF) do
        if base_text:find("Style: "..motif_name) then
            self.motif_mat_name = motif_mat_name
            break
        end
    end
    if not self.motif_mat_name then return Fail("motif not found: " .. base_text) end

    -- "Quality: Epic" ==> purple
    if base_text:find("Quality: Epic") then
        self.improve_level = Smithing.PURPLE
    end
    if base_text:find("Quality: Legendary") then
        self.improve_level = Smithing.GOLD
    end
    if not self.improve_level then return Fail("quality not found") end
    return self
end

function Parser:ParseItemLink(item_link)
d(300)
    local fields        = Util.ToWritFields(item_link)
d(310)
    local item_num      = fields.writ1
    local material_num  = fields.writ2
    local quality_num   = fields.writ3
    local set_num       = fields.writ4
    local trait_num     = fields.writ5
    local motif_num     = fields.writ6

    self.request_item   = Smithing.REQUEST_ITEMS[item_num]
    self.trait_mat_name = self.request_item.trait_set[trait_num]
    self.motif_mat_name = Smithing.MOTIF[motif_num]
d(320)
    if not self.motif_mat_name then return Fail("motif not found "..tostring(motif_num)) end
d(330)
    self.improve_level  = Smithing.QUALITY[quality_num]
    if not self.improve_level then return Fail("quality not found "..tostring(quality_num)) end
d(333)
    return self
end

-- Convert result of ParseBaseText() into  a flat list of items.
function Parser:ToMatList()
d(444)
    local MatRow = WritWorthy.MatRow
    local ml = {}
    table.insert(ml, MatRow:FromName( self.request_item.school.base_mat_name
                                    , self.request_item.base_mat_ct ))
    table.insert(ml, MatRow:FromName( self.trait_mat_name ))
    table.insert(ml, MatRow:FromName( self.motif_mat_name ))

    table.insert(ml, MatRow:FromName( self.request_item.school.green_mat_name
                                    , self.improve_level.green_mat_ct ))
    table.insert(ml, MatRow:FromName( self.request_item.school.blue_mat_name
                                    , self.improve_level.blue_mat_ct ))
    table.insert(ml, MatRow:FromName( self.request_item.school.purple_mat_name
                                    , self.improve_level.purple_mat_ct ))
    if 0 < self.improve_level.gold_mat_ct then
        table.insert(ml, MatRow:FromName( self.request_item.school.gold_mat_name
                                        , self.improve_level.gold_mat_ct ))
    end
d(555)
    self.mat_list = ml
    return self.mat_list
end

