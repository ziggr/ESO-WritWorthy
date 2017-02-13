-- Parse a Blacksmithing/Clothier/Woodworking master writ.

local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Util.lua

WritWorthy.Smithing = {}

local Smithing = WritWorthy.Smithing
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
}
Smithing.TRAITS_ARMOR    = {
    ["Sturdy"]          = "quartz"
,   ["Impenetrable"]    = "diamond"
,   ["Reinforced"]      = "sardonyx"
,   ["Well-fitted"]     = "almandine"
,   ["Training"]        = "emerald"
,   ["Infused"]         = "bloodstone"
,   ["Prosperous"]      = "garnet"
,   ["Divines"]         = "sapphire"
,   ["Nirnhoned"]       = "fortified nirncrux"
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
,   ["Barbarian"]               = "copper"
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
    { item_name = "Rubedite Axe",                school = HVY, base_mat_ct = 11, trait_set = WEAPON }
,   { item_name = "Rubedite Mace",               school = HVY, base_mat_ct = 11, trait_set = WEAPON }
,   { item_name = "Rubedite Sword",              school = HVY, base_mat_ct = 11, trait_set = WEAPON }
,   { item_name = "Rubedite Battle Axe",         school = HVY, base_mat_ct = 14, trait_set = WEAPON }
,   { item_name = "Rubedite Greataxe",           school = HVY, base_mat_ct = 14, trait_set = WEAPON }
,   { item_name = "Rubedite Greatsword",         school = HVY, base_mat_ct = 14, trait_set = WEAPON }
,   { item_name = "Rubedite Maul",               school = HVY, base_mat_ct = 14, trait_set = WEAPON }
,   { item_name = "Rubedite Dagger",             school = HVY, base_mat_ct = 10, trait_set = WEAPON }

,   { item_name = "Rubedite Cuirass",            school = HVY, base_mat_ct = 15, trait_set = ARMOR  }
,   { item_name = "Rubedite Sabatons",           school = HVY, base_mat_ct = 13, trait_set = ARMOR  }
,   { item_name = "Rubedite Gauntlets",          school = HVY, base_mat_ct = 13, trait_set = ARMOR  }
,   { item_name = "Rubedite Helm",               school = HVY, base_mat_ct = 13, trait_set = ARMOR  }
,   { item_name = "Rubedite Greaves",            school = HVY, base_mat_ct = 14, trait_set = ARMOR  }
,   { item_name = "Rubedite Pauldron",           school = HVY, base_mat_ct = 13, trait_set = ARMOR  }
,   { item_name = "Rubedite Girdle",             school = HVY, base_mat_ct = 13, trait_set = ARMOR  }

,   { item_name = "Ancestor Silk Robe",          school = LGT, base_mat_ct = 15, trait_set = ARMOR  }
,   { item_name = "Ancestor Silk Jerkin",        school = LGT, base_mat_ct = 15, trait_set = ARMOR  }
,   { item_name = "Ancestor Silk Shoes",         school = LGT, base_mat_ct = 13, trait_set = ARMOR  }
,   { item_name = "Ancestor Silk Gloves",        school = LGT, base_mat_ct = 13, trait_set = ARMOR  }
,   { item_name = "Ancestor Silk Hat",           school = LGT, base_mat_ct = 13, trait_set = ARMOR  }
,   { item_name = "Ancestor Silk Breeches",      school = LGT, base_mat_ct = 14, trait_set = ARMOR  }
,   { item_name = "Ancestor Silk Epaulets",      school = LGT, base_mat_ct = 13, trait_set = ARMOR  }
,   { item_name = "Ancestor Silk Sash",          school = LGT, base_mat_ct = 13, trait_set = ARMOR  }

,   { item_name = "Rubedo Leather Jack",         school = MED, base_mat_ct = 15, trait_set = ARMOR  }
,   { item_name = "Rubedo Leather Boots",        school = MED, base_mat_ct = 13, trait_set = ARMOR  }
,   { item_name = "Rubedo Leather Bracers",      school = MED, base_mat_ct = 13, trait_set = ARMOR  }
,   { item_name = "Rubedo Leather Helmet",       school = MED, base_mat_ct = 13, trait_set = ARMOR  }
,   { item_name = "Rubedo Leather Guards",       school = MED, base_mat_ct = 14, trait_set = ARMOR  }
,   { item_name = "Rubedo Leather Arm Cops",     school = MED, base_mat_ct = 13, trait_set = ARMOR  }
,   { item_name = "Rubedo Leather Belt",         school = MED, base_mat_ct = 13, trait_set = ARMOR  }

,   { item_name = "Ruby Ash Bow",                school = WW,  base_mat_ct = 12, trait_set = WEAPON }
,   { item_name = "Ruby Ash Inferno Staff",      school = WW,  base_mat_ct = 12, trait_set = WEAPON }
,   { item_name = "Ruby Ash Frost Staff",        school = WW,  base_mat_ct = 12, trait_set = WEAPON }
,   { item_name = "Ruby Ash Lightning Staff",    school = WW,  base_mat_ct = 12, trait_set = WEAPON }
,   { item_name = "Ruby Ash Restoration Staff",  school = WW,  base_mat_ct = 12, trait_set = WEAPON }
,   { item_name = "Ruby Ash Healing Staff",      school = WW,  base_mat_ct = 12, trait_set = WEAPON }

,   { item_name = "Ruby Ash Shield",             school = WW,  base_mat_ct = 14, trait_set = ARMOR  }
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
    for _, request_item in ipairs(Smithing.REQUEST_ITEMS) do
        if base_text:find(request_item.item_name) then
            self.request_item = request_item
            break
        end
    end
    if not self.request_item then return Fail("base not found") end

    -- "Trait: Defending" ==> [Turquoise]
    for trait_name, trait_mat_name in pairs(self.request_item.trait_set) do
        if base_text:find("Trait: "..trait_name) then
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

-- Convert result of ParseBaseText() into  a flat list of items.
function Parser:ToMatList()
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
    self.mat_list = ml
    return self.mat_list
end
