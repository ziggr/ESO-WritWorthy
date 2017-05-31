-- Parse a Blacksmithing/Clothier/Woodworking master writ.

local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Define.lua

WritWorthy.Smithing = {}

local Smithing = WritWorthy.Smithing
local Util     = WritWorthy.Util
local Fail     = WritWorthy.Util.Fail
local Log      = WritWorthy.Log

-- Schools: HVY MED LGT WOOD -------------------------------------------------
--
-- Clothing split into two since base mats differ (silk vs. leather).
--
-- "research lines" values are indices to pass as arg#2 to
-- GetSmithingResearchLineTraitInfo() to see which
-- traits we know about that item, or if we know enough traits to craft
-- the requested set bonus for that item.
-- "research lines" values learned by iterating over calls to
-- GetSmithingResearchLineInfo(trade_skill_type, i)
--
Smithing.SCHOOL_HEAVY =  {
    trade_skill_type    = CRAFTING_TYPE_BLACKSMITHING
,   base_mat_name       = "rubedite"
,   green_mat_name      = "honing stone"
,   blue_mat_name       = "dwarven oil"
,   purple_mat_name     = "grain solvent"
,   gold_mat_name       = "tempering alloy"
,   armor_weight_name   = "Heavy"
    -- research lines
,   H1_AXE              =  1
,   H1_MACE             =  2
,   H1_SWORD            =  3
,   H2_BATTLE_AXE       =  4
,   H2_MAUL             =  5
,   H2_GREATSSWORD      =  6
,   DAGGER              =  7
,   CHEST               =  8
,   FEET                =  9
,   HANDS               = 10
,   HEAD                = 11
,   LEGS                = 12
,   SHOULDERS           = 13
,   WAIST               = 14
}

Smithing.SCHOOL_MEDIUM = {
    trade_skill_type    = CRAFTING_TYPE_CLOTHIER
,   base_mat_name       = "rubedo leather"
,   green_mat_name      = "hemming"
,   blue_mat_name       = "embroidery"
,   purple_mat_name     = "elegant lining"
,   gold_mat_name       = "dreugh wax"
,   armor_weight_name   = "Medium"
    -- research lines
,   CHEST               =  8
,   FEET                =  9
,   HANDS               = 10
,   HEAD                = 11
,   LEGS                = 12
,   SHOULDERS           = 13
,   WAIST               = 14
}

Smithing.SCHOOL_LIGHT  = {
    trade_skill_type    = CRAFTING_TYPE_CLOTHIER
,   base_mat_name       = "ancestor silk"
,   green_mat_name      = "hemming"
,   blue_mat_name       = "embroidery"
,   purple_mat_name     = "elegant lining"
,   gold_mat_name       = "dreugh wax"
,   armor_weight_name   = "Light"
    -- research lines
,   CHEST               =  1
,   FEET                =  2
,   HANDS               =  3
,   HEAD                =  4
,   LEGS                =  5
,   SHOULDERS           =  6
,   WAIST               =  7
}

Smithing.SCHOOL_WOOD   = {
    trade_skill_type    = CRAFTING_TYPE_WOODWORKING
,   base_mat_name       = "ruby ash"
,   green_mat_name      = "pitch"
,   blue_mat_name       = "turpen"
,   purple_mat_name     = "mastic"
,   gold_mat_name       = "rosin"
,   armor_weight_name   = ""
    -- research lines
,   BOW                 =  1
,   FLAME_STAFF         =  2
,   ICE_STAFF           =  3
,   LIGHTNING_STAFF     =  4
,   RESTO_STAFF         =  5
,   SHIELD              =  6
}

-- Traits --------------------------------------------------------------------
--
-- Weapon and Armor must be separate sets because "Nirnhoned" mats differ
-- (potent vs. fortified nirncrux)
--
-- Table keys here are item_link writ5 numbers
-- and appear to match ITEM_TYPE_XXXX_XXXX constants
--
-- trait_index numbers are indices into research lines.
-- Gleaned through calls to
--  GetSmithingResearchLineTraitInfo(
--              trade_skill_type
--            , research_line     -- from Smithing.SCHOOL_XXX.CHEST and such
--            , i                 -- 1..9
--            )
--
Smithing.TRAITS_WEAPON = {
    [ITEM_TRAIT_TYPE_WEAPON_POWERED    ] = { trait_name = "powered",      mat_name = "chysolite"          , trait_index = 1 }
,   [ITEM_TRAIT_TYPE_WEAPON_CHARGED    ] = { trait_name = "charged",      mat_name = "amethyst"           , trait_index = 2 }
,   [ITEM_TRAIT_TYPE_WEAPON_PRECISE    ] = { trait_name = "precise",      mat_name = "ruby"               , trait_index = 3 }
,   [ITEM_TRAIT_TYPE_WEAPON_INFUSED    ] = { trait_name = "infused",      mat_name = "jade"               , trait_index = 4 }
,   [ITEM_TRAIT_TYPE_WEAPON_DEFENDING  ] = { trait_name = "defending",    mat_name = "turquoise"          , trait_index = 5 }
,   [ITEM_TRAIT_TYPE_WEAPON_TRAINING   ] = { trait_name = "training",     mat_name = "carnelian"          , trait_index = 6 }
,   [ITEM_TRAIT_TYPE_WEAPON_SHARPENED  ] = { trait_name = "sharpened",    mat_name = "fire opal"          , trait_index = 7 }
,   [ITEM_TRAIT_TYPE_WEAPON_DECISIVE   ] = { trait_name = "decisive",     mat_name = "citrine"            , trait_index = 8 }  -- nee weighted
,   [ITEM_TRAIT_TYPE_WEAPON_NIRNHONED  ] = { trait_name = "nirnhoned",    mat_name = "potent nirncrux"    , trait_index = 9 }
}
Smithing.TRAITS_ARMOR    = {
    [ITEM_TRAIT_TYPE_ARMOR_STURDY      ] = { trait_name = "sturdy",       mat_name = "quartz"             , trait_index = 1 }
,   [ITEM_TRAIT_TYPE_ARMOR_IMPENETRABLE] = { trait_name = "impenetrable", mat_name = "diamond"            , trait_index = 2 }
,   [ITEM_TRAIT_TYPE_ARMOR_REINFORCED  ] = { trait_name = "reinforced",   mat_name = "sardonyx"           , trait_index = 3 }
,   [ITEM_TRAIT_TYPE_ARMOR_WELL_FITTED ] = { trait_name = "well-fitted",  mat_name = "almandine"          , trait_index = 4 }
,   [ITEM_TRAIT_TYPE_ARMOR_TRAINING    ] = { trait_name = "training",     mat_name = "emerald"            , trait_index = 5 }
,   [ITEM_TRAIT_TYPE_ARMOR_INFUSED     ] = { trait_name = "infused",      mat_name = "bloodstone"         , trait_index = 6 }
,   [ITEM_TRAIT_TYPE_ARMOR_PROSPEROUS  ] = { trait_name = "prosperous",   mat_name = "garnet"             , trait_index = 7 } -- nee exploration
,   [ITEM_TRAIT_TYPE_ARMOR_DIVINES     ] = { trait_name = "divines",      mat_name = "sapphire"           , trait_index = 8 }
,   [ITEM_TRAIT_TYPE_ARMOR_NIRNHONED   ] = { trait_name = "nirnhoned",    mat_name = "fortified nirncrux" , trait_index = 9 }
}

-- Motifs --------------------------------------------------------------------
--
-- Table index is writ6
--
-- is_simple = motifs that only come in complete books, no separate pages.
-- crown_id  = motifs that only come in complete books from the Crown store.
--             Motifs that come only in complete books, the function
--             IsSmithingStyleKnown() accurately returns whether you've
--             learned the whole book.
-- pages_id  = The achievement ID that goes with learning a page of a motif.
--             IDs from CraftStore Fixed and Improved.
--

Smithing.MOTIF = {
    [ITEMSTYLE_RACIAL_BRETON        ] = { mat_name = "molybdenum"          , motif_name = "Breton"               , is_simple = true } -- 01
,   [ITEMSTYLE_RACIAL_REDGUARD      ] = { mat_name = "starmetal"           , motif_name = "Redguard"             , is_simple = true } -- 02
,   [ITEMSTYLE_RACIAL_ORC           ] = { mat_name = "manganese"           , motif_name = "Orc"                  , is_simple = true } -- 03
,   [ITEMSTYLE_RACIAL_DARK_ELF      ] = { mat_name = "obsidian"            , motif_name = "Dunmer"               , is_simple = true } -- 04
,   [ITEMSTYLE_RACIAL_NORD          ] = { mat_name = "corundum"            , motif_name = "Nord"                 , is_simple = true } -- 05
,   [ITEMSTYLE_RACIAL_ARGONIAN      ] = { mat_name = "flint"               , motif_name = "Argonian"             , is_simple = true } -- 06
,   [ITEMSTYLE_RACIAL_HIGH_ELF      ] = { mat_name = "adamantite"          , motif_name = "Altmer"               , is_simple = true } -- 07
,   [ITEMSTYLE_RACIAL_WOOD_ELF      ] = { mat_name = "bone"                , motif_name = "Bosmer"               , is_simple = true } -- 08
,   [ITEMSTYLE_RACIAL_KHAJIIT       ] = { mat_name = "moonstone"           , motif_name = "Khajiit"              , is_simple = true } -- 09
,   [ITEMSTYLE_UNIQUE               ] = nil --                             , motif_name = "Unique"               } -- 10
,   [ITEMSTYLE_ORG_THIEVES_GUILD    ] = { mat_name = "fine chalk"          , motif_name = "Thieves Guild"        , pages_id  = 1423 } -- 11
,   [ITEMSTYLE_ORG_DARK_BROTHERHOOD ] = { mat_name = "black beeswax"       , motif_name = "Dark Brotherhood"     , pages_id  = 1661 } -- 12
,   [ITEMSTYLE_DEITY_MALACATH       ] = { mat_name = "potash"              , motif_name = "Malacath"             , pages_id  = 1412 } -- 13
,   [ITEMSTYLE_AREA_DWEMER          ] = { mat_name = "dwemer frame"        , motif_name = "Dwemer"               , pages_id  = 1144 } -- 14
,   [ITEMSTYLE_AREA_ANCIENT_ELF     ] = { mat_name = "palladium"           , motif_name = "Ancient Elf"          , is_simple = true } -- 15
,   [ITEMSTYLE_DEITY_AKATOSH        ] = { mat_name = "pearl sand"          , motif_name = "Order of the Hour"    , pages_id  = 1660 } -- 16
,   [ITEMSTYLE_AREA_REACH           ] = { mat_name = "copper"              , motif_name = "Barbaric"             , is_simple = true } -- 17
,   [ITEMSTYLE_ENEMY_BANDIT         ] = nil --                             , motif_name = "Bandit"               } -- 18
,   [ITEMSTYLE_ENEMY_PRIMITIVE      ] = { mat_name = "argentum"            , motif_name = "Primal"               , is_simple = true } -- 19
,   [ITEMSTYLE_ENEMY_DAEDRIC        ] = { mat_name = "daedra heart"        , motif_name = "Daedric"              , is_simple = true } -- 20
,   [ITEMSTYLE_DEITY_TRINIMAC       ] = { mat_name = "auric tusk"          , motif_name = "Trinimac"             , pages_id  = 1411 } -- 21
,   [ITEMSTYLE_AREA_ANCIENT_ORC     ] = { mat_name = "cassiterite"         , motif_name = "Ancient Orc"          , pages_id  = 1341 } -- 22
,   [ITEMSTYLE_ALLIANCE_DAGGERFALL  ] = { mat_name = "lion fang"           , motif_name = "Daggerfall Covenant"  , pages_id  = 1416 } -- 23
,   [ITEMSTYLE_ALLIANCE_EBONHEART   ] = { mat_name = "dragon scute"        , motif_name = "Ebonheart Pact"       , pages_id  = 1414 } -- 24
,   [ITEMSTYLE_ALLIANCE_ALDMERI     ] = { mat_name = "eagle feather"       , motif_name = "Aldmeri Dominion"     , pages_id  = 1415 } -- 25
,   [ITEMSTYLE_UNDAUNTED            ] = { mat_name = "laurel"              , motif_name = "Mercenary"            , pages_id  = 1348 } -- 26
,   [ITEMSTYLE_RAIDS_CRAGLORN       ] = { mat_name = "star sapphire"       , motif_name = "Celestial"            , pages_id  = 1714 } -- 27
,   [ITEMSTYLE_GLASS                ] = { mat_name = "malachite"           , motif_name = "Glass"                , pages_id  = 1319 } -- 28
,   [ITEMSTYLE_AREA_XIVKYN          ] = { mat_name = "charcoal of remorse" , motif_name = "Xivkyn"               , pages_id  = 1181 } -- 29
,   [ITEMSTYLE_AREA_SOUL_SHRIVEN    ] = { mat_name = "azure plasm"         , motif_name = "Soul-Shriven"         , is_simple = true } -- 30
,   [ITEMSTYLE_ENEMY_DRAUGR         ] = { mat_name = "pristine shroud"     , motif_name = "Draugr"               , pages_id  = 1715 } -- 31
,   [ITEMSTYLE_ENEMY_MAORMER        ] = nil --                             , motif_name = "Maormer"              } -- 32
,   [ITEMSTYLE_AREA_AKAVIRI         ] = { mat_name = "goldscale"           , motif_name = "Akaviri"              , pages_id  = 1318 } -- 33
,   [ITEMSTYLE_RACIAL_IMPERIAL      ] = { mat_name = "nickel"              , motif_name = "Imperial"             , is_simple = true } -- 34
,   [ITEMSTYLE_AREA_YOKUDAN         ] = { mat_name = "ferrous salts"       , motif_name = "Yokudan"              , pages_id  = 1713 } -- 35
,   [ITEMSTYLE_UNIVERSAL            ] = nil --                             , motif_name = "unused"               } -- 36
,   [ITEMSTYLE_AREA_REACH_WINTER    ] = nil --                             , motif_name = "Reach Winter"         } -- 37
,   [ITEMSTYLE_AREA_TSAESCI         ] = nil --                             , motif_name = "Worm Cult"            } -- 38
,   [ITEMSTYLE_ENEMY_MINOTAUR       ] = { mat_name = "oxblood fungus"      , motif_name = "Minotaur"             , pages_id  = 1662 } -- 39
,   [ITEMSTYLE_EBONY                ] = { mat_name = "night pumice"        , motif_name = "Ebony"                , pages_id  = 1798 } -- 40
,   [ITEMSTYLE_ORG_ABAHS_WATCH      ] = { mat_name = "polished shilling"   , motif_name = "Abah's Watch"         , pages_id  = 1422 } -- 41
,   [ITEMSTYLE_HOLIDAY_SKINCHANGER  ] = { mat_name = "wolfsbane incense"   , motif_name = "Skinchanger"          , pages_id  = 1676 } -- 42
,   [ITEMSTYLE_ORG_MORAG_TONG       ] = { mat_name = "boiled carapace"     , motif_name = "Morag Tong"           , pages_id  = 1933 } -- 43
,   [ITEMSTYLE_AREA_RA_GADA         ] = { mat_name = "ancient sandstone"   , motif_name = "Ra Gada"              , pages_id  = 1797 } -- 44
,   [ITEMSTYLE_ENEMY_DROMOTHRA      ] = { mat_name = "defiled whiskers"    , motif_name = "Dro-m'Athra"          , pages_id  = 1659 } -- 45
,   [ITEMSTYLE_ORG_ASSASSINS        ] = { mat_name = "tainted blood"       , motif_name = "Assassins League"     , pages_id  = 1424 } -- 46
,   [ITEMSTYLE_ORG_OUTLAW           ] = { mat_name = "rogue's soot"        , motif_name = "Outlaw"               , pages_id  = 1417 } -- 47
,   [ITEMSTYLE_ORG_REDORAN           ] = nil --                             , motif_name = Unused 11"             } -- 48
,   [ITEMSTYLE_ORG_HLAALU            ] = nil --                             , motif_name = Unused 11"             } -- 49
,   [ITEMSTYLE_ORG_ORDINATOR         ] = { mat_name = "lustrous sphalerite" , motif_name = "Militant Ordinator"  , pages_id   = 1935  } -- 50
,   [ITEMSTYLE_ORG_TELVANNI          ] = nil --                             , motif_name = Unused 11"             } -- 51
,   [ITEMSTYLE_ORG_BUOYANT_ARMIGER   ] = { mat_name = "volcanic viridian"   , motif_name = "Buoyant Armiger"      , pages_id  = 1934  } -- 52
,   [ITEMSTYLE_HOLIDAY_FROSTCASTER   ] = { mat_name = "stahlrim shard"      , motif_name = "Stalhrim Frostcaster" , crown_id  = 96954 } -- 53
,   [ITEMSTYLE_AREA_ASHLANDER        ] = { mat_name = "ash canvas"          , motif_name = "Ashlander"            , pages_id  = 1932  } -- 54
,   [ITEMSTYLE_ORG_WORM_CULT         ] = nil --                             , motif_name = Unused 11"             } -- 55
,   [ITEMSTYLE_ENEMY_SILKEN_RING     ] = { mat_name = "distilled slowsilver", motif_name = "Silken Ring"          , pages_id  = 1796 } -- 56
,   [ITEMSTYLE_ENEMY_MAZZATUN        ] = { mat_name = "leviathan scrimshaw" , motif_name = "Mazzatun"             , pages_id  = 1795 } -- 57
,   [ITEMSTYLE_HOLIDAY_GRIM_HARLEQUIN] = { mat_name = "grinstones"          , motif_name = "Grim Harlequin"       , crown_id  = 82039 } -- 58
,   [ITEMSTYLE_HOLIDAY_HOLLOWJACK    ] = { mat_name = "amber marble"        , motif_name = "Hollowjack"           , pages_id  = 1545 } -- 59
,   [ITEMSTYLE_UNUSED1               ] = nil --                             , motif_name = Unused 11"             } -- 60
,   [ITEMSTYLE_UNUSED2               ] = nil --                             , motif_name = Unused 11"             } -- 61
,   [ITEMSTYLE_UNUSED3               ] = nil --                             , motif_name = Unused 11"             } -- 62
,   [ITEMSTYLE_UNUSED4               ] = nil --                             , motif_name = Unused 11"             } -- 63
,   [ITEMSTYLE_UNUSED5               ] = nil --                             , motif_name = Unused 11"             } -- 64
,   [ITEMSTYLE_UNUSED6               ] = nil --                             , motif_name = Unused 11"             } -- 65
,   [ITEMSTYLE_UNUSED7               ] = nil --                             , motif_name = Unused 11"             } -- 66
,   [ITEMSTYLE_UNUSED8               ] = nil --                             , motif_name = Unused 11"             } -- 67
,   [ITEMSTYLE_UNUSED9               ] = nil --                             , motif_name = Unused 11"             } -- 68
,   [ITEMSTYLE_UNUSED10              ] = nil --                             , motif_name = Unused 11"             } -- 69
,   [ITEMSTYLE_UNUSED11              ] = nil --                             , motif_name = Unused 11"             } -- 70
,   [ITEMSTYLE_UNUSED12              ] = nil --                             , motif_name = Unused 11"             } -- 71
,   [ITEMSTYLE_UNUSED13              ] = nil --                             , motif_name = Unused 11"             } -- 72
,   [ITEMSTYLE_UNUSED14              ] = nil --                             , motif_name = Unused 11"             } -- 73
,   [ITEMSTYLE_UNUSED15              ] = nil --                             , motif_name = Unused 11"             } -- 74
,   [ITEMSTYLE_UNUSED16              ] = nil --                             , motif_name = Unused 11"             } -- 75
,   [ITEMSTYLE_UNUSED17              ] = nil --                             , motif_name = Unused 11"             } -- 76
,   [ITEMSTYLE_UNUSED18              ] = nil --                             , motif_name = Unused 11"             } -- 77
,   [ITEMSTYLE_UNUSED19              ] = nil --                             , motif_name = Unused 11"             } -- 78
,   [ITEMSTYLE_UNUSED20              ] = nil --                             , motif_name = Unused 11"             } -- 79
,   [ITEMSTYLE_MAX_VALUE             ] = nil --                             , motif_name = Unused 11"             } -- 79
}

-- Motif page numbers --------------------------------------------------------
--
-- For checking whether we know the motif page for a requested item
--
Smithing.MOTIF_PAGE = {
    AXES       =  1
,   BELTS      =  2
,   BOOTS      =  3
,   BOWS       =  4
,   CHESTS     =  5
,   DAGGERS    =  6
,   GLOVES     =  7
,   HELMETS    =  8
,   LEGS       =  9
,   MACES      = 10
,   SHIELDS    = 11
,   SHOULDERS  = 12
,   STAVES     = 13
,   SWORDS     = 14
}

-- Requestable items ---------------------------------------------------------
--
-- Material, trait, and motif page requirements for each possitble Master
-- Writ BS/CL/WW item.
--
-- table index and item_id are writ1
-- item_name        no longer used, retained here to document each line.
-- school           tells which set of crafting materials and research lines to use.
-- base_mat_ct      is how many Rubedite/Silk/whatever to use to create a CP150 item.
-- trait_set        picks between armor and and weapon traits. writ5.
-- research_line    is the researchLineIndex argument to
--                      GetSmithingResearchLineTraitInfo() to see if we know the
--                      correct and enough traits.
-- motif_page       is which of the 1..14 motif pages applies to this item.
-- dol_pattern_index is a value for Dolgubon's Lazy Writ Crafter, patternIndex enum.
--
                        -- abbreviations to make the table more concise.
local HVY    = Smithing.SCHOOL_HEAVY
local MED    = Smithing.SCHOOL_MEDIUM
local LGT    = Smithing.SCHOOL_LIGHT
local WW     = Smithing.SCHOOL_WOOD
local WEAPON = Smithing.TRAITS_WEAPON
local ARMOR  = Smithing.TRAITS_ARMOR
local PG     = Smithing.MOTIF_PAGE

Smithing.REQUEST_ITEMS = {
  [53] = { item_id = 53, item_name = "Rubedite Axe",                school = HVY, base_mat_ct = 11, trait_set = WEAPON, research_line = HVY.H1_AXE,         motif_page = PG.AXES     , dol_pattern_index =  1 }
, [56] = { item_id = 56, item_name = "Rubedite Mace",               school = HVY, base_mat_ct = 11, trait_set = WEAPON, research_line = HVY.H1_MACE,        motif_page = PG.MACES    , dol_pattern_index =  2 }
, [59] = { item_id = 59, item_name = "Rubedite Sword",              school = HVY, base_mat_ct = 11, trait_set = WEAPON, research_line = HVY.H1_SWORD,       motif_page = PG.SWORDS   , dol_pattern_index =  3 }
, [68] = { item_id = 68, item_name = "Rubedite Greataxe",           school = HVY, base_mat_ct = 14, trait_set = WEAPON, research_line = HVY.H2_BATTLE_AXE,  motif_page = PG.AXES     , dol_pattern_index =  4 }
, [67] = { item_id = 67, item_name = "Rubedite Greatsword",         school = HVY, base_mat_ct = 14, trait_set = WEAPON, research_line = HVY.H2_GREATSSWORD, motif_page = PG.SWORDS   , dol_pattern_index =  5 }
, [69] = { item_id = 69, item_name = "Rubedite Maul",               school = HVY, base_mat_ct = 14, trait_set = WEAPON, research_line = HVY.H2_MAUL,        motif_page = PG.MACES    , dol_pattern_index =  6 }
, [62] = { item_id = 62, item_name = "Rubedite Dagger",             school = HVY, base_mat_ct = 10, trait_set = WEAPON, research_line = HVY.DAGGER,         motif_page = PG.DAGGERS  , dol_pattern_index =  7 }

, [46] = { item_id = 46, item_name = "Rubedite Cuirass",            school = HVY, base_mat_ct = 15, trait_set = ARMOR , research_line = HVY.CHEST,          motif_page = PG.CHESTS   , dol_pattern_index =  8 }
, [50] = { item_id = 50, item_name = "Rubedite Sabatons",           school = HVY, base_mat_ct = 13, trait_set = ARMOR , research_line = HVY.FEET,           motif_page = PG.BOOTS    , dol_pattern_index =  9 }
, [52] = { item_id = 52, item_name = "Rubedite Gauntlets",          school = HVY, base_mat_ct = 13, trait_set = ARMOR , research_line = HVY.HANDS,          motif_page = PG.GLOVES   , dol_pattern_index = 10 }
, [44] = { item_id = 44, item_name = "Rubedite Helm",               school = HVY, base_mat_ct = 13, trait_set = ARMOR , research_line = HVY.HEAD,           motif_page = PG.HELMETS  , dol_pattern_index = 11 }
, [49] = { item_id = 49, item_name = "Rubedite Greaves",            school = HVY, base_mat_ct = 14, trait_set = ARMOR , research_line = HVY.LEGS,           motif_page = PG.LEGS     , dol_pattern_index = 12 }
, [47] = { item_id = 47, item_name = "Rubedite Pauldron",           school = HVY, base_mat_ct = 13, trait_set = ARMOR , research_line = HVY.SHOULDERS,      motif_page = PG.SHOULDERS, dol_pattern_index = 13 }
, [48] = { item_id = 48, item_name = "Rubedite Girdle",             school = HVY, base_mat_ct = 13, trait_set = ARMOR , research_line = HVY.WAIST,          motif_page = PG.BELTS    , dol_pattern_index = 14 }

, [28] = { item_id = 28, item_name = "Ancestor Silk Robe",          school = LGT, base_mat_ct = 15, trait_set = ARMOR , research_line = LGT.CHEST,          motif_page = PG.CHESTS   , dol_pattern_index =  1 }
, [ 0] = { item_id =  0, item_name = "Ancestor Silk Jerkin",        school = LGT, base_mat_ct = 15, trait_set = ARMOR , research_line = LGT.CHEST,          motif_page = PG.CHESTS   , dol_pattern_index =  2 }
, [32] = { item_id = 32, item_name = "Ancestor Silk Shoes",         school = LGT, base_mat_ct = 13, trait_set = ARMOR , research_line = LGT.FEET,           motif_page = PG.BOOTS    , dol_pattern_index =  3 }
, [34] = { item_id = 34, item_name = "Ancestor Silk Gloves",        school = LGT, base_mat_ct = 13, trait_set = ARMOR , research_line = LGT.HANDS,          motif_page = PG.GLOVES   , dol_pattern_index =  4 }
, [26] = { item_id = 26, item_name = "Ancestor Silk Hat",           school = LGT, base_mat_ct = 13, trait_set = ARMOR , research_line = LGT.HEAD,           motif_page = PG.HELMETS  , dol_pattern_index =  5 }
, [31] = { item_id = 31, item_name = "Ancestor Silk Breeches",      school = LGT, base_mat_ct = 14, trait_set = ARMOR , research_line = LGT.LEGS,           motif_page = PG.LEGS     , dol_pattern_index =  6 }
, [29] = { item_id = 29, item_name = "Ancestor Silk Epaulets",      school = LGT, base_mat_ct = 13, trait_set = ARMOR , research_line = LGT.SHOULDERS,      motif_page = PG.SHOULDERS, dol_pattern_index =  7 }
, [30] = { item_id = 30, item_name = "Ancestor Silk Sash",          school = LGT, base_mat_ct = 13, trait_set = ARMOR , research_line = LGT.WAIST,          motif_page = PG.BELTS    , dol_pattern_index =  8 }

, [37] = { item_id = 37, item_name = "Rubedo Leather Jack",         school = MED, base_mat_ct = 15, trait_set = ARMOR , research_line = MED.CHEST,          motif_page = PG.CHESTS   , dol_pattern_index =  9 }
, [41] = { item_id = 41, item_name = "Rubedo Leather Boots",        school = MED, base_mat_ct = 13, trait_set = ARMOR , research_line = MED.FEET,           motif_page = PG.BOOTS    , dol_pattern_index = 10 }
, [43] = { item_id = 43, item_name = "Rubedo Leather Bracers",      school = MED, base_mat_ct = 13, trait_set = ARMOR , research_line = MED.HANDS,          motif_page = PG.GLOVES   , dol_pattern_index = 11 }
, [35] = { item_id = 35, item_name = "Rubedo Leather Helmet",       school = MED, base_mat_ct = 13, trait_set = ARMOR , research_line = MED.HEAD,           motif_page = PG.HELMETS  , dol_pattern_index = 12 }
, [40] = { item_id = 40, item_name = "Rubedo Leather Guards",       school = MED, base_mat_ct = 14, trait_set = ARMOR , research_line = MED.LEGS,           motif_page = PG.LEGS     , dol_pattern_index = 13 }
, [38] = { item_id = 38, item_name = "Rubedo Leather Arm Cops",     school = MED, base_mat_ct = 13, trait_set = ARMOR , research_line = MED.SHOULDERS,      motif_page = PG.SHOULDERS, dol_pattern_index = 14 }
, [39] = { item_id = 39, item_name = "Rubedo Leather Belt",         school = MED, base_mat_ct = 13, trait_set = ARMOR , research_line = MED.WAIST,          motif_page = PG.BELTS    , dol_pattern_index = 15 }

, [70] = { item_id = 70, item_name = "Ruby Ash Bow",                school = WW,  base_mat_ct = 12, trait_set = WEAPON, research_line = WW.BOW,             motif_page = PG.BOWS     , dol_pattern_index =  1 }
, [72] = { item_id = 72, item_name = "Ruby Ash Inferno Staff",      school = WW,  base_mat_ct = 12, trait_set = WEAPON, research_line = WW.FLAME_STAFF,     motif_page = PG.STAVES   , dol_pattern_index =  3 }
, [73] = { item_id = 73, item_name = "Ruby Ash Frost Staff",        school = WW,  base_mat_ct = 12, trait_set = WEAPON, research_line = WW.ICE_STAFF,       motif_page = PG.STAVES   , dol_pattern_index =  4 }
, [74] = { item_id = 74, item_name = "Ruby Ash Lightning Staff",    school = WW,  base_mat_ct = 12, trait_set = WEAPON, research_line = WW.LIGHTNING_STAFF, motif_page = PG.STAVES   , dol_pattern_index =  5 }
, [71] = { item_id = 71, item_name = "Ruby Ash Healing Staff",      school = WW,  base_mat_ct = 12, trait_set = WEAPON, research_line = WW.RESTO_STAFF,     motif_page = PG.STAVES   , dol_pattern_index =  6 }

, [65] = { item_id = 65, item_name = "Ruby Ash Shield",             school = WW,  base_mat_ct = 14, trait_set = ARMOR , research_line = WW.SHIELD,          motif_page = PG.SHIELDS  , dol_pattern_index =  2 }
}

-- Set Bonus required trait counts -------------------------------------------
--
-- How many traits must you know in order to craft an item with this
-- set bonus?
--
-- Table index is writ4 value for smithing writs.
--
-- dol_set_index is for Dolgubon's Lazy Set Crafter, an index into its own
--              internal table of craftable sets.
--              Brittle, likely to change. Could ask Dolgubon to publish
--              its table so that we could connect it up programmatically.
--
-- Learned by iterating over itemLink strings and dumping their baseText.
-- Dump still around somewhere in doc/item_link.txt.
--
Smithing.SET_BONUS = {
    [  1] = nil
  , [  2] = nil
  , [  3] = nil
  , [  4] = nil
  , [  5] = nil
  , [  6] = nil
  , [  7] = nil
  , [  8] = nil
  , [  9] = nil
 ,  [ 10] = nil
 ,  [ 11] = nil
 ,  [ 12] = nil
 ,  [ 13] = nil
 ,  [ 14] = nil
 ,  [ 15] = nil
 ,  [ 16] = nil
 ,  [ 17] = nil
 ,  [ 18] = nil
 ,  [ 19] = { name = "Vestments of the Warlock",                                         }
 ,  [ 20] = { name = "Witchman Armor",                                                   }
 ,  [ 21] = { name = "Akaviri Dragonguard",                                              }
 ,  [ 22] = { name = "Dreamer's Mantle",                                                 }
 ,  [ 23] = { name = "Archer's Mind",                                                    }
 ,  [ 24] = { name = "Footman's Fortune",                                                }
 ,  [ 25] = { name = "Desert Rose",                                                      }
 ,  [ 26] = { name = "Prisoner's Rags",                                                  }
 ,  [ 27] = { name = "Fiord's Legacy",                                                   }
 ,  [ 28] = { name = "Barkskin",                                                         }
 ,  [ 29] = { name = "Sergeant's Mail",                                                  }
 ,  [ 30] = { name = "Thunderbug's Carapace",                                            }
 ,  [ 31] = { name = "Silks of the Sun",                                                 }
 ,  [ 32] = { name = "Healer's Habit",                                                   }
 ,  [ 33] = { name = "Viper's Sting",                                                    }
 ,  [ 34] = { name = "Night Mother's Embrace",                                           }
 ,  [ 35] = { name = "Knightmare",                                                       }
 ,  [ 36] = { name = "Armor of the Veiled Heritance",                                    }
 ,  [ 37] = { name = "Death's Wind",                    trait_ct = 2, dol_set_index =  2 }
 ,  [ 38] = { name = "Twilight's Embrace",              trait_ct = 3, dol_set_index =  6 }
 ,  [ 39] = { name = "Alessian Order",                               }
 ,  [ 40] = { name = "Night's Silence",                 trait_ct = 2, dol_set_index =  3 }
 ,  [ 41] = { name = "Whitestrake's Retribution",       trait_ct = 4, dol_set_index = 10 }
 ,  [ 42] = nil
 ,  [ 43] = { name = "Armor of the Seducer",            trait_ct = 3, dol_set_index =  7 }
 ,  [ 44] = { name = "Vampire's Kiss",                  trait_ct = 5, dol_set_index = 11 }
 ,  [ 45] = nil
 ,  [ 46] = { name = "Noble Duelist's Silks",                                            }
 ,  [ 47] = { name = "Robes of the Withered Hand",                                       }
 ,  [ 48] = { name = "Magnus' Gift",                    trait_ct = 4, dol_set_index =  8 }
 ,  [ 49] = { name = "Shadow of the Red Mountain",                                       }
 ,  [ 50] = { name = "The Morag Tong",                                                   }
 ,  [ 51] = { name = "Night Mother's Gaze",             trait_ct = 6, dol_set_index = 14 }
 ,  [ 52] = { name = "Beckoning Steel",                                                  }
 ,  [ 53] = { name = "The Ice Furnace",                                                  }
 ,  [ 54] = { name = "Ashen Grip",                      trait_ct = 2, dol_set_index =  4 }
 ,  [ 55] = { name = "Prayer Shawl",                                                     }
 ,  [ 56] = { name = "Stendarr's Embrace",                                               }
 ,  [ 57] = { name = "Syrabane's Grip",                                                  }
 ,  [ 58] = { name = "Hide of the Werewolf",                                             }
 ,  [ 59] = { name = "Kyne's Kiss",                                                      }
 ,  [ 60] = { name = "Darkstride",                                                       }
 ,  [ 61] = { name = "Dreugh King Slayer",                                               }
 ,  [ 62] = { name = "Hatchling's Shell",                                                }
 ,  [ 63] = { name = "The Juggernaut",                                                   }
 ,  [ 64] = { name = "Shadow Dancer's Raiment",                                          }
 ,  [ 65] = { name = "Bloodthorn's Touch",                                               }
 ,  [ 66] = { name = "Robes of the Hist",                                                }
 ,  [ 67] = { name = "Shadow Walker",                                                    }
 ,  [ 68] = { name = "Stygian",                                                          }
 ,  [ 69] = { name = "Ranger's Gait",                                                    }
 ,  [ 70] = { name = "Seventh Legion Brute",                                             }
 ,  [ 71] = { name = "Durok's Bane",                                                     }
 ,  [ 72] = { name = "Nikulas' Heavy Armor",                                             }
 ,  [ 73] = { name = "Oblivion's Foe",                  trait_ct = 8, dol_set_index = 21 }
 ,  [ 74] = { name = "Spectre's Eye",                   trait_ct = 8, dol_set_index = 22 }
 ,  [ 75] = { name = "Torug's Pact",                    trait_ct = 3, dol_set_index =  5 }
 ,  [ 76] = { name = "Robes of Alteration Mastery",                                      }
 ,  [ 77] = { name = "Crusader",                                                         }
 ,  [ 78] = { name = "Hist Bark",                       trait_ct = 4, dol_set_index =  9 }
 ,  [ 79] = { name = "Willow's Path",                   trait_ct = 6, dol_set_index = 15 }
 ,  [ 80] = { name = "Hunding's Rage",                  trait_ct = 6, dol_set_index = 16 }
 ,  [ 81] = { name = "Song of Lamae",                   trait_ct = 5, dol_set_index = 12 }
 ,  [ 82] = { name = "Alessia's Bulwark",               trait_ct = 5, dol_set_index = 13 }
 ,  [ 83] = { name = "Elf Bane",                                                         }
 ,  [ 84] = { name = "Orgnum's Scales",                 trait_ct = 8, dol_set_index = 18 }
 ,  [ 85] = { name = "Almalexia's Mercy",                                                }
 ,  [ 86] = { name = "Queen's Elegance",                                                 }
 ,  [ 87] = { name = "Eyes of Mara",                    trait_ct = 8, dol_set_index = 19 }
 ,  [ 88] = { name = "Robes of Destruction Mastery",                                     }
 ,  [ 89] = { name = "Sentry",                                                           }
 ,  [ 90] = { name = "Senche's Bite",                                                    }
 ,  [ 91] = { name = "Oblivion's Edge",                                                  }
 ,  [ 92] = { name = "Kagrenac's Hope",                 trait_ct = 8, dol_set_index = 17 }
 ,  [ 93] = { name = "Storm Knight's Plate",                                             }
 ,  [ 94] = { name = "Meridia's Blessed Armor",                                          }
 ,  [ 95] = { name = "Shalidor's Curse",                trait_ct = 8, dol_set_index = 20 }
 ,  [ 96] = { name = "Armor of Truth",                                                   }
 ,  [ 97] = { name = "The Arch-Mage",                                                    }
 ,  [ 98] = { name = "Necropotence",                                                     }
 ,  [ 99] = { name = "Salvation",                                                        }
,   [100] = { name = "Hawk's Eye",                                                       }
,   [101] = { name = "Affliction",                                                       }
,   [102] = { name = "Duneripper's Scales",                                              }
,   [103] = { name = "Magicka Furnace",                                                  }
,   [104] = { name = "Curse Eater",                                                      }
,   [105] = { name = "Twin Sisters",                                                     }
,   [106] = { name = "Wilderqueen's Arch",                                               }
,   [107] = { name = "Wyrd Tree's Blessing",                                             }
,   [108] = { name = "Ravager",                                                          }
,   [109] = { name = "Light of Cyrodiil",                                                }
,   [110] = { name = "Sanctuary",                                                        }
,   [111] = { name = "Ward of Cyrodiil",                                                 }
,   [112] = { name = "Night Terror",                                                     }
,   [113] = { name = "Crest of Cyrodiil",                                                }
,   [114] = { name = "Soulshine",                                                        }
,   [115] = nil
,   [116] = { name = "The Destruction Suite",                                            }
,   [117] = { name = "Relics of the Physician, Ansur",                                   }
,   [118] = { name = "Treasures of the Earthforge",                                      }
,   [119] = { name = "Relics of the Rebellion",                                          }
,   [120] = { name = "Arms of Infernace",                                                }
,   [121] = { name = "Arms of the Ancestors",                                            }
,   [122] = { name = "Ebon Armory",                                                      }
,   [123] = { name = "Hircine's Veneer",                                                 }
,   [124] = { name = "The Worm's Raiment",                                               }
,   [125] = { name = "Wrath of the Imperium",                                            }
,   [126] = { name = "Grace of the Ancients",                                            }
,   [127] = { name = "Deadly Strike",                                                    }
,   [128] = { name = "Blessing of the Potentates",                                       }
,   [129] = { name = "Vengeance Leech",                                                  }
,   [130] = { name = "Eagle Eye",                                                        }
,   [131] = { name = "Bastion of the Heartland",                                         }
,   [132] = { name = "Shield of the Valiant",                                            }
,   [133] = { name = "Buffer of the Swift",                                              }
,   [134] = { name = "Shroud of the Lich",                                               }
,   [135] = { name = "Draugr's Heritage",                                                }
,   [136] = { name = "Immortal Warrior",                                                 }
,   [137] = { name = "Berserking Warrior",                                               }
,   [138] = { name = "Defending Warrior",                                                }
,   [139] = { name = "Wise Mage",                                                        }
,   [140] = { name = "Destructive Mage",                                                 }
,   [141] = { name = "Healing Mage",                                                     }
,   [142] = { name = "Quick Serpent",                                                    }
,   [143] = { name = "Poisonous Serpent",                                                }
,   [144] = { name = "Twice-Fanged Serpent",                                             }
,   [145] = { name = "Way of Fire",                                                      }
,   [146] = { name = "Way of Air",                                                       }
,   [147] = { name = "Way of Martial Knowledge",                                         }
,   [148] = { name = "Way of the Arena",                trait_ct = 8, dol_set_index = 23 }
,   [149] = nil
,   [150] = nil
,   [151] = nil
,   [152] = nil
,   [153] = nil
,   [154] = nil
,   [155] = { name = "Undaunted Bastion",                                                }
,   [156] = { name = "Undaunted Infiltrator",                                            }
,   [157] = { name = "Undaunted Unweaver",                                               }
,   [158] = { name = "Embershield",                                                      }
,   [159] = { name = "Sunderflame",                                                      }
,   [160] = { name = "Burning Spellweave",                                               }
,   [161] = { name = "Twice-Born Star",                 trait_ct = 9, dol_set_index = 24 }
,   [162] = { name = "Spawn of Mephala",                                                 }
,   [163] = { name = "Blood Spawn",                                                      }
,   [164] = { name = "Lord Warden",                                                      }
,   [165] = { name = "Scourge Harvester",                                                }
,   [166] = { name = "Engine Guardian",                                                  }
,   [167] = { name = "Nightflame",                                                       }
,   [168] = { name = "Nerien'eth",                                                       }
,   [169] = { name = "Valkyn Skoria",                                                    }
,   [170] = { name = "Maw of the Infernal",                                              }
,   [171] = { name = "Eternal Warrior",                                                  }
,   [172] = { name = "Infallible Mage",                                                  }
,   [173] = { name = "Vicious Serpent",                                                  }
,   [174] = nil
,   [175] = nil
,   [176] = { name = "Noble's Conquest",                trait_ct = 5, dol_set_index = 25 }
,   [177] = { name = "Redistributor",                   trait_ct = 7, dol_set_index = 26 }
,   [178] = { name = "Armor Master",                    trait_ct = 9, dol_set_index = 27 }
,   [179] = { name = "Black Rose",                                                       }
,   [180] = { name = "Powerful Assault",                                                 }
,   [181] = { name = "Meritorious Service",                                              }
,   [182] = nil
,   [183] = { name = "Molag Kena",                                                       }
,   [184] = { name = "Brands of Imperium",                                               }
,   [185] = { name = "Spell Power Cure",                                                 }
,   [186] = { name = "Jolting Arms",                                                     }
,   [187] = { name = "Swamp Raider",                                                     }
,   [188] = { name = "Storm Master",                                                     }
,   [189] = nil
,   [190] = { name = "Scathing Mage",                                                    }
,   [191] = nil
,   [192] = nil
,   [193] = { name = "Overwhelming Surge",                                               }
,   [194] = { name = "Combat Physician",                                                 }
,   [195] = { name = "Sheer Venom",                                                      }
,   [196] = { name = "Leeching Plate",                                                   }
,   [197] = { name = "Tormentor",                                                        }
,   [198] = { name = "Essence Thief",                                                    }
,   [199] = { name = "Shield Breaker",                                                   }
,   [200] = { name = "Phoenix",                                                          }
,   [201] = { name = "Reactive Armor",                                                   }
,   [202] = nil
,   [203] = nil
,   [204] = { name = "Endurance",                                                        }
,   [205] = { name = "Willpower",                                                        }
,   [206] = { name = "Agility",                                                          }
,   [207] = { name = "Law of Julianos",                 trait_ct = 6, dol_set_index = 29 }
,   [208] = { name = "Trial by Fire",                   trait_ct = 3, dol_set_index = 28 }
,   [209] = { name = "Armor of the Code",                                                }
,   [210] = { name = "Mark of the Pariah",                                               }
,   [211] = { name = "Permafrost",                                                       }
,   [212] = { name = "Briarheart",                                                       }
,   [213] = { name = "Glorious Defender",                                                }
,   [214] = { name = "Para Bellum",                                                      }
,   [215] = { name = "Elemental Succession",                                             }
,   [216] = { name = "Hunt Leader",                                                      }
,   [217] = { name = "Winterborn",                                                       }
,   [218] = { name = "Trinimac's Valor",                                                 }
,   [219] = { name = "Morkuldin",                       trait_ct = 9, dol_set_index = 30 }
,   [220] = nil
,   [221] = nil
,   [222] = nil
,   [223] = nil
,   [224] = { name = "Tava's Favor",                    trait_ct = 5, dol_set_index = 31 }
,   [225] = { name = "Clever Alchemist",                trait_ct = 7, dol_set_index = 32 }
,   [226] = { name = "Eternal Hunt",                    trait_ct = 9, dol_set_index = 33 }
,   [227] = { name = "Bahraha's Curse",                                                  }
,   [228] = { name = "Syvarra's Scales",                                                 }
,   [229] = { name = "Twilight Remedy",                                                  }
,   [230] = { name = "Moondancer",                                                       }
,   [231] = { name = "Lunar Bastion",                                                    }
,   [232] = { name = "Roar of Alkosh",                                                   }
,   [233] = nil
,   [234] = { name = "Marksman's Crest",                                                 }
,   [235] = { name = "Robes of Transmutation",                                           }
,   [236] = { name = "Vicious Death",                                                    }
,   [237] = { name = "Leki's Focus",                                                     }
,   [238] = { name = "Fasalla's Guile",                                                  }
,   [239] = { name = "Warrior's Fury",                                                   }
,   [240] = { name = "Kvatch Gladiator",                trait_ct = 6, dol_set_index = 34 }
,   [241] = { name = "Varen's Legacy",                  trait_ct = 7, dol_set_index = 35 }
,   [242] = { name = "Pelinal's Aptitude",              trait_ct = 9, dol_set_index = 36 }
,   [243] = { name = "Hide of Morihaus",                                                 }
,   [244] = { name = "Flanking Strategist",                                              }
,   [245] = { name = "Sithis' Touch",                                                    }
,   [246] = { name = "Galerion's Revenge",                                               }
,   [247] = { name = "Vicecanon of Venom",                                               }
,   [248] = { name = "Thews of the Harbinger",                                           }
,   [249] = nil
,   [250] = nil
,   [251] = nil
,   [252] = nil
,   [253] = { name = "Imperial Physique",                                                }
,   [254] = nil
,   [255] = nil
,   [256] = { name = "Mighty Chudan",                                                    }
,   [257] = { name = "Velidreth",                                                        }
,   [258] = { name = "Amber Plasm",                                                      }
,   [259] = { name = "Heem-Jas' Retribution",                                            }
,   [260] = { name = "Aspect of Mazzatun",                                               }
,   [261] = { name = "Gossamer",                                                         }
,   [262] = { name = "Widowmaker",                                                       }
,   [263] = { name = "Hand of Mephala",                                                  }
,   [264] = { name = "Giant Spider",                                                     }
,   [265] = { name = "Shadowrend",                                                       }
,   [266] = { name = "Kra'gh",                                                           }
,   [267] = { name = "Swarm Mother",                                                     }
,   [268] = { name = "Sentinel of Rkugamz",                                              }
,   [269] = { name = "Chokethorn",                                                       }
,   [270] = { name = "Slimecraw",                                                        }
,   [271] = { name = "Sellistrix",                                                       }
,   [272] = { name = "Infernal Guardian",                                                }
,   [273] = { name = "Ilambris",                                                         }
,   [274] = { name = "Iceheart",                                                         }
,   [275] = { name = "Stormfist",                                                        }
,   [276] = { name = "Tremorscale",                                                      }
,   [277] = { name = "Pirate Skeleton",                                                  }
,   [278] = { name = "The Troll King",                                                   }
,   [279] = { name = "Selene",                                                           }
,   [280] = { name = "Grothdarr",                                                        }
,   [281] = { name = "Armor of the Trainee",                                             }
,   [282] = { name = "Vampire Cloak",                                                    }
,   [283] = { name = "Sword-Singer",                                                     }
,   [284] = { name = "Order of Diagna",                                                  }
,   [285] = { name = "Vampire Lord",                                                     }
,   [286] = { name = "Spriggan's Thorns",                                                }
,   [287] = { name = "Green Pact",                                                       }
,   [288] = { name = "Beekeeper's Gear",                                                 }
,   [289] = { name = "Spinner's Garments",                                               }
,   [290] = { name = "Skooma Smuggler",                                                  }
,   [291] = { name = "Shalk Exoskeleton",                                                }
,   [292] = { name = "Mother's Sorrow",                                                  }
,   [293] = { name = "Plague Doctor",                                                    }
,   [294] = { name = "Ysgramor's Birthright",                                            }
,   [295] = { name = "Jailbreaker",                                                      }
,   [296] = { name = "Spelunker",                                                        }
,   [297] = { name = "Spider Cultist Cowl",                                              }
,   [298] = { name = "Light Speaker",                                                    }
,   [299] = { name = "Toothrow",                                                         }
,   [300] = { name = "Netch's Touch",                                                    }
,   [301] = { name = "Strength of the Automaton",                                        }
,   [302] = { name = "Leviathan",                                                        }
,   [303] = { name = "Lamia's Song",                                                     }
,   [304] = { name = "Medusa",                                                           }
,   [305] = { name = "Treasure Hunter",                                                  }
,   [306] = nil
,   [307] = { name = "Draugr Hulk",                                                      }
,   [308] = { name = "Bone Pirate's Tatters",                                            }
,   [309] = { name = "Knight-errant's Mail",                                             }
,   [310] = { name = "Sword Dancer",                                                     }
,   [311] = { name = "Rattlecage",                                                       }
,   [312] = { name = "Tremorscale",                                                      }
,   [313] = { name = "Masters Duel Wield",                                               }
,   [314] = { name = "Masters Two Handed",                                               }
,   [315] = { name = "Masters One Hand and Shield",                                      }
,   [316] = { name = "Masters Destruction Staff",                                        }
,   [317] = { name = "Masters Duel Wield",                                               }
,   [318] = { name = "Masters Restoration Staff",                                        }
,   [319] = nil
,   [320] = nil
,   [321] = nil
}

-- Improvement Material Counts -----------------------------------------------
--
-- Material counts for improving to purple or gold.
--
Smithing.PURPLE = {
    index          = 4
,   name           = "Epic"
,   green_mat_ct   = 2
,   blue_mat_ct    = 3
,   purple_mat_ct  = 4
,   gold_mat_ct    = 0
}

Smithing.GOLD = {
    index          = 5
,   name           = "Legendary"
,   green_mat_ct   = 2
,   blue_mat_ct    = 3
,   purple_mat_ct  = 4
,   gold_mat_ct    = 8
}

-- indices are item_link writ3 numbers (1-3 are white..blue, not used here)
Smithing.QUALITY = {
    [4] = Smithing.PURPLE
,   [5] = Smithing.GOLD
}

-- Parser ====================================================================

Smithing.Parser = {}
local Parser = Smithing.Parser

function Parser:New()
    local o = {
        class           = "smithing"
    ,   request_item    = nil   -- Smithing.REQUEST_ITEMS[n]
    ,   set_bonus       = nil   -- Smithing.SET_BONUS[n]
    ,   trait_num       = nil   -- ITEM_TRAIT_TYPE_WEAPON_DEFENDING
    ,   motif_num       = nil   -- 19 ITEMSTYLE_ENEMY_PRIMITIVE
    ,   motif           = nil   -- Smithing.MOTIF[n]
    ,   improve_level   = nil   -- PURPLE, GOLD
    ,   mat_list        = {}    -- of MatRow
    ,   can_dolgubon    = true
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Parser:ParseItemLink(item_link)
    local fields        = Util.ToWritFields(item_link)
    local item_num      = fields.writ1
    local material_num  = fields.writ2
    local quality_num   = fields.writ3
    local set_num       = fields.writ4
    local trait_num     = fields.writ5
    local motif_num     = fields.writ6

    self.request_item   = Smithing.REQUEST_ITEMS[item_num]
    Log:Add("request_item:"..tostring(item_num).." "
            ..tostring(self.request_item.item_name))
    self.set_bonus      = Smithing.SET_BONUS[set_num]
    if not self.set_bonus then return Fail("set not found "..tostring(set_num)) end
    Log:Add("set_bonus:"..tostring(set_num))
    Log:Add(self.set_bonus)
    self.trait          = self.request_item.trait_set[trait_num]
    self.trait_num      = trait_num
    Log:Add("trait:"..tostring(trait_num))
    Log:Add(self.trait)
    self.motif_num      = motif_num
    self.motif          = Smithing.MOTIF[motif_num]
    Log:Add("motif:"..tostring(motif_num))
    Log:Add(self.motif)
    if not self.motif then return Fail("motif not found "..tostring(motif_num)) end
    self.improve_level  = Smithing.QUALITY[quality_num]
    Log:Add("improve:"..tostring(quality_num))
    Log:Add(self.improve_level)
    if not self.improve_level then
        return Fail("quality not found "..tostring(quality_num)) end
    return self
end

-- Convert result of ParseBaseText() into  a flat list of items.
function Parser:ToMatList()
    local MatRow = WritWorthy.MatRow
    local ml = {}
    table.insert(ml, MatRow:FromName( self.request_item.school.base_mat_name
                                    , self.request_item.base_mat_ct ))
    table.insert(ml, MatRow:FromName( self.trait.mat_name ))
    table.insert(ml, MatRow:FromName( self.motif.mat_name ))

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

-- Do we know the required motif and traits?
function Parser:ToKnowList()
    local Know = WritWorthy.Know
    local r = {}

                        -- Do you know this motif?
                        --
                        -- First see if we just know the whole book.
                        --
                        -- This works for earlier motifs that don't have
                        -- separate pages, and for Crown Store exclusives, and
                        -- for any paged books like Glass or Xivkyn or Ebony,
                        -- if you know all 14 pages.
                        --
                        -- MYSTERY_OFFSET: because IsSmithingStyleKnown()
                        -- surprises us by subtracting 1 from its argument.
    local MYSTERY_OFFSET = 1
    local motif_known = IsSmithingStyleKnown(self.motif_num + MYSTERY_OFFSET)
    Log:Add("motif book IsSmithingStyleKnown("
            ..tostring(self.motif_num).."+1) = "..tostring(motif_known))

                        -- If the above check failed, and the motif has
                        -- individual pages, check those. For some reason,
                        -- the 2nd arg to IsSmithingStyleKnown() has no effect.
                        -- So copy CraftStore and use achievement progress.
    if (not motif_known) and self.motif.pages_id then
        local _, completed_ct = GetAchievementCriterion(
                                  self.motif.pages_id
                                , self.request_item.motif_page)
        motif_known = 0 < completed_ct
        Log:Add("motif page GetAchievementCriterion("
                .."pages_id="..tostring(self.motif.pages_id)
                ..", req.page="..tostring(self.request_item.motif_page)
                ..") = "..tostring(completed_ct))
                        -- Debug dump all 14 pages of this motif
        local pg_known = {}
        for pg = 1,14 do
            local _, completed_ct = GetAchievementCriterion(
                                  self.motif.pages_id
                                , pg )
            pg_known[pg] = completed_ct
        end
        Log:Add("pages known:"..table.concat(pg_known, " "))
    end
    local title = string.format("motif %s", self.motif.motif_name)
    local msg   = string.format("Motif %s not known", self.motif.motif_name)
    table.insert(r, Know:New({ name     = title
                             , is_known = motif_known
                             , lack_msg = msg
                             }))

                        -- Do you know this trait?
    local line_name = GetSmithingResearchLineInfo(
                              self.request_item.school.trade_skill_type
                            , self.request_item.research_line )
    line_name = line_name:lower()
    Log:Add("GetSmithingResearchLineInfo("
            .."skill="..tostring(self.request_item.school.trade_skill_type)
            ..", line="..tostring(self.request_item.research_line)
            ..") = " ..tostring(line_name))
    local _,_,trait_known = GetSmithingResearchLineTraitInfo(
                              self.request_item.school.trade_skill_type
                            , self.request_item.research_line
                            , self.trait.trait_index )
    Log:Add("GetSmithingResearchLineTraitInfo("
            .."skill="..tostring(self.request_item.school.trade_skill_type)
            ..", line="..tostring(self.request_item.research_line)
            ..", trait="..tostring(self.trait.trait_index)
            ..") = " ..tostring(trait_known))
    local title = string.format("trait %s %s", self.trait.trait_name, line_name)
    local msg   = string.format("Trait %s %s not known", self.trait.trait_name, line_name)
    table.insert(r, Know:New({ name     = title
                             , is_known = trait_known
                             , lack_msg = msg
                             }))

                        -- Do you know enough traits to craft this set bonus?
    if self.set_bonus and self.set_bonus.trait_ct then
        local known_trait_ct = 0
        local known_t = {}
        for trait_num, trait in pairs(self.request_item.trait_set) do
            local _,_,known = GetSmithingResearchLineTraitInfo(
                                      self.request_item.school.trade_skill_type
                                    , self.request_item.research_line
                                    , trait.trait_index )
            local value = 0
            if known then
                value = 1
            end
            known_trait_ct = known_trait_ct + value
            known_t[trait.trait_index] = value
        end
        Log:Add("known traits for "
                .."GSRLTI(skill="..tostring(self.request_item.school.trade_skill_type)
                ..", line="..tostring(self.request_item.research_line)
                ..", trait_index=?):"..table.concat(known_t," "))
        local title = string.format( "%d traits for set bonus", self.set_bonus.trait_ct)
        local msg   = string.format( "%d of %d traits required for set %s"
                               , known_trait_ct
                               , self.set_bonus.trait_ct
                               , tostring(self.set_bonus.name)
                               )
        table.insert(r, Know:New({ name     = title
                                 , is_known = self.set_bonus.trait_ct <= known_trait_ct
                                 , lack_msg = msg }))
    end

    return r
end


-- Dolgubon's Lazy Set Crafter integration -----------------------------------
--[[
UI requirements
Style names from    DolgubonSetCrafter.styleNames
Trait names from    DolgubonSetCrafter.armourTraits and .weaponTraits
Quality names from  DolgubonSetCrafter.quality
Set names from      DolgubonSetCrafter.setIndexes

styleIndex from DSC.ComboBox.Style.(selected)[1]
UI requires:

LLC requires

styleIndex = 8      Style   = "High Elf"
                    Weight  = "Heavy"
                    Pattern = "Chest"
                    Quality = "(p)Epic"
                    Trait   = "Divines"
                    Set     = "Alessia's Bulwark"


styleIndex = 1 + ITEMSTYLE_XXX
 7  Argonian             --  6 = ITEMSTYLE_RACIAL_ARGONIAN
16  Ancient Elf          -- 15 = ITEMSTYLE_AREA_ANCIENT_ELF
23  Ancient Orc          -- 22 = ITEMSTYLE_AREA_ANCIENT_ORC
26  Aldmeri Dominion     -- 25 = ITEMSTYLE_ALLIANCE_ALDMERI
34  Akaviri              -- 33 = ITEMSTYLE_AREA_AKAVIRI
42  abahs watch          -- 42 = ITEMSTYLE_ORG_ABAHS_WATCH

trait = 1 + ITEM_TRAIT_TYPE_XXX
2   Powered
3   Charged
4   Precise
5   Infused (weapon)
6   Defending
7   Training (weapon)
8   Sharpened
9   Decisive
12  Sturdy
13  Impenetrable
14  Reinforced
15  Well-Fitted
16  Training (armor)
17  Infused (armor)
18  Prosperous
19  Divines
26  Nirnhoned (armor)
27  Nirnhoned (weapon)

station  == CRAFTING_TYPE_XXX
1   blacksmithing (both armor and weapons)
2   clothier
6   woodworking (weapon and shield)

quality
1 = normal white
2 = fine green
3 = superior blue
4 = epic purple
5 = legendary yellow

CraftRequestTable[]
[ 1 pattern    ] patternIndex above, 1..15
[ 2 isCP       ] true
[ 3 level      ] 150
[ 4 styleIndex ] ITEMSTYLE_XXX + 1,
[ 5 trait      ] trait above
[ 6 false      ] false
[ 7 station    ] station above 1, 2, or 6
[ 8 setIndex   ] 13
[ 9 quality    ] quality above 1..5
[10 true       ] true

--]]


-- Create a Dolgubon's Lazy Set Crafter request.
function Parser:ToDolRequest()

                        -- a unique identifier within Dolgubon's
                        -- enqueued requests. No, this is not really
                        -- unique and neither Dolgubon nor Zig cares.
                        -- Close enough.
    local reference = math.random()

                        -- API struct passed to LibLazyCrafter for
                        -- eventual crafting.
    local o = {}
    o.patternIndex = self.request_item.dol_pattern_index
    o.isCP         = true
    o.level        = 150
    o.styleIndex   = self.motif_num + 1
    o.traitIndex   = self.trait_num + 1
    o.useUniversalStyleItem = false
    o.station      = self.request_item.school.trade_skill_type
    o.setIndex     = self.set_bonus.dol_set_index
    o.quality      = self.improve_level.index
    o.autocraft    = true
    o.reference    = reference
    local craft_request_table = {
      o.patternIndex            --  1
    , o.isCP                    --  2
    , o.level                   --  3
    , o.styleIndex              --  4
    , o.traitIndex              --  5
    , o.useUniversalStyleItem   --  6
    , o.station                 --  7
    , o.setIndex                --  8
    , o.quality                 --  9
    , o.autocraft               -- 10
    , o.reference               -- 11
    }

                        -- UI row with user-visible strings.
                        -- This is just for display, so okay if strings
                        -- mismatch something Dolgubon would supply. (For
                        -- example, Dolgubon has a private shortening function
                        -- to say "Seducer" instead of "Armor of the Seducer",
                        -- but we don't get to call this.)
    local request_table = {}
    request_table.Pattern           = self.request_item.item_name
    request_table.Weight            = self.request_item.school.armor_weight_name
    request_table.Trait             = self.request_item.trait_set[self.trait_num].trait_name
    --quest_table.isCP              = true
    request_table.Level             = "CP150"
    request_table.Style             = self.motif.motif_name
    request_table.styleIndex        = self.motif_num + 1
    request_table.Set               = self.set_bonus.name
    request_table.Quality           = self.improve_level.name
    request_table.Reference         = reference
    request_table.CraftRequestTable = craft_request_table

    return request_table
end
