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
-- "research lines" values are indices to pass as arg#2 to
-- GetSmithingResearchLineTraitInfo() to see which
-- traits we know about that item, or if we know enough traits to craft
-- the requested set bonus for that item.
--   Indices learned by iterating over calls to
-- GetSmithingResearchLineInfo(school, i)
--
Smithing.SCHOOL_HEAVY =  {
    trade_skill_type    = CRAFTING_TYPE_BLACKSMITHING
,   base_mat_name       = "rubedite"
,   green_mat_name      = "honing stone"
,   blue_mat_name       = "dwarven oil"
,   purple_mat_name     = "grain solvent"
,   gold_mat_name       = "tempering alloy"
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
-- Index numbers here are item_link writ5 numbers
-- and appear to match ITEM_TYPE_XXXX_XXXX constants
--
Smithing.TRAITS_WEAPON = {
    [ITEM_TRAIT_TYPE_WEAPON_POWERED    ] = { mat_name = "chysolite"          , trait_index = 1 }
,   [ITEM_TRAIT_TYPE_WEAPON_CHARGED    ] = { mat_name = "amethyst"           , trait_index = 2 }
,   [ITEM_TRAIT_TYPE_WEAPON_PRECISE    ] = { mat_name = "ruby"               , trait_index = 3 }
,   [ITEM_TRAIT_TYPE_WEAPON_INFUSED    ] = { mat_name = "jade"               , trait_index = 4 }
,   [ITEM_TRAIT_TYPE_WEAPON_DEFENDING  ] = { mat_name = "turquoise"          , trait_index = 5 }
,   [ITEM_TRAIT_TYPE_WEAPON_TRAINING   ] = { mat_name = "carnelian"          , trait_index = 6 }
,   [ITEM_TRAIT_TYPE_WEAPON_SHARPENED  ] = { mat_name = "fire opal"          , trait_index = 7 }
,   [ITEM_TRAIT_TYPE_WEAPON_DECISIVE   ] = { mat_name = "citrine"            , trait_index = 8 }  -- nee weighted
,   [ITEM_TRAIT_TYPE_WEAPON_NIRNHONED  ] = { mat_name = "potent nirncrux"    , trait_index = 9 }
}
Smithing.TRAITS_ARMOR    = {
    [ITEM_TRAIT_TYPE_ARMOR_STURDY      ] = { mat_name = "quartz"             , trait_index = 1 }
,   [ITEM_TRAIT_TYPE_ARMOR_IMPENETRABLE] = { mat_name = "diamond"            , trait_index = 2 }
,   [ITEM_TRAIT_TYPE_ARMOR_REINFORCED  ] = { mat_name = "sardonyx"           , trait_index = 3 }
,   [ITEM_TRAIT_TYPE_ARMOR_WELL_FITTED ] = { mat_name = "almandine"          , trait_index = 4 }
,   [ITEM_TRAIT_TYPE_ARMOR_TRAINING    ] = { mat_name = "emerald"            , trait_index = 5 }
,   [ITEM_TRAIT_TYPE_ARMOR_INFUSED     ] = { mat_name = "bloodstone"         , trait_index = 6 }
,   [ITEM_TRAIT_TYPE_ARMOR_PROSPEROUS  ] = { mat_name = "garnet"             , trait_index = 7 } -- nee exploration
,   [ITEM_TRAIT_TYPE_ARMOR_DIVINES     ] = { mat_name = "sapphire"           , trait_index = 8 }
,   [ITEM_TRAIT_TYPE_ARMOR_NIRNHONED   ] = { mat_name = "fortified nirncrux" , trait_index = 9 }
}

-- Motifs --------------------------------------------------------------------
--
Smithing.MOTIF = {
    [ITEMSTYLE_RACIAL_BRETON        ]  = "molybdenum"           -- 01 Breton
,   [ITEMSTYLE_RACIAL_REDGUARD      ]  = "starmetal"            -- 02 Redguard
,   [ITEMSTYLE_RACIAL_ORC           ]  = "manganese"            -- 03 Orc
,   [ITEMSTYLE_RACIAL_DARK_ELF      ]  = "obsidian"             -- 04 Dunmer
,   [ITEMSTYLE_RACIAL_NORD          ]  = "corundum"             -- 05 Nord
,   [ITEMSTYLE_RACIAL_ARGONIAN      ]  = "flint"                -- 06 Argonian
,   [ITEMSTYLE_RACIAL_HIGH_ELF      ]  = "adamantite"           -- 07 Altmer
,   [ITEMSTYLE_RACIAL_WOOD_ELF      ]  = "bone"                 -- 08 Bosmer
,   [ITEMSTYLE_RACIAL_KHAJIIT       ]  = "moonstone"            -- 09 Khajiit
,   [ITEMSTYLE_UNIQUE               ]  = nil                    -- 10 Unique
,   [ITEMSTYLE_ORG_THIEVES_GUILD    ]  = "fine chalk"           -- 11 Thieves Guild
,   [ITEMSTYLE_ORG_DARK_BROTHERHOOD ]  = "black beeswax"        -- 12 Dark Brotherhood
,   [ITEMSTYLE_DEITY_MALACATH       ]  = "potash"               -- 13 Malacath
,   [ITEMSTYLE_AREA_DWEMER          ]  = "dwemer frame"         -- 14 Dwemer
,   [ITEMSTYLE_AREA_ANCIENT_ELF     ]  = "palladium"            -- 15 Ancient Elf
,   [ITEMSTYLE_DEITY_AKATOSH        ]  = "pearl sand"           -- 16 Order of the Hour
,   [ITEMSTYLE_AREA_REACH           ]  = "copper"               -- 17 Barbaric
,   [ITEMSTYLE_ENEMY_BANDIT         ]  = nil                    -- 18 Bandit
,   [ITEMSTYLE_ENEMY_PRIMITIVE      ]  = "argentum"             -- 19 Primal
,   [ITEMSTYLE_ENEMY_DAEDRIC        ]  = "daedra heart"         -- 20 Daedric
,   [ITEMSTYLE_DEITY_TRINIMAC       ]  = "auric tusk"           -- 21 Trinimac
,   [ITEMSTYLE_AREA_ANCIENT_ORC     ]  = "cassiterite"          -- 22 Ancient Orc
,   [ITEMSTYLE_ALLIANCE_DAGGERFALL  ]  = "lion fang"            -- 23 Daggerfall Covenant
,   [ITEMSTYLE_ALLIANCE_EBONHEART   ]  = "dragon scute"         -- 24 Ebonheart Pact
,   [ITEMSTYLE_ALLIANCE_ALDMERI     ]  = "eagle feather"        -- 25 Aldmeri Dominion
,   [ITEMSTYLE_UNDAUNTED            ]  = "laurel"               -- 26 Mercenary
,   [ITEMSTYLE_RAIDS_CRAGLORN       ]  = "star sapphire"        -- 27 Celestial
,   [ITEMSTYLE_GLASS                ]  = "malachite"            -- 28 Glass
,   [ITEMSTYLE_AREA_XIVKYN          ]  = "charcoal of remorse"  -- 29 Xivkyn
,   [ITEMSTYLE_AREA_SOUL_SHRIVEN    ]  = "azure plasm"          -- 30 Soul-Shriven
,   [ITEMSTYLE_ENEMY_DRAUGR         ]  = "pristine shroud"      -- 31 Draugr
,   [ITEMSTYLE_ENEMY_MAORMER        ]  = nil                    -- 32 Maormer
,   [ITEMSTYLE_AREA_AKAVIRI         ]  = "goldscale"            -- 33 Akaviri
,   [ITEMSTYLE_RACIAL_IMPERIAL      ]  = "nickel"               -- 34 Imperial
,   [ITEMSTYLE_AREA_YOKUDAN         ]  = "ferrous salts"        -- 35 Yokudan
,   [ITEMSTYLE_UNIVERSAL            ]  = nil                    -- 36 unused
,   [ITEMSTYLE_AREA_REACH_WINTER    ]  = nil                    -- 37 Reach Winter
,   [ITEMSTYLE_ORG_WORM_CULT        ]  = nil                    -- 38 Worm Cult
,   [ITEMSTYLE_ENEMY_MINOTAUR       ]  = "oxblood fungus"       -- 39 Minotaur
,   [ITEMSTYLE_EBONY                ]  = "night pumice"         -- 40 Ebony
,   [ITEMSTYLE_ORG_ABAHS_WATCH      ]  = "polished shilling"    -- 41 Abah's Watch
,   [ITEMSTYLE_ENEMY_SKINCHANGER    ]  = "wolfsbane incense"    -- 42 Skinchanger
,   [ITEMSTYLE_ORG_MORAG_TONG       ]  = nil                    -- 43 Morag Tong
,   [ITEMSTYLE_AREA_RA_GADA         ]  = "ancient sandstone"    -- 44 Ra Gada
,   [ITEMSTYLE_ENEMY_DROMOTHRA      ]  = "defiled whiskers"     -- 45 Dro-m'Athra
,   [ITEMSTYLE_ORG_ASSASSINS        ]  = "tainted blood"        -- 46 Assassins League
,   [ITEMSTYLE_ORG_OUTLAW           ]  = "rogue's soot"         -- 47 Outlaw
,   [ITEMSTYLE_UNUSED11             ]  = nil                    -- 48 Unused 11
,   [ITEMSTYLE_UNUSED12             ]  = nil                    -- 49 Unused 12
,   [ITEMSTYLE_UNUSED13             ]  = nil                    -- 40 Unused 13
,   [ITEMSTYLE_UNUSED14             ]  = nil                    -- 51 Unused 14
,   [ITEMSTYLE_UNUSED15             ]  = nil                    -- 52 Unused 15
,   [ITEMSTYLE_UNUSED16             ]  = "stahlrim shard"       -- 53 Stalhrim Frostcaster
,   [ITEMSTYLE_UNUSED17             ]  = nil                    -- 54 Unused 17
,   [ITEMSTYLE_UNUSED18             ]  = nil                    -- 55 Unused 18
,   [ITEMSTYLE_UNUSED19             ]  = "distilled slowsilver" -- 56 Silken Ring
,   [ITEMSTYLE_UNUSED20             ]  = "leviathan scrimshaw"  -- 57 Mazzatun
,   [ITEMSTYLE_UNUSED21             ]  = "grinstones"           -- 58 Grim Harlequin
,   [ITEMSTYLE_UNUSED22             ]  = "amber marble"         -- 59 Hollowjack
,   [60                             ]  = nil                    -- 60
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
-- Material requirements for each possitble Master Write BS/CL/WW item.
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
  [53] = { item_id = 53, item_name = "Rubedite Axe",                school = HVY, base_mat_ct = 11, trait_set = WEAPON, research_line = HVY.H1_AXE,         motif_page = PG.AXES    }
, [56] = { item_id = 56, item_name = "Rubedite Mace",               school = HVY, base_mat_ct = 11, trait_set = WEAPON, research_line = HVY.H1_MACE,        motif_page = PG.MACES   }
, [59] = { item_id = 59, item_name = "Rubedite Sword",              school = HVY, base_mat_ct = 11, trait_set = WEAPON, research_line = HVY.H1_SWORD,       motif_page = PG.SWORDS  }
, [68] = { item_id = 68, item_name = "Rubedite Greataxe",           school = HVY, base_mat_ct = 14, trait_set = WEAPON, research_line = HVY.H2_BATTLE_AXE,  motif_page = PG.AXES    }
, [67] = { item_id = 67, item_name = "Rubedite Greatsword",         school = HVY, base_mat_ct = 14, trait_set = WEAPON, research_line = HVY.H2_GREATSSWORD, motif_page = PG.SWORDS  }
, [69] = { item_id = 69, item_name = "Rubedite Maul",               school = HVY, base_mat_ct = 14, trait_set = WEAPON, research_line = HVY.H2_MAUL,        motif_page = PG.MACES   }
, [62] = { item_id = 62, item_name = "Rubedite Dagger",             school = HVY, base_mat_ct = 10, trait_set = WEAPON, research_line = HVY.DAGGER,         motif_page = PG.DAGGERS }

, [46] = { item_id = 46, item_name = "Rubedite Cuirass",            school = HVY, base_mat_ct = 15, trait_set = ARMOR , research_line = HVY.CHEST,          motif_page = PG.CHESTS  }
, [50] = { item_id = 50, item_name = "Rubedite Sabatons",           school = HVY, base_mat_ct = 13, trait_set = ARMOR , research_line = HVY.FEET,           motif_page = PG.BOOTS   }
, [52] = { item_id = 52, item_name = "Rubedite Gauntlets",          school = HVY, base_mat_ct = 13, trait_set = ARMOR , research_line = HVY.HANDS,          motif_page = PG.GLOVES  }
, [44] = { item_id = 44, item_name = "Rubedite Helm",               school = HVY, base_mat_ct = 13, trait_set = ARMOR , research_line = HVY.HEAD,           motif_page = PG.HELMETS }
, [49] = { item_id = 49, item_name = "Rubedite Greaves",            school = HVY, base_mat_ct = 14, trait_set = ARMOR , research_line = HVY.LEGS,           motif_page = PG.LEGS    }
, [47] = { item_id = 47, item_name = "Rubedite Pauldron",           school = HVY, base_mat_ct = 13, trait_set = ARMOR , research_line = HVY.SHOULDERS,      motif_page = PG.SHOULDERS }
, [48] = { item_id = 48, item_name = "Rubedite Girdle",             school = HVY, base_mat_ct = 13, trait_set = ARMOR , research_line = HVY.WAIST,          motif_page = PG.BELTS   }

, [28] = { item_id = 28, item_name = "Ancestor Silk Robe",          school = LGT, base_mat_ct = 15, trait_set = ARMOR , research_line = LGT.CHEST,          motif_page = PG.CHESTS  }
, [ 0] = { item_id =  0, item_name = "Ancestor Silk Jerkin",        school = LGT, base_mat_ct = 15, trait_set = ARMOR , research_line = LGT.CHEST,          motif_page = PG.CHESTS  }
, [32] = { item_id = 32, item_name = "Ancestor Silk Shoes",         school = LGT, base_mat_ct = 13, trait_set = ARMOR , research_line = LGT.FEET,           motif_page = PG.BOOTS   }
, [34] = { item_id = 34, item_name = "Ancestor Silk Gloves",        school = LGT, base_mat_ct = 13, trait_set = ARMOR , research_line = LGT.HANDS,          motif_page = PG.GLOVES  }
, [26] = { item_id = 26, item_name = "Ancestor Silk Hat",           school = LGT, base_mat_ct = 13, trait_set = ARMOR , research_line = LGT.HEAD,           motif_page = PG.HELMETS }
, [31] = { item_id = 31, item_name = "Ancestor Silk Breeches",      school = LGT, base_mat_ct = 14, trait_set = ARMOR , research_line = LGT.LEGS,           motif_page = PG.LEGS    }
, [29] = { item_id = 29, item_name = "Ancestor Silk Epaulets",      school = LGT, base_mat_ct = 13, trait_set = ARMOR , research_line = LGT.SHOULDERS,      motif_page = PG.SHOULDERS }
, [30] = { item_id = 30, item_name = "Ancestor Silk Sash",          school = LGT, base_mat_ct = 13, trait_set = ARMOR , research_line = LGT.WAIST,          motif_page = PG.BELTS   }

, [37] = { item_id = 37, item_name = "Rubedo Leather Jack",         school = MED, base_mat_ct = 15, trait_set = ARMOR , research_line = LGT.CHEST,          motif_page = PG.CHESTS  }
, [41] = { item_id = 41, item_name = "Rubedo Leather Boots",        school = MED, base_mat_ct = 13, trait_set = ARMOR , research_line = LGT.FEET,           motif_page = PG.BOOTS   }
, [43] = { item_id = 43, item_name = "Rubedo Leather Bracers",      school = MED, base_mat_ct = 13, trait_set = ARMOR , research_line = LGT.HANDS,          motif_page = PG.GLOVES  }
, [35] = { item_id = 35, item_name = "Rubedo Leather Helmet",       school = MED, base_mat_ct = 13, trait_set = ARMOR , research_line = LGT.HEAD,           motif_page = PG.HELMETS }
, [40] = { item_id = 40, item_name = "Rubedo Leather Guards",       school = MED, base_mat_ct = 14, trait_set = ARMOR , research_line = LGT.LEGS,           motif_page = PG.LEGS    }
, [38] = { item_id = 38, item_name = "Rubedo Leather Arm Cops",     school = MED, base_mat_ct = 13, trait_set = ARMOR , research_line = LGT.SHOULDERS,      motif_page = PG.SHOULDERS }
, [39] = { item_id = 39, item_name = "Rubedo Leather Belt",         school = MED, base_mat_ct = 13, trait_set = ARMOR , research_line = LGT.WAIST,          motif_page = PG.BELTS   }

, [70] = { item_id = 70, item_name = "Ruby Ash Bow",                school = WW,  base_mat_ct = 12, trait_set = WEAPON, research_line = WW.BOW,             motif_page = PG.BOWS    }
, [72] = { item_id = 72, item_name = "Ruby Ash Inferno Staff",      school = WW,  base_mat_ct = 12, trait_set = WEAPON, research_line = WW.FLAME_STAFF,     motif_page = PG.STAVES  }
, [73] = { item_id = 73, item_name = "Ruby Ash Frost Staff",        school = WW,  base_mat_ct = 12, trait_set = WEAPON, research_line = WW.ICE_STAFF,       motif_page = PG.STAVES  }
, [74] = { item_id = 74, item_name = "Ruby Ash Lightning Staff",    school = WW,  base_mat_ct = 12, trait_set = WEAPON, research_line = WW.LIGHTNING_STAFF, motif_page = PG.STAVES  }
, [71] = { item_id = 71, item_name = "Ruby Ash Healing Staff",      school = WW,  base_mat_ct = 12, trait_set = WEAPON, research_line = WW.RESTO_STAFF,     motif_page = PG.STAVES  }

, [65] = { item_id = 65, item_name = "Ruby Ash Shield",             school = WW,  base_mat_ct = 14, trait_set = ARMOR , research_line = WW.SHIELD,          motif_page = PG.SHIELDS }
}

-- Set Bonus required trait counts -------------------------------------------
--
-- How many traits must you know in order to craft an item with this
-- set bonus?
--
-- Table index is writ4 value for smithing writs.
--
-- ??? Could not find "Spectre's Eye"
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
 ,  [ 19] = { name = "Vestments of the Warlock",                     }
 ,  [ 20] = { name = "Witchman Armor",                               }
 ,  [ 21] = { name = "Akaviri Dragonguard",                          }
 ,  [ 22] = { name = "Dreamer's Mantle",                             }
 ,  [ 23] = { name = "Archer's Mind",                                }
 ,  [ 24] = { name = "Footman's Fortune",                            }
 ,  [ 25] = { name = "Desert Rose",                                  }
 ,  [ 26] = { name = "Prisoner's Rags",                              }
 ,  [ 27] = { name = "Fiord's Legacy",                               }
 ,  [ 28] = { name = "Barkskin",                                     }
 ,  [ 29] = { name = "Sergeant's Mail",                              }
 ,  [ 30] = { name = "Thunderbug's Carapace",                        }
 ,  [ 31] = { name = "Silks of the Sun",                             }
 ,  [ 32] = { name = "Healer's Habit",                               }
 ,  [ 33] = { name = "Viper's Sting",                                }
 ,  [ 34] = { name = "Night Mother's Embrace",                       }
 ,  [ 35] = { name = "Knightmare",                                   }
 ,  [ 36] = { name = "Armor of the Veiled Heritance",                }
 ,  [ 37] = { name = "Death's Wind",                    trait_ct = 2 }
 ,  [ 38] = { name = "Twilight's Embrace",              trait_ct = 3 }
 ,  [ 39] = { name = "Alessian Order",                               }
 ,  [ 40] = { name = "Night's Silence",                 trait_ct = 2 }
 ,  [ 41] = { name = "Whitestrake's Retribution",       trait_ct = 4 }
 ,  [ 42] = nil
 ,  [ 43] = { name = "Armor of the Seducer",            trait_ct = 3 }
 ,  [ 44] = { name = "Vampire's Kiss",                  trait_ct = 5 }
 ,  [ 45] = nil
 ,  [ 46] = { name = "Noble Duelist's Silks",                        }
 ,  [ 47] = { name = "Robes of the Withered Hand",                   }
 ,  [ 48] = { name = "Magnus' Gift",                    trait_ct = 4 }
 ,  [ 49] = { name = "Shadow of the Red Mountain",                   }
 ,  [ 50] = { name = "The Morag Tong",                               }
 ,  [ 51] = { name = "Night Mother's Gaze",             trait_ct = 6 }
 ,  [ 52] = { name = "Beckoning Steel",                              }
 ,  [ 53] = { name = "The Ice Furnace",                              }
 ,  [ 54] = { name = "Ashen Grip",                      trait_ct = 2 }
 ,  [ 55] = { name = "Prayer Shawl",                                 }
 ,  [ 56] = { name = "Stendarr's Embrace",                           }
 ,  [ 57] = { name = "Syrabane's Grip",                              }
 ,  [ 58] = { name = "Hide of the Werewolf",                         }
 ,  [ 59] = { name = "Kyne's Kiss",                                  }
 ,  [ 60] = { name = "Darkstride",                                   }
 ,  [ 61] = { name = "Dreugh King Slayer",                           }
 ,  [ 62] = { name = "Hatchling's Shell",                            }
 ,  [ 63] = { name = "The Juggernaut",                               }
 ,  [ 64] = { name = "Shadow Dancer's Raiment",                      }
 ,  [ 65] = { name = "Bloodthorn's Touch",                           }
 ,  [ 66] = { name = "Robes of the Hist",                            }
 ,  [ 67] = { name = "Shadow Walker",                                }
 ,  [ 68] = { name = "Stygian",                                      }
 ,  [ 69] = { name = "Ranger's Gait",                                }
 ,  [ 70] = { name = "Seventh Legion Brute",                         }
 ,  [ 71] = { name = "Durok's Bane",                                 }
 ,  [ 72] = { name = "Nikulas' Heavy Armor",                         }
 ,  [ 73] = { name = "Oblivion's Foe",                  trait_ct = 8 }
 ,  [ 75] = { name = "Torug's Pact",                    trait_ct = 3 }
 ,  [ 76] = { name = "Robes of Alteration Mastery",                  }
 ,  [ 77] = { name = "Crusader",                                     }
 ,  [ 78] = { name = "Hist Bark",                       trait_ct = 4 }
 ,  [ 79] = { name = "Willow's Path",                   trait_ct = 6 }
 ,  [ 80] = { name = "Hunding's Rage",                  trait_ct = 6 }
 ,  [ 81] = { name = "Song of Lamae",                   trait_ct = 5 }
 ,  [ 82] = { name = "Alessia's Bulwark",               trait_ct = 5 }
 ,  [ 83] = { name = "Elf Bane",                                     }
 ,  [ 84] = { name = "Orgnum's Scales",                 trait_ct = 8 }
 ,  [ 85] = { name = "Almalexia's Mercy",                            }
 ,  [ 86] = { name = "Queen's Elegance",                             }
 ,  [ 87] = { name = "Eyes of Mara",                    trait_ct = 8 }
 ,  [ 88] = { name = "Robes of Destruction Mastery",                 }
 ,  [ 89] = { name = "Sentry",                                       }
 ,  [ 90] = { name = "Senche's Bite",                                }
 ,  [ 91] = { name = "Oblivion's Edge",                              }
 ,  [ 92] = { name = "Kagrenac's Hope",                 trait_ct = 8 }
 ,  [ 93] = { name = "Storm Knight's Plate",                         }
 ,  [ 94] = { name = "Meridia's Blessed Armor",                      }
 ,  [ 95] = { name = "Shalidor's Curse",                trait_ct = 8 }
 ,  [ 96] = { name = "Armor of Truth",                               }
 ,  [ 97] = { name = "The Arch-Mage",                                }
 ,  [ 98] = { name = "Necropotence",                                 }
 ,  [ 99] = { name = "Salvation",                                    }
,   [100] = { name = "Hawk's Eye",                                   }
,   [101] = { name = "Affliction",                                   }
,   [102] = { name = "Duneripper's Scales",                          }
,   [103] = { name = "Magicka Furnace",                              }
,   [104] = { name = "Curse Eater",                                  }
,   [105] = { name = "Twin Sisters",                                 }
,   [106] = { name = "Wilderqueen's Arch",                           }
,   [107] = { name = "Wyrd Tree's Blessing",                         }
,   [108] = { name = "Ravager",                                      }
,   [109] = { name = "Light of Cyrodiil",                            }
,   [110] = { name = "Sanctuary",                                    }
,   [111] = { name = "Ward of Cyrodiil",                             }
,   [112] = { name = "Night Terror",                                 }
,   [113] = { name = "Crest of Cyrodiil",                            }
,   [114] = { name = "Soulshine",                                    }
,   [115] = nil
,   [116] = { name = "The Destruction Suite",                        }
,   [117] = { name = "Relics of the Physician, Ansur",               }
,   [118] = { name = "Treasures of the Earthforge",                  }
,   [119] = { name = "Relics of the Rebellion",                      }
,   [120] = { name = "Arms of Infernace",                            }
,   [121] = { name = "Arms of the Ancestors",                        }
,   [122] = { name = "Ebon Armory",                                  }
,   [123] = { name = "Hircine's Veneer",                             }
,   [124] = { name = "The Worm's Raiment",                           }
,   [125] = { name = "Wrath of the Imperium",                        }
,   [126] = { name = "Grace of the Ancients",                        }
,   [127] = { name = "Deadly Strike",                                }
,   [128] = { name = "Blessing of the Potentates",                   }
,   [129] = { name = "Vengeance Leech",                              }
,   [130] = { name = "Eagle Eye",                                    }
,   [131] = { name = "Bastion of the Heartland",                     }
,   [132] = { name = "Shield of the Valiant",                        }
,   [133] = { name = "Buffer of the Swift",                          }
,   [134] = { name = "Shroud of the Lich",                           }
,   [135] = { name = "Draugr's Heritage",                            }
,   [136] = { name = "Immortal Warrior",                             }
,   [137] = { name = "Berserking Warrior",                           }
,   [138] = { name = "Defending Warrior",                            }
,   [139] = { name = "Wise Mage",                                    }
,   [140] = { name = "Destructive Mage",                             }
,   [141] = { name = "Healing Mage",                                 }
,   [142] = { name = "Quick Serpent",                                }
,   [143] = { name = "Poisonous Serpent",                            }
,   [144] = { name = "Twice-Fanged Serpent",                         }
,   [145] = { name = "Way of Fire",                                  }
,   [146] = { name = "Way of Air",                                   }
,   [147] = { name = "Way of Martial Knowledge",                     }
,   [148] = { name = "Way of the Arena",                trait_ct = 8 }
,   [149] = nil
,   [150] = nil
,   [151] = nil
,   [152] = nil
,   [153] = nil
,   [154] = nil
,   [155] = { name = "Undaunted Bastion",                            }
,   [156] = { name = "Undaunted Infiltrator",                        }
,   [157] = { name = "Undaunted Unweaver",                           }
,   [158] = { name = "Embershield",                                  }
,   [159] = { name = "Sunderflame",                                  }
,   [160] = { name = "Burning Spellweave",                           }
,   [161] = { name = "Twice-Born Star",                 trait_ct = 9 }
,   [162] = { name = "Spawn of Mephala",                             }
,   [163] = { name = "Blood Spawn",                                  }
,   [164] = { name = "Lord Warden",                                  }
,   [165] = { name = "Scourge Harvester",                            }
,   [166] = { name = "Engine Guardian",                              }
,   [167] = { name = "Nightflame",                                   }
,   [168] = { name = "Nerien'eth",                                   }
,   [169] = { name = "Valkyn Skoria",                                }
,   [170] = { name = "Maw of the Infernal",                          }
,   [171] = { name = "Eternal Warrior",                              }
,   [172] = { name = "Infallible Mage",                              }
,   [173] = { name = "Vicious Serpent",                              }
,   [174] = nil
,   [175] = nil
,   [176] = { name = "Noble's Conquest",                trait_ct = 5 }
,   [177] = { name = "Redistributor",                   trait_ct = 7 }
,   [178] = { name = "Armor Master",                    trait_ct = 9 }
,   [179] = { name = "Black Rose",                                   }
,   [180] = { name = "Powerful Assault",                             }
,   [181] = { name = "Meritorious Service",                          }
,   [182] = nil
,   [183] = { name = "Molag Kena",                                   }
,   [184] = { name = "Brands of Imperium",                           }
,   [185] = { name = "Spell Power Cure",                             }
,   [186] = { name = "Jolting Arms",                                 }
,   [187] = { name = "Swamp Raider",                                 }
,   [188] = { name = "Storm Master",                                 }
,   [189] = nil
,   [190] = { name = "Scathing Mage",                                }
,   [191] = nil
,   [192] = nil
,   [193] = { name = "Overwhelming Surge",                           }
,   [194] = { name = "Combat Physician",                             }
,   [195] = { name = "Sheer Venom",                                  }
,   [196] = { name = "Leeching Plate",                               }
,   [197] = { name = "Tormentor",                                    }
,   [198] = { name = "Essence Thief",                                }
,   [199] = { name = "Shield Breaker",                               }
,   [200] = { name = "Phoenix",                                      }
,   [201] = { name = "Reactive Armor",                               }
,   [202] = nil
,   [203] = nil
,   [204] = { name = "Endurance",                                    }
,   [205] = { name = "Willpower",                                    }
,   [206] = { name = "Agility",                                      }
,   [207] = { name = "Law of Julianos",                 trait_ct = 6 }
,   [208] = { name = "Trial by Fire",                   trait_ct = 3 }
,   [209] = { name = "Armor of the Code",                            }
,   [210] = { name = "Mark of the Pariah",                           }
,   [211] = { name = "Permafrost",                                   }
,   [212] = { name = "Briarheart",                                   }
,   [213] = { name = "Glorious Defender",                            }
,   [214] = { name = "Para Bellum",                                  }
,   [215] = { name = "Elemental Succession",                         }
,   [216] = { name = "Hunt Leader",                                  }
,   [217] = { name = "Winterborn",                                   }
,   [218] = { name = "Trinimac's Valor",                             }
,   [219] = { name = "Morkuldin",                       trait_ct = 9  }
,   [220] = nil
,   [221] = nil
,   [222] = nil
,   [223] = nil
,   [224] = { name = "Tava's Favor",                    trait_ct = 5 }
,   [225] = { name = "Clever Alchemist",                trait_ct = 7 }
,   [226] = { name = "Eternal Hunt",                    trait_ct = 9 }
,   [227] = { name = "Bahraha's Curse",                              }
,   [228] = { name = "Syvarra's Scales",                             }
,   [229] = { name = "Twilight Remedy",                              }
,   [230] = { name = "Moondancer",                                   }
,   [231] = { name = "Lunar Bastion",                                }
,   [232] = { name = "Roar of Alkosh",                               }
,   [233] = nil
,   [234] = { name = "Marksman's Crest",                             }
,   [235] = { name = "Robes of Transmutation",                       }
,   [236] = { name = "Vicious Death",                                }
,   [237] = { name = "Leki's Focus",                                 }
,   [238] = { name = "Fasalla's Guile",                              }
,   [239] = { name = "Warrior's Fury",                               }
,   [240] = { name = "Kvatch Gladiator",                trait_ct = 6 }
,   [241] = { name = "Varen's Legacy",                  trait_ct = 7 }
,   [242] = { name = "Pelinal's Aptitude",              trait_ct = 9 }
,   [243] = { name = "Hide of Morihaus",                             }
,   [244] = { name = "Flanking Strategist",                          }
,   [245] = { name = "Sithis' Touch",                                }
,   [246] = { name = "Galerion's Revenge",                           }
,   [247] = { name = "Vicecanon of Venom",                           }
,   [248] = { name = "Thews of the Harbinger",                       }
,   [249] = nil
,   [250] = nil
,   [251] = nil
,   [252] = nil
,   [253] = { name = "Imperial Physique",                            }
,   [254] = nil
,   [255] = nil
,   [256] = { name = "Mighty Chudan",                                }
,   [257] = { name = "Velidreth",                                    }
,   [258] = { name = "Amber Plasm",                                  }
,   [259] = { name = "Heem-Jas' Retribution",                        }
,   [260] = { name = "Aspect of Mazzatun",                           }
,   [261] = { name = "Gossamer",                                     }
,   [262] = { name = "Widowmaker",                                   }
,   [263] = { name = "Hand of Mephala",                              }
,   [264] = { name = "Giant Spider",                                 }
,   [265] = { name = "Shadowrend",                                   }
,   [266] = { name = "Kra'gh",                                       }
,   [267] = { name = "Swarm Mother",                                 }
,   [268] = { name = "Sentinel of Rkugamz",                          }
,   [269] = { name = "Chokethorn",                                   }
,   [270] = { name = "Slimecraw",                                    }
,   [271] = { name = "Sellistrix",                                   }
,   [272] = { name = "Infernal Guardian",                            }
,   [273] = { name = "Ilambris",                                     }
,   [274] = { name = "Iceheart",                                     }
,   [275] = { name = "Stormfist",                                    }
,   [276] = { name = "Tremorscale",                                  }
,   [277] = { name = "Pirate Skeleton",                              }
,   [278] = { name = "The Troll King",                               }
,   [279] = { name = "Selene",                                       }
,   [280] = { name = "Grothdarr",                                    }
,   [281] = { name = "Armor of the Trainee",                         }
,   [282] = { name = "Vampire Cloak",                                }
,   [283] = { name = "Sword-Singer",                                 }
,   [284] = { name = "Order of Diagna",                              }
,   [285] = { name = "Vampire Lord",                                 }
,   [286] = { name = "Spriggan's Thorns",                            }
,   [287] = { name = "Green Pact",                                   }
,   [288] = { name = "Beekeeper's Gear",                             }
,   [289] = { name = "Spinner's Garments",                           }
,   [290] = { name = "Skooma Smuggler",                              }
,   [291] = { name = "Shalk Exoskeleton",                            }
,   [292] = { name = "Mother's Sorrow",                              }
,   [293] = { name = "Plague Doctor",                                }
,   [294] = { name = "Ysgramor's Birthright",                        }
,   [295] = { name = "Jailbreaker",                                  }
,   [296] = { name = "Spelunker",                                    }
,   [297] = { name = "Spider Cultist Cowl",                          }
,   [298] = { name = "Light Speaker",                                }
,   [299] = { name = "Toothrow",                                     }
,   [300] = { name = "Netch's Touch",                                }
,   [301] = { name = "Strength of the Automaton",                    }
,   [302] = { name = "Leviathan",                                    }
,   [303] = { name = "Lamia's Song",                                 }
,   [304] = { name = "Medusa",                                       }
,   [305] = { name = "Treasure Hunter",                              }
,   [306] = nil
,   [307] = { name = "Draugr Hulk",                                  }
,   [308] = { name = "Bone Pirate's Tatters",                        }
,   [309] = { name = "Knight-errant's Mail",                         }
,   [310] = { name = "Sword Dancer",                                 }
,   [311] = { name = "Rattlecage",                                   }
,   [312] = { name = "Tremorscale",                                  }
,   [313] = { name = "Masters Duel Wield",                           }
,   [314] = { name = "Masters Two Handed",                           }
,   [315] = { name = "Masters One Hand and Shield",                  }
,   [316] = { name = "Masters Destruction Staff",                    }
,   [317] = { name = "Masters Duel Wield",                           }
,   [318] = { name = "Masters Restoration Staff",                    }
,   [319] = nil
,   [320] = nil
,   [321] = nil
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
        base_text       = nil   -- "Consume to start quest"
                                -- "\nCraft a Rubedite Sword;"
                                -- " Quality: Legendary;"
                                -- " Trait: Defending;"
                                -- " Set: Way of the Arena;"
                                -- " Style: Primal"
    ,   request_item    = nil   -- Smithing.REQUEST_ITEMS[n]
    ,   set_bonus       = nil   -- Smithing.SET_BONUS[n]
    ,   trait_mat_name  = nil   -- "turquoise"
    ,   trait_index     = nil   -- 5  (1..9, used as last arg to GetSmithingResearchLineTraitInfo())
    ,   trait_num       = nil   -- ITEM_TRAIT_TYPE_WEAPON_DEFENDING
    ,   motif_num       = nil   -- 19 ITEMSTYLE_ENEMY_PRIMITIVE
    ,   motif_mat_name  = nil   -- "argentum"
    ,   improve_level   = nil   -- PURPLE, GOLD
    ,   mat_list        = {}    -- of MatRow
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
    self.set_bonus      = Smithing.SET_BONUS[set_num]
    if not self.set_bonus then return Fail("set not found "..tostring(set_num)) end
    self.trait_num      = trait_num
    self.trait_index    = self.request_item.trait_set[trait_num].trait_index
    self.trait_mat_name = self.request_item.trait_set[trait_num].mat_name
    self.motif_num      = motif_num
    self.motif_mat_name = Smithing.MOTIF[motif_num]
    if not self.motif_mat_name then return Fail("motif not found "..tostring(motif_num)) end
    self.improve_level  = Smithing.QUALITY[quality_num]
    if not self.improve_level then return Fail("quality not found "..tostring(quality_num)) end
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

-- Do we know the required motif and traits?
function Parser:ToKnowList()
    local Know = WritWorthy.Know
    local r = {}
                        -- Do you know this motif?
                        -- NEEDS TESTING: non-paged motifs like Breton
    local motif_known = IsSmithingStyleKnown( self.motif_num
                                            , self.request_item.motif_page )
d(string.format( "IsSmithingStyleKnown( %d , %d ) = %s"
               , self.motif_num
               , self.request_item.motif_page
               , tostring(motif_known)
               ))

    table.insert(r, Know:New({ name     = "motif"
                             , is_known = motif_known
                             , lack_msg = "Motif not known"
                             }))

                        -- Do you know this trait?
    local _,_,trait_known = GetSmithingResearchLineTraitInfo(
                              self.request_item.school.trade_skill_type
                            , self.request_item.research_line
                            , self.trait_index )
d(string.format( "GetSmithingResearchLineTraitInfo( %d , %d , %d ) = %s"
               , self.request_item.school.trade_skill_type
               , self.request_item.research_line
               , self.trait_index
               , tostring(trait_known)
               ))

    table.insert(r, Know:New({ name     = "trait"
                             , is_known = trait_known
                             , lack_msg = "Trait not known"
                             }))

                        -- Do you know enough traits to craft this set bonus?
    if self.set_bonus and self.set_bonus.trait_ct then
        local known_trait_ct = 0
        for trait_num, trait in pairs(self.request_item.trait_set) do
            local _,_,known = GetSmithingResearchLineTraitInfo(
                                      self.request_item.school.trade_skill_type
                                    , self.request_item.research_line
                                    , trait.trait_index )
d(string.format( "GetSmithingResearchLineTraitInfo( %d , %d , %d ) = %s    %d of %d"
               , self.request_item.school.trade_skill_type
               , self.request_item.research_line
               , trait.trait_index
               , tostring(known)
               , known_trait_ct
               , self.set_bonus.trait_ct
               ))
            if known then
                known_trait_ct = known_trait_ct + 1
            end
        end

        local s = string.format( "%d of %d traits required for set %s"
                               , known_trait_ct
                               , self.set_bonus.trait_ct
                               , tostring(self.set_bonus.name)
                               )
        table.insert(r, Know:New({ name     = "traits for set bonus"
                                 , is_known = self.set_bonus.trait_ct <= known_trait_ct
                                 , lack_msg = s }))
    else
        d("set_bonus:"..tostring(self.set_bonus))
    end

    return r
end
