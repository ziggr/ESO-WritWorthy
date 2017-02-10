local LAM2 = LibStub("LibAddonMenu-2.0")

local WritWorthy = {}
local SmithItem = {}
local MatRow = {}

WritWorthy.name            = "WritWorthy"
WritWorthy.version         = "2.7.1"

local function Fail(msg)
    d(msg)
end

-- Chat Colors ---------------------------------------------------------------

WritWorthy.GREY = "999999"

function WritWorthy.color(color, text)
    return "|c" .. color .. text .. "|r"
end

function WritWorthy.grey(text)
    return WritWorthy.color(WritWorthy.GREY, text)
end

function WritWorthy.round(f)
    if not f then return f end
    return math.floor(0.5+f)
end

-- Number/String conversion --------------------------------------------------

-- Return commafied integer number, or "?" if nil.
function WritWorthy.ToMoney(x)
    if not x then return "?" end
    return ZO_CurrencyControl_FormatCurrency(WritWorthy.round(x), false)
end

-- MatRow ====================================================================
--
-- One row of SmithItem.mat_list

function MatRow:New()
    local o = {
        name    = nil   -- "rubedite"
    ,   link    = nil   -- "|H0:item:64489:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
    ,   ct      = nil   -- 13
    ,   mm      = nil   -- 13.42315
    }
    setmetatable(o, self)
    self.__index = self
    return o
end
function MatRow:FromName(mat_name, ct)
    local o  = MatRow:New()
    o.name = mat_name
    o.link = SmithItem.LINK[mat_name]
    if ct then
        o.ct = tonumber(ct)
    else
        o.ct = 1
    end
    o.mm = WritWorthy.MMPrice(o.link)
    return o
end
function MatRow:Total()
    if not self.ct then return 0 end
    if not self.mm then return 0 end
    return self.ct * self.mm
end
function MatRow.ListDump(mat_list)
    local total = 0
    for _, row in ipairs(mat_list) do
        local row_total = row:Total()
        total = total + row_total
        d(WritWorthy.ToMoney(row_total) .. "g = "
         .. tostring(row.ct) .. "x "
         .. WritWorthy.ToMoney(row.mm) .. " "
         .. tostring(row.link) )
    end
    d(WritWorthy.ToMoney(total) .. "g total")
end
function MatRow.ListTotal(mat_list)
    local total = 0
    for _, row in ipairs(mat_list) do
        total = total + row:Total()
    end
    return total
end

-- SmithItem =================================================================
--
-- A single blacksmithing, clothing, or woodworking crafted item, required
-- for a Master Writ.

-- The four crafting schools (clothing counts as two: light and medium)
SmithItem.HEAVY = {
    base_mat_name       = "rubedite"
,   green_mat_name      = "honing stone"
,   blue_mat_name       = "dwarven oil"
,   purple_mat_name     = "grain solvent"
,   gold_mat_name       = "tempering alloy"
}

SmithItem.MEDIUM = {
    base_mat_name       = "rubedo leather"
,   green_mat_name      = "hemming"
,   blue_mat_name       = "embroidery"
,   purple_mat_name     = "elegant lining"
,   gold_mat_name       = "dreugh wax"
}

SmithItem.LIGHT  = {
    base_mat_name       = "ancestor silk"
,   green_mat_name      = "hemming"
,   blue_mat_name       = "embroidery"
,   purple_mat_name     = "elegant lining"
,   gold_mat_name       = "dreugh wax"
}

SmithItem.WOOD   = {
    base_mat_name       = "ruby ash"
,   green_mat_name      = "pitch"
,   blue_mat_name       = "turpen"
,   purple_mat_name     = "mastic"
,   gold_mat_name       = "rosin"
}

-- Traits for weapons and armor.
-- Need two tables since "Nirnhoned" could mean either potent or fortified.
SmithItem.TRAITS_WEAPON = {
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
SmithItem.ARMOR    = {
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

SmithItem.MOTIF = {
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
,   ["Soul-shriven"]            = "azure plasm"
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

-- Material requirements for each possitble Master Write BS/CL/WW item.
                        -- abbreviations to make the table more concise.
local HVY = SmithItem.HEAVY
local MED = SmithItem.MEDIUM
local LGT = SmithItem.LIGHT
local WW  = SmithItem.WOOD
local WEAPON = SmithItem.TRAITS_WEAPON
local ARMOR  = SmithItem.ARMOR

SmithItem.ITEM_BASE = {
    { name = "Rubedite Axe",                school = HVY, base_mat_ct = 11, trait_set = WEAPON }
,   { name = "Rubedite Mace",               school = HVY, base_mat_ct = 11, trait_set = WEAPON }
,   { name = "Rubedite Sword",              school = HVY, base_mat_ct = 11, trait_set = WEAPON }
,   { name = "Rubedite Battle Axe",         school = HVY, base_mat_ct = 14, trait_set = WEAPON }
,   { name = "Rubedite Greatsword",         school = HVY, base_mat_ct = 14, trait_set = WEAPON }
,   { name = "Rubedite Maul",               school = HVY, base_mat_ct = 14, trait_set = WEAPON }
,   { name = "Rubedite Dagger",             school = HVY, base_mat_ct = 10, trait_set = WEAPON }

,   { name = "Rubedite Cuirass",            school = HVY, base_mat_ct = 15, trait_set = ARMOR  }
,   { name = "Rubedite Sabatons",           school = HVY, base_mat_ct = 13, trait_set = ARMOR  }
,   { name = "Rubedite Gauntlets",          school = HVY, base_mat_ct = 13, trait_set = ARMOR  }
,   { name = "Rubedite Helm",               school = HVY, base_mat_ct = 13, trait_set = ARMOR  }
,   { name = "Rubedite Greaves",            school = HVY, base_mat_ct = 14, trait_set = ARMOR  }
,   { name = "Rubedite Pauldron",           school = HVY, base_mat_ct = 13, trait_set = ARMOR  }
,   { name = "Rubedite Girdle",             school = HVY, base_mat_ct = 13, trait_set = ARMOR  }

,   { name = "Ancestor Silk Robe",          school = LGT, base_mat_ct = 15, trait_set = ARMOR  }
,   { name = "Ancestor Silk Jerkin",        school = LGT, base_mat_ct = 15, trait_set = ARMOR  }
,   { name = "Ancestor Silk Shoes",         school = LGT, base_mat_ct = 13, trait_set = ARMOR  }
,   { name = "Ancestor Silk Gloves",        school = LGT, base_mat_ct = 13, trait_set = ARMOR  }
,   { name = "Ancestor Silk Hat",           school = LGT, base_mat_ct = 13, trait_set = ARMOR  }
,   { name = "Ancestor Silk Breeches",      school = LGT, base_mat_ct = 14, trait_set = ARMOR  }
,   { name = "Ancestor Silk Epaulets",      school = LGT, base_mat_ct = 13, trait_set = ARMOR  }
,   { name = "Ancestor Silk Sash",          school = LGT, base_mat_ct = 13, trait_set = ARMOR  }

,   { name = "Rubedo Leather Jack",         school = MED, base_mat_ct = 15, trait_set = ARMOR  }
,   { name = "Rubedo Leather Boots",        school = MED, base_mat_ct = 13, trait_set = ARMOR  }
,   { name = "Rubedo Leather Bracers",      school = MED, base_mat_ct = 13, trait_set = ARMOR  }
,   { name = "Rubedo Leather Helmet",       school = MED, base_mat_ct = 13, trait_set = ARMOR  }
,   { name = "Rubedo Leather Guards",       school = MED, base_mat_ct = 14, trait_set = ARMOR  }
,   { name = "Rubedo Leather Arm Cops",     school = MED, base_mat_ct = 13, trait_set = ARMOR  }
,   { name = "Rubedo Leather Belt",         school = MED, base_mat_ct = 13, trait_set = ARMOR  }

,   { name = "Ruby Ash Bow",                school = WW,  base_mat_ct = 12, trait_set = WEAPON }
,   { name = "Ruby Ash Inferno Staff",      school = WW,  base_mat_ct = 12, trait_set = WEAPON }
,   { name = "Ruby Ash Ice Staff",          school = WW,  base_mat_ct = 12, trait_set = WEAPON }
,   { name = "Ruby Ash Lightning Staff",    school = WW,  base_mat_ct = 12, trait_set = WEAPON }
,   { name = "Ruby Ash Restoration Staff",  school = WW,  base_mat_ct = 12, trait_set = WEAPON }

,   { name = "Ruby Ash Shield",             school = WW,  base_mat_ct = 14, trait_set = ARMOR  }
}

-- Material counts for improving to purple or gold.
SmithItem.PURPLE = { green_mat_ct   = 2
                   , blue_mat_ct    = 3
                   , purple_mat_ct  = 4
                   , gold_mat_ct    = 0
                   }

SmithItem.GOLD   = { green_mat_ct   = 2
                   , blue_mat_ct    = 3
                   , purple_mat_ct  = 4
                   , gold_mat_ct    = 8
                   }

-- It is easier to maintain code if I can type "[Dreugh Wax]" instead of
--"|H0:item:54177:34:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
SmithItem.LINK = {
    ["ancestor silk"      ] = "|H0:item:64504:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
,   ["rubedo leather"     ] = "|H0:item:64506:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
,   ["rubedite"           ] = "|H0:item:64489:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
,   ["ruby ash"           ] = "|H0:item:64502:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"

,   ["hemming"            ] = "|H0:item:54174:31:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
,   ["embroidery"         ] = "|H0:item:54175:32:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
,   ["elegant lining"     ] = "|H0:item:54176:33:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
,   ["dreugh wax"         ] = "|H0:item:54177:34:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"

,   ["honing stone"       ] = "|H0:item:54170:31:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
,   ["dwarven oil"        ] = "|H0:item:54171:32:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
,   ["grain solvent"      ] = "|H0:item:54172:33:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
,   ["tempering alloy"    ] = "|H0:item:54173:34:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"

,   ["pitch"              ] = "|H0:item:54178:31:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
,   ["turpen"             ] = "|H0:item:54179:32:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
,   ["mastic"             ] = "|H0:item:54180:33:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
,   ["rosin"              ] = "|H0:item:54181:34:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"

,   ["adamantite"         ] = "|H0:item:33252:30:50:0:0:0:0:0:0:0:0:0:0:0:0:7:0:0:0:0:0|h|h"
,   ["obsidian"           ] = "|H0:item:33253:30:0:0:0:0:0:0:0:0:0:0:0:0:0:4:0:0:0:0:0|h|h"
,   ["bone"               ] = "|H0:item:33194:30:0:0:0:0:0:0:0:0:0:0:0:0:0:8:0:0:0:0:0|h|h"
,   ["corundum"           ] = "|H0:item:33256:30:0:0:0:0:0:0:0:0:0:0:0:0:0:5:0:0:0:0:0|h|h"
,   ["molybdenum"         ] = "|H0:item:33251:30:13:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:0:0|h|h"
,   ["starmetal"          ] = "|H0:item:33258:30:0:0:0:0:0:0:0:0:0:0:0:0:0:2:0:0:0:0:0|h|h"
,   ["moonstone"          ] = "|H0:item:33255:30:50:0:0:0:0:0:0:0:0:0:0:0:0:9:0:0:0:0:0|h|h"
,   ["manganese"          ] = "|H0:item:33257:30:50:0:0:0:0:0:0:0:0:0:0:0:0:3:0:0:0:0:0|h|h"
,   ["flint"              ] = "|H0:item:33150:30:0:0:0:0:0:0:0:0:0:0:0:0:0:6:0:0:0:0:0|h|h"
,   ["nickel"             ] = "|H0:item:33254:30:50:0:0:0:0:0:0:0:0:0:0:0:0:34:0:0:0:0:0|h|h"
,   ["palladium"          ] = "|H0:item:46152:30:0:0:0:0:0:0:0:0:0:0:0:0:0:15:0:0:0:0:0|h|h"
,   ["copper"             ] = "|H0:item:46149:30:23:0:0:0:0:0:0:0:0:0:0:0:0:17:0:0:0:0:0|h|h"
,   ["argentum"           ] = "|H0:item:46150:30:16:0:0:0:0:0:0:0:0:0:0:0:0:19:0:0:0:0:0|h|h"
,   ["daedra heart"       ] = "|H0:item:46151:30:50:0:0:0:0:0:0:0:0:0:0:0:0:20:0:0:0:0:0|h|h"
,   ["dwemer frame"       ] = "|H0:item:57587:30:0:0:0:0:0:0:0:0:0:0:0:0:0:14:0:0:0:0:0|h|h"
,   ["malachite"          ] = "|H0:item:64689:6:0:0:0:0:0:0:0:0:0:0:0:0:0:28:0:0:0:0:0|h|h"
,   ["charcoal of remorse"] = "|H0:item:59922:30:0:0:0:0:0:0:0:0:0:0:0:0:0:29:0:0:0:0:0|h|h"
,   ["goldscale"          ] = "|H0:item:64687:30:50:0:0:0:0:0:0:0:0:0:0:0:0:33:0:0:0:0:0|h|h"
,   ["laurel"             ] = "|H0:item:64713:6:50:0:0:0:0:0:0:0:0:0:0:0:0:26:0:0:0:0:0|h|h"
,   ["cassiterite"        ] = "|H0:item:69555:30:0:0:0:0:0:0:0:0:0:0:0:0:0:22:0:0:0:0:0|h|h"
,   ["auric tusk"         ] = "|H0:item:71582:30:0:0:0:0:0:0:0:0:0:0:0:0:0:21:0:0:0:0:0|h|h"
,   ["potash"             ] = "|H0:item:71584:30:50:0:0:0:0:0:0:0:0:0:0:0:0:13:0:0:0:0:0|h|h"
,   ["rogue's soot"       ] = "|H0:item:71538:30:0:0:0:0:0:0:0:0:0:0:0:0:0:47:0:0:0:0:0|h|h"
,   ["eagle feather"      ] = "|H0:item:71738:30:0:0:0:0:0:0:0:0:0:0:0:0:0:25:0:0:0:0:0|h|h"
,   ["lion fang"          ] = "|H0:item:71742:30:0:0:0:0:0:0:0:0:0:0:0:0:0:23:0:0:0:0:0|h|h"
,   ["dragon scute"       ] = "|H0:item:71740:30:0:0:0:0:0:0:0:0:0:0:0:0:0:24:0:0:0:0:0|h|h"
,   ["azure plasm"        ] = "|H0:item:71766:30:50:0:0:0:0:0:0:0:0:0:0:0:0:30:0:0:0:0:0|h|h"
,   ["fine chalk"         ] = "|H0:item:75370:30:0:0:0:0:0:0:0:0:0:0:0:0:0:11:0:0:0:0:0|h|h"
,   ["polished shilling"  ] = "|H0:item:76914:30:0:0:0:0:0:0:0:0:0:0:0:0:0:41:0:0:0:0:0|h|h"
,   ["tainted blood"      ] = "|H0:item:76910:30:0:0:0:0:0:0:0:0:0:0:0:0:0:46:0:0:0:0:0|h|h"
,   ["defiled whiskers"   ] = "|H0:item:79672:30:0:0:0:0:0:0:0:0:0:0:0:0:0:45:0:0:0:0:0|h|h"
,   ["black beeswax"      ] = "|H0:item:79304:30:0:0:0:0:0:0:0:0:0:0:0:0:0:12:0:0:0:0:0|h|h"
,   ["oxblood fungus"     ] = "|H0:item:81994:30:0:0:0:0:0:0:0:0:0:0:0:0:0:39:0:0:0:0:0|h|h"
,   ["pearl sand"         ] = "|H0:item:81996:30:0:0:0:0:0:0:0:0:0:0:0:0:0:16:0:0:0:0:0|h|h"
,   ["ferrous salts"      ] = "|H0:item:64685:30:1:0:0:0:0:0:0:0:0:0:0:0:0:35:0:0:0:0:0|h|h"
,   ["star sapphire"      ] = "|H0:item:81998:30:1:0:0:0:0:0:0:0:0:0:0:0:0:27:0:0:0:0:0|h|h"
,   ["pristine shroud"    ] = "|H0:item:75373:30:1:0:0:0:0:0:0:0:0:0:0:0:0:31:0:0:0:0:0|h|h"
,   ["amber marble"       ] = "|H0:item:82000:30:1:0:0:0:0:0:0:0:0:0:0:0:0:59:0:0:0:0:0|h|h"
,   ["grinstones"         ] = "|H0:item:82002:30:1:0:0:0:0:0:0:0:0:0:0:0:0:58:0:0:0:0:0|h|h"
,   ["stalhrim shard"     ] = "|H0:item:114283:30:1:0:0:0:0:0:0:0:0:0:0:0:0:53:0:0:0:0:0|h|h"
,   ["wolfsbane incense"  ] = "|H0:item:96388:30:1:0:0:0:0:0:0:0:0:0:0:0:0:42:0:0:0:0:0|h|h"

,   ["quartz"             ] = "|H0:item:4456:30:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
,   ["diamond"            ] = "|H0:item:23219:30:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
,   ["sardonyx"           ] = "|H0:item:30221:30:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
,   ["almandine"          ] = "|H0:item:23221:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
,   ["emerald"            ] = "|H0:item:4442:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
,   ["bloodstone"         ] = "|H0:item:30219:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
,   ["garnet"             ] = "|H0:item:23171:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
,   ["sapphire"           ] = "|H0:item:23173:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
,   ["fortified nirncrux" ] = "|H0:item:56862:30:6:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
,   ["chysolite"          ] = "|H0:item:23203:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
,   ["amethyst"           ] = "|H0:item:23204:30:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
,   ["ruby"               ] = "|H0:item:4486:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
,   ["jade"               ] = "|H0:item:810:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
,   ["turquoise"          ] = "|H0:item:813:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
,   ["carnelian"          ] = "|H0:item:23165:30:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
,   ["fire opal"          ] = "|H0:item:23149:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
,   ["citrine"            ] = "|H0:item:16291:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
,   ["potent nirncrux"    ] = "|H0:item:56863:30:46:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"

}
function SmithItem:New()
    local o = {
        base_text       = nil   -- "Consume to start quest"
                                -- "\nCraft a Rubedite Sword;"
                                -- " Quality: Legendary;"
                                -- " Trait: Defending;"
                                -- " Set: Way of the Arena;"
                                -- " Style: Primal"
    ,   reward_text     = nil   -- "Reward 92 (icon) Writ Vouchers"
    ,   item_base       = nil   -- SmithItem.ITEM_BASE[x]
    ,   trait_mat_name  = nil   -- [Turquoise]
    ,   motif_mat_name  = nil   -- [Argentum]
    ,   improve_level   = nil   -- PURPLE, GOLD
    ,   voucher_ct      = nil   -- 92
    ,   mat_list        = {}    -- of MatRow
    ,   purchase_gold   = nil   -- 90000  (only for guild store purchases)
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function SmithItem:ParseBaseText(base_text)
    self.base_text = base_text

    -- "Rubedite Sword" ==> blacksmithing, 11 Rubedite Ingot
    for _, item_base in ipairs(SmithItem.ITEM_BASE) do
        if base_text:find(item_base.name) then
            self.item_base     = item_base
            break
        end
    end
    if not self.item_base then return Fail("base not found") end

    -- "Trait: Defending" ==> [Turquoise]
    for trait_name, trait_mat_name in pairs(self.item_base.trait_set) do
        if base_text:find("Trait: "..trait_name) then
            self.trait_mat_name = trait_mat_name
            break
        end
    end
    if not self.trait_mat_name then return Fail("trait not found") end

    -- "Style: Primal" ==> [Argentum]
    for motif_name, motif_mat_name in pairs(SmithItem.MOTIF) do
        if base_text:find("Style: "..motif_name) then
            self.motif_mat_name = motif_mat_name
            break
        end
    end
    if not self.motif_mat_name then return Fail("motif not found") end

    -- "Quality: Epic" ==> purple
    if base_text:find("Quality: Epic") then
        self.improve_level = SmithItem.PURPLE
    end
    if base_text:find("Quality: Legendary") then
        self.improve_level = SmithItem.GOLD
    end
    if not self.improve_level then return Fail("quality not found") end
    return self
end

function SmithItem:ParseRewardText(reward_text)
    self.reward_text = reward_text
    local _,_,s = reward_text:find("Reward: (%d+)")
    if s then
        self.voucher_ct = tonumber(s)
    end
    if not self.voucher_ct then return Fail("voucher ct not found") end
end

-- Factory to take an item, parse its MasterWrit descriptive text into
-- useful fields.
function SmithItem:FromLink(item_link, purchase_gold)
    local o = SmithItem:New()
    if not (o:ParseBaseText(GenerateMasterWritBaseText(item_link))) return nil
    o:ParseRewardText(GenerateMasterWritRewardText(item_link))
    o.purchase_gold = purchase_gold
    return o
end

-- Take fields extracted by FromLink() and expand into a flat list of items.
function SmithItem:CollectMatList()
    local ml = {}
    table.insert(ml, MatRow:FromName( self.item_base.school.base_mat_name
                                    , self.item_base.base_mat_ct ))
    table.insert(ml, MatRow:FromName( self.trait_mat_name ))
    table.insert(ml, MatRow:FromName( self.motif_mat_name ))

    table.insert(ml, MatRow:FromName( self.item_base.school.green_mat_name
                                    , self.improve_level.green_mat_ct ))
    table.insert(ml, MatRow:FromName( self.item_base.school.blue_mat_name
                                    , self.improve_level.blue_mat_ct ))
    table.insert(ml, MatRow:FromName( self.item_base.school.purple_mat_name
                                    , self.improve_level.purple_mat_ct ))
    if 0 < self.improve_level.gold_mat_ct then
        table.insert(ml, MatRow:FromName( self.item_base.school.gold_mat_name
                                        , self.improve_level.gold_mat_ct ))
    end
    self.mat_list = ml
end

function SmithItem:DebugDump()
    d(self.base_text)
    -- d(self.reward_text)

    -- if self.item_base then
    --     d("item_base.name: "        .. tostring(self.item_base.name))
    --     d("item_base.base_mat_ct: " .. tostring(self.item_base.base_mat_ct))
    -- else
    --     d("item_base: nil")
    -- end
    -- d("trait_mat_name: " .. tostring(self.trait_mat_name))
    -- d("motif_mat_name: " .. tostring(self.motif_mat_name))

    -- if self.improve_level then
    --     d("improve_level.ct: " .. tostring(self.improve_level.green_mat_ct)
    --                     .. "/" .. tostring(self.improve_level.blue_mat_ct)
    --                     .. "/" .. tostring(self.improve_level.purple_mat_ct)
    --                     .. "/" .. tostring(self.improve_level.gold_mat_ct))
    -- else
    --     d("improve_level: nil")
    -- end

    -- d("voucher_ct: " .. tostring(self.voucher_ct))

    MatRow.ListDump(self.mat_list)
end

function SmithItem:TooltipText()
    local mat_total  = MatRow.ListTotal(self.mat_list)
    local total_text = "Mat total: " .. WritWorthy.ToMoney(mat_total) .. "g"

    local purchase_total = 0
    local purchase_text  = ""
    if self.purchase_gold then
        purchase_total = self.purchase_gold
        purchase_text = "Purchase: " .. WritWorthy.ToMoney(self.purchase_gold) .. "g"
    end

    local voucher_ct = tonumber(self.voucher_ct)
    local per_voucher_text = ""
    if 0 < voucher_ct then
        local total = mat_total + purchase_total
        local p = total / voucher_ct
        per_voucher_text = "Per voucher: " .. WritWorthy.ToMoney(p) .. "g"
    end

    if not purchase_text then
        return total_text .. "  " .. per_voucher_text
    end

    return total_text .. "  " .. purchase_text .. "\n" .. per_voucher_text
end

-- WritWorthy ================================================================

function WritWorthy.MMPrice(link)
    if not MasterMerchant then return nil end
    if not link then return nil end
    local mm = MasterMerchant:itemStats(link, false)
    if not mm then return nil end
    if mm.avgPrice and 0 < mm.avgPrice then
        return mm.avgPrice
    end

                        -- Normal price lookup came up empty, try an
                        -- expanded time range.
                        --
                        -- MasterMerchant lacks an API to control time range,
                        -- it does this internally by polling the state of
                        -- control/shift-key modifiers (!) so we monkey-patch
                        -- MM with our own code that ignores modifier keys
                        -- and always returns a LOOONG time range
    local save_tc = MasterMerchant.TimeCheck
    MasterMerchant.TimeCheck
        = function(self)
            local daysRange = 100  -- 3+ months is long enough.
            return GetTimeStamp() - (86400 * daysRange), daysRange
          end
    mm = MasterMerchant:itemStats(link, false)
    MasterMerchant.TimeCheck = save_tc

    if not mm then return nil end
    return mm.avgPrice
end

-- Tooltip Intercept ---------------------------------------------------------

-- Monkey-patch ZOS' ItemTooltip with our own after-overrides. Lets ZOS code
-- create and show the original tooltip, and then we come in and insert our
-- own stuff.
--
-- Based on CraftStore's CS.TooltipHandler().
--
function WritWorthy.TooltipInterceptInstall()
    local tt=ItemTooltip.SetBagItem
    ItemTooltip.SetBagItem=function(control,bagId,slotIndex,...)
        tt(control,bagId,slotIndex,...)
        WritWorthy.TooltipInsertOurText(control,GetItemLink(bagId,slotIndex))
    end
    local tt=ItemTooltip.SetLootItem
    ItemTooltip.SetLootItem=function(control,lootId,...)
        tt(control,lootId,...)
        WritWorthy.TooltipInsertOurText(control,GetLootItemLink(lootId))
    end
    local tt=PopupTooltip.SetLink
    PopupTooltip.SetLink=function(control,link,...)
        tt(control,link,...)
        WritWorthy.TooltipInsertOurText(control,link)
    end
    local tt=ItemTooltip.SetTradingHouseItem
    ItemTooltip.SetTradingHouseItem=function(control,tradingHouseIndex,...)
        tt(control,tradingHouseIndex,...)
        local _,_,_,_,_,_,purchase_gold = GetTradingHouseSearchResultItemInfo(tradingHouseIndex)
        WritWorthy.TooltipInsertOurText(control
                , GetTradingHouseSearchResultItemLink(tradingHouseIndex)
                , purchase_gold
                )
    end
end

-- Hook to let us add stuff to a tooltip.
--
-- control:  the tooltip, responds to :AddLine(text)
-- link:     the item whose tip ZOScode is showing.
--
function WritWorthy.TooltipInsertOurText(control, item_link, purchase_gold)
    -- Only fire for master writs.
    if ITEMTYPE_MASTER_WRIT ~= GetItemLinkItemType(item_link) then return end

    local smith_item = SmithItem:FromLink(item_link, purchase_gold)
    if not smith_item then return end
    smith_item:CollectMatList()
    smith_item:DebugDump()

    control:AddLine(smith_item:TooltipText())
end

-- Init ----------------------------------------------------------------------

function WritWorthy.OnAddOnLoaded(event, addonName)
    if addonName ~= WritWorthy.name then return end
    if not WritWorthy.version then return end
    WritWorthy:Initialize()
end

function WritWorthy:Initialize()
    WritWorthy.TooltipInterceptInstall()
    --EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)
end

-- Postamble -----------------------------------------------------------------

EVENT_MANAGER:RegisterForEvent( WritWorthy.name
                              , EVENT_ADD_ON_LOADED
                              , WritWorthy.OnAddOnLoaded
                              )

