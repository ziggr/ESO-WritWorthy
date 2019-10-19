-- Parse a Blacksmithing/Clothier/Woodworking master writ.

local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Define.lua
-- Do not define WW=WritWorthy here. We already use WW=Wood Working.

WritWorthy.Smithing = {}

local Smithing = WritWorthy.Smithing
local Util     = WritWorthy.Util
local Fail     = WritWorthy.Util.Fail
local Log      = WritWorthy.Log

local a = WritWorthy.RequiredSkill
local b = WritWorthy.RequiredSkill.FetchInfo
local c = WritWorthy.RequiredSkill.BS_TEMPER_EXPERTISE

local CRAFTING_TYPE_JEWELRYCRAFTING = CRAFTING_TYPE_JEWELRYCRAFTING or 7

function Smithing.Init()

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
,   armor_weight_name   = WritWorthy.SI("SI_ARMORTYPE3")
,   temper_skill        = WritWorthy.RequiredSkill.BS_TEMPER_EXPERTISE
,   motif_required      = true
    -- research lines
,   H1_AXE              =  1
,   H1_MACE             =  2
,   H1_SWORD            =  3
,   H2_BATTLE_AXE       =  4
,   H2_MAUL             =  5
,   H2_GREATSWORD       =  6
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
,   armor_weight_name   = WritWorthy.SI("SI_ARMORTYPE2")
,   temper_skill        = WritWorthy.RequiredSkill.CL_TEMPER_EXPERTISE
,   motif_required      = true
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
,   armor_weight_name   = WritWorthy.SI("SI_ARMORTYPE1")
,   temper_skill        = WritWorthy.RequiredSkill.CL_TEMPER_EXPERTISE
,   motif_required      = true
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
,   temper_skill        = WritWorthy.RequiredSkill.WW_TEMPER_EXPERTISE
,   motif_required      = true
    -- research lines
,   BOW                 =  1
,   FLAME_STAFF         =  2
,   ICE_STAFF           =  3
,   LIGHTNING_STAFF     =  4
,   RESTO_STAFF         =  5
,   SHIELD              =  6
}

Smithing.SCHOOL_JEWELRY = {
    trade_skill_type    = CRAFTING_TYPE_JEWELRYCRAFTING
,   base_mat_name       = "platinum"
,   green_mat_name      = "terne"
,   blue_mat_name       = "iridium"
,   purple_mat_name     = "zircon"
,   gold_mat_name       = "chromium"
,   armor_weight_name   = ""
,   temper_skill        = WritWorthy.RequiredSkill.JW_TEMPER_EXPERTISE
,   motif_required      = false
,   autocraft_not_implemented = true
    -- research lines
,   RING                =  2
,   NECKLACE            =  1
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
    [ITEM_TRAIT_TYPE_WEAPON_POWERED      ] = { trait_num = ITEM_TRAIT_TYPE_WEAPON_POWERED       , trait_index = 1 }
,   [ITEM_TRAIT_TYPE_WEAPON_CHARGED      ] = { trait_num = ITEM_TRAIT_TYPE_WEAPON_CHARGED       , trait_index = 2 }
,   [ITEM_TRAIT_TYPE_WEAPON_PRECISE      ] = { trait_num = ITEM_TRAIT_TYPE_WEAPON_PRECISE       , trait_index = 3 }
,   [ITEM_TRAIT_TYPE_WEAPON_INFUSED      ] = { trait_num = ITEM_TRAIT_TYPE_WEAPON_INFUSED       , trait_index = 4 }
,   [ITEM_TRAIT_TYPE_WEAPON_DEFENDING    ] = { trait_num = ITEM_TRAIT_TYPE_WEAPON_DEFENDING     , trait_index = 5 }
,   [ITEM_TRAIT_TYPE_WEAPON_TRAINING     ] = { trait_num = ITEM_TRAIT_TYPE_WEAPON_TRAINING      , trait_index = 6 }
,   [ITEM_TRAIT_TYPE_WEAPON_SHARPENED    ] = { trait_num = ITEM_TRAIT_TYPE_WEAPON_SHARPENED     , trait_index = 7 }
,   [ITEM_TRAIT_TYPE_WEAPON_DECISIVE     ] = { trait_num = ITEM_TRAIT_TYPE_WEAPON_DECISIVE      , trait_index = 8 }
,   [ITEM_TRAIT_TYPE_WEAPON_NIRNHONED    ] = { trait_num = ITEM_TRAIT_TYPE_WEAPON_NIRNHONED     , trait_index = 9 }
}
Smithing.TRAITS_ARMOR = {
    [ITEM_TRAIT_TYPE_ARMOR_STURDY        ] = { trait_num = ITEM_TRAIT_TYPE_ARMOR_STURDY         , trait_index = 1 }
,   [ITEM_TRAIT_TYPE_ARMOR_IMPENETRABLE  ] = { trait_num = ITEM_TRAIT_TYPE_ARMOR_IMPENETRABLE   , trait_index = 2 }
,   [ITEM_TRAIT_TYPE_ARMOR_REINFORCED    ] = { trait_num = ITEM_TRAIT_TYPE_ARMOR_REINFORCED     , trait_index = 3 }
,   [ITEM_TRAIT_TYPE_ARMOR_WELL_FITTED   ] = { trait_num = ITEM_TRAIT_TYPE_ARMOR_WELL_FITTED    , trait_index = 4 }
,   [ITEM_TRAIT_TYPE_ARMOR_TRAINING      ] = { trait_num = ITEM_TRAIT_TYPE_ARMOR_TRAINING       , trait_index = 5 }
,   [ITEM_TRAIT_TYPE_ARMOR_INFUSED       ] = { trait_num = ITEM_TRAIT_TYPE_ARMOR_INFUSED        , trait_index = 6 }
,   [ITEM_TRAIT_TYPE_ARMOR_PROSPEROUS    ] = { trait_num = ITEM_TRAIT_TYPE_ARMOR_PROSPEROUS     , trait_index = 7 }
,   [ITEM_TRAIT_TYPE_ARMOR_DIVINES       ] = { trait_num = ITEM_TRAIT_TYPE_ARMOR_DIVINES        , trait_index = 8 }
,   [ITEM_TRAIT_TYPE_ARMOR_NIRNHONED     ] = { trait_num = ITEM_TRAIT_TYPE_ARMOR_NIRNHONED      , trait_index = 9 }
}
Smithing.TRAITS_JEWELRY = {
    [ITEM_TRAIT_TYPE_JEWELRY_ARCANE      ] = { trait_num = ITEM_TRAIT_TYPE_JEWELRY_ARCANE       , trait_index = 1 }
,   [ITEM_TRAIT_TYPE_JEWELRY_HEALTHY     ] = { trait_num = ITEM_TRAIT_TYPE_JEWELRY_HEALTHY      , trait_index = 2 }
,   [ITEM_TRAIT_TYPE_JEWELRY_ROBUST      ] = { trait_num = ITEM_TRAIT_TYPE_JEWELRY_ROBUST       , trait_index = 3 }
,   [ITEM_TRAIT_TYPE_JEWELRY_TRIUNE      ] = { trait_num = ITEM_TRAIT_TYPE_JEWELRY_TRIUNE       , trait_index = 4 }
,   [ITEM_TRAIT_TYPE_JEWELRY_INFUSED     ] = { trait_num = ITEM_TRAIT_TYPE_JEWELRY_INFUSED      , trait_index = 5 }
,   [ITEM_TRAIT_TYPE_JEWELRY_PROTECTIVE  ] = { trait_num = ITEM_TRAIT_TYPE_JEWELRY_PROTECTIVE   , trait_index = 6 }
,   [ITEM_TRAIT_TYPE_JEWELRY_SWIFT       ] = { trait_num = ITEM_TRAIT_TYPE_JEWELRY_SWIFT        , trait_index = 7 }
,   [ITEM_TRAIT_TYPE_JEWELRY_HARMONY     ] = { trait_num = ITEM_TRAIT_TYPE_JEWELRY_HARMONY      , trait_index = 8 }
,   [ITEM_TRAIT_TYPE_JEWELRY_BLOODTHIRSTY] = { trait_num = ITEM_TRAIT_TYPE_JEWELRY_BLOODTHIRSTY , trait_index = 9 }
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
    [ITEMSTYLE_RACIAL_BRETON            ] = { is_simple =  true } -- Breton
,   [ITEMSTYLE_RACIAL_REDGUARD          ] = { is_simple =  true } -- Redguard
,   [ITEMSTYLE_RACIAL_ORC               ] = { is_simple =  true } -- Orc
,   [ITEMSTYLE_RACIAL_DARK_ELF          ] = { is_simple =  true } -- Dunmer
,   [ITEMSTYLE_RACIAL_NORD              ] = { is_simple =  true } -- Nord
,   [ITEMSTYLE_RACIAL_ARGONIAN          ] = { is_simple =  true } -- Argonian
,   [ITEMSTYLE_RACIAL_HIGH_ELF          ] = { is_simple =  true } -- Altmer
,   [ITEMSTYLE_RACIAL_WOOD_ELF          ] = { is_simple =  true } -- Bosmer
,   [ITEMSTYLE_RACIAL_KHAJIIT           ] = { is_simple =  true } -- Khajiit
,   [ITEMSTYLE_UNIQUE                   ] = nil                   -- Unique
,   [ITEMSTYLE_ORG_THIEVES_GUILD        ] = { pages_id  =  1423 } -- Thieves Guild
,   [ITEMSTYLE_ORG_DARK_BROTHERHOOD     ] = { pages_id  =  1661 } -- Dark Brotherhood
,   [ITEMSTYLE_DEITY_MALACATH           ] = { pages_id  =  1412 } -- Malacath
,   [ITEMSTYLE_AREA_DWEMER              ] = { pages_id  =  1144 } -- Dwemer
,   [ITEMSTYLE_AREA_ANCIENT_ELF         ] = { is_simple =  true } -- Ancient Elf
,   [ITEMSTYLE_DEITY_AKATOSH            ] = { pages_id  =  1660 } -- Order of the Hour
,   [ITEMSTYLE_AREA_REACH               ] = { is_simple =  true } -- Barbaric
,   [ITEMSTYLE_ENEMY_BANDIT             ] = nil                   -- Bandit
,   [ITEMSTYLE_ENEMY_PRIMITIVE          ] = { is_simple =  true } -- Primal
,   [ITEMSTYLE_ENEMY_DAEDRIC            ] = { is_simple =  true } -- Daedric
,   [ITEMSTYLE_DEITY_TRINIMAC           ] = { pages_id  =  1411 } -- Trinimac
,   [ITEMSTYLE_AREA_ANCIENT_ORC         ] = { pages_id  =  1341 } -- Ancient Orc
,   [ITEMSTYLE_ALLIANCE_DAGGERFALL      ] = { pages_id  =  1416 } -- Daggerfall Covenant
,   [ITEMSTYLE_ALLIANCE_EBONHEART       ] = { pages_id  =  1414 } -- Ebonheart Pact
,   [ITEMSTYLE_ALLIANCE_ALDMERI         ] = { pages_id  =  1415 } -- Aldmeri Dominion
,   [ITEMSTYLE_UNDAUNTED                ] = { pages_id  =  1348 } -- Mercenary
,   [ITEMSTYLE_RAIDS_CRAGLORN           ] = { pages_id  =  1714 } -- Celestial
,   [ITEMSTYLE_GLASS                    ] = { pages_id  =  1319 } -- Glass
,   [ITEMSTYLE_AREA_XIVKYN              ] = { pages_id  =  1181 } -- Xivkyn
,   [ITEMSTYLE_AREA_SOUL_SHRIVEN        ] = { is_simple =  true } -- Soul-Shriven
,   [ITEMSTYLE_ENEMY_DRAUGR             ] = { pages_id  =  1715 } -- Draugr
,   [ITEMSTYLE_ENEMY_MAORMER            ] = nil                   -- Maormer
,   [ITEMSTYLE_AREA_AKAVIRI             ] = { pages_id  =  1318 } -- Akaviri
,   [ITEMSTYLE_RACIAL_IMPERIAL          ] = { is_simple =  true } -- Imperial
,   [ITEMSTYLE_AREA_YOKUDAN             ] = { pages_id  =  1713 } -- Yokudan
,   [ITEMSTYLE_UNIVERSAL                ] = nil                   -- unused
,   [ITEMSTYLE_AREA_REACH_WINTER        ] = nil                   -- Reach Winter
,   [ITEMSTYLE_AREA_TSAESCI             ] = { crown_id  =132532 } -- Taesci
,   [ITEMSTYLE_ENEMY_MINOTAUR           ] = { pages_id  =  1662 } -- Minotaur
,   [ITEMSTYLE_EBONY                    ] = { pages_id  =  1798 } -- Ebony
,   [ITEMSTYLE_ORG_ABAHS_WATCH          ] = { pages_id  =  1422 } -- Abah's Watch
,   [ITEMSTYLE_HOLIDAY_SKINCHANGER      ] = { pages_id  =  1676 } -- Skinchanger
,   [ITEMSTYLE_ORG_MORAG_TONG           ] = { pages_id  =  1933 } -- Morag Tong
,   [ITEMSTYLE_AREA_RA_GADA             ] = { pages_id  =  1797 } -- Ra Gada
,   [ITEMSTYLE_ENEMY_DROMOTHRA          ] = { pages_id  =  1659 } -- Dro-m'Athra
,   [ITEMSTYLE_ORG_ASSASSINS            ] = { pages_id  =  1424 } -- Assassins League
,   [ITEMSTYLE_ORG_OUTLAW               ] = { pages_id  =  1417 } -- Outlaw
,   [ITEMSTYLE_ORG_REDORAN              ] = { pages_id  =  2022 } -- Redoran
,   [ITEMSTYLE_ORG_HLAALU               ] = { pages_id  =  2021 } -- Hlaalu
,   [ITEMSTYLE_ORG_ORDINATOR            ] = { pages_id  =  1935 } -- Militant Ordinator
,   [ITEMSTYLE_ORG_TELVANNI             ] = { pages_id  =  2023 } -- Telvanni
,   [ITEMSTYLE_ORG_BUOYANT_ARMIGER      ] = { pages_id  =  1934 } -- Buoyant Armiger
,   [ITEMSTYLE_HOLIDAY_FROSTCASTER      ] = { crown_id  = 96954 } -- Stalhrim Frostcaster
,   [ITEMSTYLE_AREA_ASHLANDER           ] = { pages_id  =  1932 } -- Ashlander
,   [ITEMSTYLE_ORG_WORM_CULT            ] = { pages_id  =  2120 } -- Worm Cult
,   [ITEMSTYLE_ENEMY_SILKEN_RING        ] = { pages_id  =  1796 } -- Silken Ring
,   [ITEMSTYLE_ENEMY_MAZZATUN           ] = { pages_id  =  1795 } -- Mazzatun
,   [ITEMSTYLE_HOLIDAY_GRIM_HARLEQUIN   ] = { crown_id  = 82039 } -- Grim Harlequin
,   [ITEMSTYLE_HOLIDAY_HOLLOWJACK       ] = { pages_id  =  1545 } -- Hollowjack
    -- Hollowjack/59 was the last named ITEMSTYLE_X constant.
    -- It's all numeric from here on out.
,   [ 61 ] = { pages_id  =  2098 } -- Bloodforge
,   [ 62 ] = { pages_id  =  2097 } -- Dreadhorn
,   [ 65 ] = { pages_id  =  2044 } -- Apostle
,   [ 66 ] = { pages_id  =  2045 } -- Ebonshadow
,   [ 67 ] = nil                   -- Undaunted 67
,   [ 68 ] = nil                   -- Use Me
,   [ 69 ] = { pages_id  =  2190 } -- Fang Lair
,   [ 70 ] = { pages_id  =  2189 } -- Scalecaller
,   [ 71 ] = { pages_id  =  2186 } -- Psijic Order
,   [ 72 ] = { pages_id  =  2187 } -- Sapiarch
,   [ 73 ] = { pages_id  =  2319 } -- Welkynar
,   [ 74 ] = { pages_id  =  2188 } -- Dremora
,   [ 75 ] = { pages_id  =  2285 } -- Pyandonean
,   [ 76 ] = nil                   -- Divine Prosecution
,   [ 77 ] = { pages_id  =  2317 } -- Huntsman
,   [ 78 ] = { pages_id  =  2318 } -- Silver Dawn
,   [ 79 ] = { pages_id  =  2360 } -- Dead-Water
,   [ 80 ] = { pages_id  =  2359 } -- Honor Guard
,   [ 81 ] = { pages_id  =  2361 } -- Elder Argonian
,   [ 82 ] = { pages_id  =  2503 } -- Coldsnap
,   [ 83 ] = { pages_id  =  2504 } -- Meridian
,   [ 84 ] = { pages_id  =  2505 } -- Anequina
,   [ 85 ] = { pages_id  =  2506 } -- Pellitine
,   [ 86 ] = { pages_id  =  2507 } -- Sunspire
,   [ 87 ] = nil                   -- Dragon Bone
,   [ 88 ] = { pages_id  =  2628 } -- Moongrave
,   [ 89 ] = { pages_id  =  2629 } -- Stags of Z'en
,   [ 90 ] = nil                   -- Witches Festival 2019
,   [ 91 ] = nil                   -- ?
,   [ 92 ] = { pages_id  =  2630 } -- Dragonguard
,   [ 93 ] = nil                   -- Moongrave Fane
,   [ 94 ] = nil                   -- New Moon
,   [ 95 ] = nil                   -- Shields of Senchal

                        -- How to learn pages_id for new motifs:
                        -- 1. open the 'J' Quest screen
                        -- 2. select Achievements tab
                        -- 3. right-click a "X Style Master" achievement
                        -- 4. Link in chat
                        -- 5. /breakitem the above
                        -- The quest id, aka pages_id, is the first number.
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
-- dol_pattern_index is a value for Dolgubon's LibLazyCrafting, patternIndex enum.
--
                        -- abbreviations to make the table more concise.
local HVY    = Smithing.SCHOOL_HEAVY
local MED    = Smithing.SCHOOL_MEDIUM
local LGT    = Smithing.SCHOOL_LIGHT
local WW     = Smithing.SCHOOL_WOOD
local JW     = Smithing.SCHOOL_JEWELRY
local WEAPON = Smithing.TRAITS_WEAPON
local ARMOR  = Smithing.TRAITS_ARMOR
local TJW    = Smithing.TRAITS_JEWELRY
local PG     = Smithing.MOTIF_PAGE

Smithing.REQUEST_ITEMS = {
  [53] = { item_id = 53, example_item_id = 43529, item_name = "Rubedite Axe",                school = HVY, base_mat_ct = 11, trait_set = WEAPON, research_line = HVY.H1_AXE,         motif_page = PG.AXES     , dol_pattern_index =  1 }
, [56] = { item_id = 56, example_item_id = 43530, item_name = "Rubedite Mace",               school = HVY, base_mat_ct = 11, trait_set = WEAPON, research_line = HVY.H1_MACE,        motif_page = PG.MACES    , dol_pattern_index =  2 }
, [59] = { item_id = 59, example_item_id = 43531, item_name = "Rubedite Sword",              school = HVY, base_mat_ct = 11, trait_set = WEAPON, research_line = HVY.H1_SWORD,       motif_page = PG.SWORDS   , dol_pattern_index =  3 }
, [68] = { item_id = 68, example_item_id = 43532, item_name = "Rubedite Greataxe",           school = HVY, base_mat_ct = 14, trait_set = WEAPON, research_line = HVY.H2_BATTLE_AXE,  motif_page = PG.AXES     , dol_pattern_index =  4 }
, [67] = { item_id = 67, example_item_id = 43534, item_name = "Rubedite Greatsword",         school = HVY, base_mat_ct = 14, trait_set = WEAPON, research_line = HVY.H2_GREATSWORD,  motif_page = PG.SWORDS   , dol_pattern_index =  6 }
, [69] = { item_id = 69, example_item_id = 43533, item_name = "Rubedite Maul",               school = HVY, base_mat_ct = 14, trait_set = WEAPON, research_line = HVY.H2_MAUL,        motif_page = PG.MACES    , dol_pattern_index =  5 }
, [62] = { item_id = 62, example_item_id = 43535, item_name = "Rubedite Dagger",             school = HVY, base_mat_ct = 10, trait_set = WEAPON, research_line = HVY.DAGGER,         motif_page = PG.DAGGERS  , dol_pattern_index =  7 }

, [46] = { item_id = 46, example_item_id = 43537, item_name = "Rubedite Cuirass",            school = HVY, base_mat_ct = 15, trait_set = ARMOR , research_line = HVY.CHEST,          motif_page = PG.CHESTS   , dol_pattern_index =  8 }
, [50] = { item_id = 50, example_item_id = 43538, item_name = "Rubedite Sabatons",           school = HVY, base_mat_ct = 13, trait_set = ARMOR , research_line = HVY.FEET,           motif_page = PG.BOOTS    , dol_pattern_index =  9 }
, [52] = { item_id = 52, example_item_id = 43539, item_name = "Rubedite Gauntlets",          school = HVY, base_mat_ct = 13, trait_set = ARMOR , research_line = HVY.HANDS,          motif_page = PG.GLOVES   , dol_pattern_index = 10 }
, [44] = { item_id = 44, example_item_id = 43562, item_name = "Rubedite Helm",               school = HVY, base_mat_ct = 13, trait_set = ARMOR , research_line = HVY.HEAD,           motif_page = PG.HELMETS  , dol_pattern_index = 11 }
, [49] = { item_id = 49, example_item_id = 43540, item_name = "Rubedite Greaves",            school = HVY, base_mat_ct = 14, trait_set = ARMOR , research_line = HVY.LEGS,           motif_page = PG.LEGS     , dol_pattern_index = 12 }
, [47] = { item_id = 47, example_item_id = 43541, item_name = "Rubedite Pauldron",           school = HVY, base_mat_ct = 13, trait_set = ARMOR , research_line = HVY.SHOULDERS,      motif_page = PG.SHOULDERS, dol_pattern_index = 13 }
, [48] = { item_id = 48, example_item_id = 43542, item_name = "Rubedite Girdle",             school = HVY, base_mat_ct = 13, trait_set = ARMOR , research_line = HVY.WAIST,          motif_page = PG.BELTS    , dol_pattern_index = 14 }

, [28] = { item_id = 28, example_item_id = 43543, item_name = "Ancestor Silk Robe",          school = LGT, base_mat_ct = 15, trait_set = ARMOR , research_line = LGT.CHEST,          motif_page = PG.CHESTS   , dol_pattern_index =  1 }
, [75] = { item_id = 75, example_item_id = 44241, item_name = "Ancestor Silk Jerkin",        school = LGT, base_mat_ct = 15, trait_set = ARMOR , research_line = LGT.CHEST,          motif_page = PG.CHESTS   , dol_pattern_index =  2 }
, [32] = { item_id = 32, example_item_id = 43544, item_name = "Ancestor Silk Shoes",         school = LGT, base_mat_ct = 13, trait_set = ARMOR , research_line = LGT.FEET,           motif_page = PG.BOOTS    , dol_pattern_index =  3 }
, [34] = { item_id = 34, example_item_id = 43545, item_name = "Ancestor Silk Gloves",        school = LGT, base_mat_ct = 13, trait_set = ARMOR , research_line = LGT.HANDS,          motif_page = PG.GLOVES   , dol_pattern_index =  4 }
, [26] = { item_id = 26, example_item_id = 43564, item_name = "Ancestor Silk Hat",           school = LGT, base_mat_ct = 13, trait_set = ARMOR , research_line = LGT.HEAD,           motif_page = PG.HELMETS  , dol_pattern_index =  5 }
, [31] = { item_id = 31, example_item_id = 43546, item_name = "Ancestor Silk Breeches",      school = LGT, base_mat_ct = 14, trait_set = ARMOR , research_line = LGT.LEGS,           motif_page = PG.LEGS     , dol_pattern_index =  6 }
, [29] = { item_id = 29, example_item_id = 43547, item_name = "Ancestor Silk Epaulets",      school = LGT, base_mat_ct = 13, trait_set = ARMOR , research_line = LGT.SHOULDERS,      motif_page = PG.SHOULDERS, dol_pattern_index =  7 }
, [30] = { item_id = 30, example_item_id = 43548, item_name = "Ancestor Silk Sash",          school = LGT, base_mat_ct = 13, trait_set = ARMOR , research_line = LGT.WAIST,          motif_page = PG.BELTS    , dol_pattern_index =  8 }

, [37] = { item_id = 37, example_item_id = 43550, item_name = "Rubedo Leather Jack",         school = MED, base_mat_ct = 15, trait_set = ARMOR , research_line = MED.CHEST,          motif_page = PG.CHESTS   , dol_pattern_index =  9 }
, [41] = { item_id = 41, example_item_id = 43551, item_name = "Rubedo Leather Boots",        school = MED, base_mat_ct = 13, trait_set = ARMOR , research_line = MED.FEET,           motif_page = PG.BOOTS    , dol_pattern_index = 10 }
, [43] = { item_id = 43, example_item_id = 43552, item_name = "Rubedo Leather Bracers",      school = MED, base_mat_ct = 13, trait_set = ARMOR , research_line = MED.HANDS,          motif_page = PG.GLOVES   , dol_pattern_index = 11 }
, [35] = { item_id = 35, example_item_id = 43563, item_name = "Rubedo Leather Helmet",       school = MED, base_mat_ct = 13, trait_set = ARMOR , research_line = MED.HEAD,           motif_page = PG.HELMETS  , dol_pattern_index = 12 }
, [40] = { item_id = 40, example_item_id = 43553, item_name = "Rubedo Leather Guards",       school = MED, base_mat_ct = 14, trait_set = ARMOR , research_line = MED.LEGS,           motif_page = PG.LEGS     , dol_pattern_index = 13 }
, [38] = { item_id = 38, example_item_id = 43554, item_name = "Rubedo Leather Arm Cops",     school = MED, base_mat_ct = 13, trait_set = ARMOR , research_line = MED.SHOULDERS,      motif_page = PG.SHOULDERS, dol_pattern_index = 14 }
, [39] = { item_id = 39, example_item_id = 43555, item_name = "Rubedo Leather Belt",         school = MED, base_mat_ct = 13, trait_set = ARMOR , research_line = MED.WAIST,          motif_page = PG.BELTS    , dol_pattern_index = 15 }

, [70] = { item_id = 70, example_item_id = 43549, item_name = "Ruby Ash Bow",                school = WW,  base_mat_ct = 12, trait_set = WEAPON, research_line = WW.BOW,             motif_page = PG.BOWS     , dol_pattern_index =  1 }
, [72] = { item_id = 72, example_item_id = 43557, item_name = "Ruby Ash Inferno Staff",      school = WW,  base_mat_ct = 12, trait_set = WEAPON, research_line = WW.FLAME_STAFF,     motif_page = PG.STAVES   , dol_pattern_index =  3 }
, [73] = { item_id = 73, example_item_id = 43558, item_name = "Ruby Ash Frost Staff",        school = WW,  base_mat_ct = 12, trait_set = WEAPON, research_line = WW.ICE_STAFF,       motif_page = PG.STAVES   , dol_pattern_index =  4 }
, [74] = { item_id = 74, example_item_id = 43559, item_name = "Ruby Ash Lightning Staff",    school = WW,  base_mat_ct = 12, trait_set = WEAPON, research_line = WW.LIGHTNING_STAFF, motif_page = PG.STAVES   , dol_pattern_index =  5 }
, [71] = { item_id = 71, example_item_id = 43560, item_name = "Ruby Ash Healing Staff",      school = WW,  base_mat_ct = 12, trait_set = WEAPON, research_line = WW.RESTO_STAFF,     motif_page = PG.STAVES   , dol_pattern_index =  6 }

, [65] = { item_id = 65, example_item_id = 43556, item_name = "Ruby Ash Shield",             school = WW,  base_mat_ct = 14, trait_set = ARMOR , research_line = WW.SHIELD,          motif_page = PG.SHIELDS  , dol_pattern_index =  2 }

, [24] = { item_id = 24 ,example_item_id = 43536, item_name = "Platinum Ring",               school = JW,  base_mat_ct = 10, trait_set = TJW   , research_line = JW.RING,            motif_page = nil         , dol_pattern_index =  1 }
, [18] = { item_id = 18 ,example_item_id = 43561, item_name = "Platinum Necklace",           school = JW,  base_mat_ct = 15, trait_set = TJW   , research_line = JW.NECKLACE,        motif_page = nil         , dol_pattern_index =  2 }

}

WritWorthy.COLORIZED_QUALITY = {}
for quality = 1,5 do
    local quality_text = WritWorthy.SI("SI_ITEMQUALITY"..tostring(quality))
    local color_def = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, quality))
    WritWorthy.COLORIZED_QUALITY[quality] = color_def:Colorize(quality_text)
end

-- Improvement Material Counts -----------------------------------------------
--
-- Material counts for improving to purple or gold.
--
Smithing.PURPLE = {
    index          = 4
,   name           = WritWorthy.COLORIZED_QUALITY[4]
,   green_mat_ct   = 2
,   blue_mat_ct    = 3
,   purple_mat_ct  = 4
,   gold_mat_ct    = 0
}

Smithing.GOLD = {
    index          = 5
,   name           = WritWorthy.COLORIZED_QUALITY[5]
,   green_mat_ct   = 2
,   blue_mat_ct    = 3
,   purple_mat_ct  = 4
,   gold_mat_ct    = 8
}

Smithing.GREEN_JEWELRY = {
    index          = 2
,   name           = WritWorthy.COLORIZED_QUALITY[2]
,   green_mat_ct   = 1
,   blue_mat_ct    = 0
,   purple_mat_ct  = 0
,   gold_mat_ct    = 0
}

Smithing.BLUE_JEWELRY = {
    index          = 3
,   name           = WritWorthy.COLORIZED_QUALITY[3]
,   green_mat_ct   = 1
,   blue_mat_ct    = 2
,   purple_mat_ct  = 0
,   gold_mat_ct    = 0
}

Smithing.PURPLE_JEWELRY = {
    index          = 4
,   name           = WritWorthy.COLORIZED_QUALITY[4]
,   green_mat_ct   = 1
,   blue_mat_ct    = 2
,   purple_mat_ct  = 3
,   gold_mat_ct    = 0
}

Smithing.GOLD_JEWELRY = {
    index          = 5
,   name           = WritWorthy.COLORIZED_QUALITY[5]
,   green_mat_ct   = 1
,   blue_mat_ct    = 2
,   purple_mat_ct  = 3
,   gold_mat_ct    = 4
}

-- indices are item_link writ3 numbers (1-3 are white..blue, not used here)
Smithing.QUALITY = {
    [4] = Smithing.PURPLE
,   [5] = Smithing.GOLD
}
Smithing.QUALITY_JEWELRY = {
    [2] = Smithing.GREEN_JEWELRY
,   [3] = Smithing.BLUE_JEWELRY
,   [4] = Smithing.PURPLE_JEWELRY
,   [5] = Smithing.GOLD_JEWELRY
}

end -- function WritWorthy.Smithing.Init()
-- end of Init() =============================================================


-- Roll through different values to explore set indexes or whatever.
-- Record results to savedVariables.discover.XXX
--
-- 1. game chat:  /script WritWorthy.Smithing.Discover()
--    output      WritWorthy: discovered xxx_ct: 99
-- 2.             /reloadui to write to SavedVariables.
-- 3. workstation make get  -or-  make getpts
--                SavedVariables copied to workstation
-- 4. Gaze upon data/WritWorthy.lua's discover.XXX
--
function Smithing.Discover()
    WritWorthy.savedVariables.discover = {}
                        -- Scan set bonus, aka writ4
    local set = {}
    local set_ct = 0
    local t = "|H1:item:138798:6:1:0:0:0:18:255:4:%d:23:0:0:0:0:0:0:0:0:0:76000|h|h"
    local re = "Set: ([^;]*)"
    for i=1,500 do
        local item_link = string.format(t, i)
        local b = GenerateMasterWritBaseText(item_link)
        local _,_,f = string.find(b,re)
        set[i] = f
        if f then set_ct = set_ct + 1 end
    end
    WritWorthy.savedVariables.discover.writ4_smithing_set_bonus = set
    d("WritWorthy: discovered set_ct:"..tostring(set_ct))

                        -- Scan requested item id aka writ1
                        -- (not ZOS itemId)
                        -- Rubedite 1h Axe, Ancestor Silk Shoes, and so on
    -- local t = "|H1:item:119563:6:1:0:0:0:%d:188:4:324:4:51:0:0:0:0:0:0:0:0:72000|h|h" -- bs
    -- local t = "|H1:item:119694:6:1:0:0:0:%d:194:4:95:16:42:0:0:0:0:0:0:0:0:63250|h|h"  -- cl
    -- local t = "|H1:item:121530:6:1:0:0:0:%d:192:5:241:8:9:0:0:0:0:0:0:0:0:451500|h|h" -- ww
    local item = {}
    local item_ct = 0
    local t = "|H1:item:138798:6:1:0:0:0:%d:255:4:37:23:0:0:0:0:0:0:0:0:0:76000|h|h"
    local re = "Craft an? (.*);"
    for i=1,100 do
        local item_link = string.format(t, i)
        local b = GenerateMasterWritBaseText(item_link)
        local _,_,f = string.find(b,re)
        item[i] = f
        if f then item_ct = item_ct + 1 end
    end
    WritWorthy.savedVariables.discover.writ4_smithing_item = item
    d("WritWorthy: discovered item_ct:"..tostring(item_ct))

                        -- scan writ2: material
                        -- We only use CP150 mats, so
                        -- most of this range is pointless.
    local mat = {}
    local mat_ct = 0
    local t = "|H1:item:138798:6:1:0:0:0:18:%d:4:37:23:0:0:0:0:0:0:0:0:0:76000|h|h"
    local re = "Craft an? ([^;]*);"
    for i=170,255 do
        local item_link = string.format(t, i)
        local b = GenerateMasterWritBaseText(item_link)
        local _,_,f = string.find(b,re)
        mat[i] = f
        if f then mat_ct = mat_ct + 1 end
    end
    WritWorthy.savedVariables.discover.writ2_smithing_mat = mat
    d("WritWorthy: discovered mat_ct:"..tostring(mat_ct))

                        -- writ5: trait
    local trait = {}
    local trait_ct = 0
    local t = "|H1:item:119563:6:1:0:0:0:56:188:4:324:%d:51:0:0:0:0:0:0:0:0:72000|h|h"
    local re = "Trait: ([^;]*);"
    for i=1,50 do
        local item_link = string.format(t, i)
        local b = GenerateMasterWritBaseText(item_link)
        local _,_,f = string.find(b,re)
        trait[i] = f
        if f then trait_ct = trait_ct + 1 end
    end
    WritWorthy.savedVariables.discover.writ5_smithing_trait = trait
    d("WritWorthy: discovered trait_ct:"..tostring(trait_ct))

                        -- writ6: motif
    local motif = {}
    local motif_ct = 0
    local t = "|H1:item:119563:6:1:0:0:0:56:188:4:324:4:%d:0:0:0:0:0:0:0:0:72000|h|h"
    local re = "Style: ([^;]*)"
    for i=1,100 do
        local item_link = string.format(t, i)
        local b = GenerateMasterWritBaseText(item_link)
        local _,_,f = string.find(b,re)
        motif[i] = f
        if f then motif_ct = motif_ct + 1 end
    end
    WritWorthy.savedVariables.discover.writ6_smithing_motif = motif
    d("WritWorthy: discovered motif_ct:"..tostring(motif_ct))

    local skill_line = {}
    local skill_line_ct = GetNumSkillLines(SKILL_TYPE_TRADESKILL)
    local total_ability_ct = 0
    for skill_index=1,skill_line_ct do
        local s = {GetSkillLineInfo(SKILL_TYPE_TRADESKILL, skill_index)}
        local ss = { name = s[1]
                   , rank = s[2]
                   , discovered = s[3]
                   , skill_line_id = s[4]
                   , advised = s[5]
                   , unlock_text = s[6]
                   , ability = {}
                   }
        skill_line[skill_index] = ss

        local ability_ct = GetNumSkillAbilities(SKILL_TYPE_TRADESKILL, skill_index)
        for ability_index = 1,ability_ct do
            local a = { GetSkillAbilityInfo(SKILL_TYPE_TRADESKILL, skill_index, ability_index)}
            local ability_id = GetSkillAbilityId(SKILL_TYPE_TRADESKILL, skill_index, ability_index)
            local aa = { name = a[1]
                       , texture_name = a[2]
                       , earned_rank = a[3]
                       , passive = a[4]
                       , ultimate = a[5]
                       , purchased = a[6]
                       , progression_index = a[7]
                       , rank_index = a[8]
                       , ability_id = ability_id
                       }
            ss.ability[ability_index] = aa
            total_ability_ct = total_ability_ct+ 1
        end
    end
    WritWorthy.savedVariables.discover.skill_line = skill_line
    d("WritWorthy: discovered ability_ct:"..tostring(total_ability_ct))
end


-- Parser ====================================================================

Smithing.Parser = {
    class = "smithing"
}
local Parser = Smithing.Parser

function Parser:New()
    local o = {
        request_item    = nil   -- Smithing.REQUEST_ITEMS[n]
    ,   set_bonus       = nil   -- { name, trait_ct }
    ,   trait_num       = nil   -- ITEM_TRAIT_TYPE_WEAPON_DEFENDING
    ,   motif_num       = nil   -- 19 ITEMSTYLE_ENEMY_PRIMITIVE
    ,   motif           = nil   -- Smithing.MOTIF[n]
    ,   improve_level   = nil   -- PURPLE, GOLD
    ,   mat_list        = {}    -- of MatRow
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Parser:GetSetBonus(set_id)
    local r = {}
                        -- Fetch set data from Baertram's LibSets, if possible.
    Parser.client_lang = Parser.client_lang or GetCVar("language.2")
    if WritWorthy.LibSets() and WritWorthy.LibSets().GetSetInfo then
        local si = WritWorthy.LibSets().GetSetInfo(set_id)
        if si then
            r.name      = si.names and (si.names[Parser.client_lang] or si.names["en"])
            r.trait_ct  = si.traitsNeeded
        else
            r.name      = string.format("Unknown Set %d", set_id)
            r.trait_ct  = 0
            Log.Warn("LibSets lacks data for set_id:%d, using hardcoded: "..tostring(r.name))
        end
    end
                        -- Force set name to I18N name, in case user
                        -- wants EN names on a DE client.
    r.name = WritWorthy.SetName(set_id) or r.name

                        -- Remember the set_id because it's helpful elsewhere.
    if not r.set_id then
        r.set_id = set_id
    end
    return r
end

function Parser:ParseItemLink(item_link)
    Log:StartNewEvent("ParseItemLink: %s %s", self.class, item_link)
    local fields        = Util.ToWritFields(item_link)
    local item_num      = fields.writ1
    local material_num  = fields.writ2
    local quality_num   = fields.writ3
    local set_num       = fields.writ4
    local trait_num     = fields.writ5
    local motif_num     = fields.writ6

-- wr 1 item_num      24  "Ring"
--    2 material_num 255  "platinum"
--    3 quality_num    5  "Legendary"
--    4 set_num      224  "Tava's Favor"
--    5 trait_num     33  "infused"
--    6 motif_num      0

    self.request_item   = Smithing.REQUEST_ITEMS[item_num]
    if not self.request_item then return nil end
                        -- Replace hardcoded US English name with a l10n one.
    if not self.request_item.tr then
        local fmt = "|H0:item:%d:308:50:0:0:0:0:0:0:0:0:0:0:0:0:2:0:0:0:0:0|h|h"
        local ll = string.format(fmt, self.request_item.example_item_id)
        self.request_item.tr = self.request_item.item_name -- retain old name for debugging.
        self.request_item.item_name = WritWorthy.Gear(self.request_item.example_item_id)
    end
    Log:Add("request_item"
           , tostring(item_num).." "..tostring(self.request_item.item_name))
    self.crafting_type = self.request_item.school.trade_skill_type
    self.set_bonus      = self:GetSetBonus(set_num)
    if not self.set_bonus then return Fail("set not found "..tostring(set_num)) end
    Log:Add("set_bonus", self.set_bonus)

    self.trait          = self.request_item.trait_set[trait_num]
    self.trait_num      = trait_num
                        -- trait_name used just for debugging,
                        -- not as a key or UI string anywhere.
    self.trait.trait_name = self.trait.trait_name
                            or WritWorthy.SI("SI_ITEMTRAITTYPE"..tostring(trait_num))

    self.trait.mat_link = self.trait.mat_link
                          or GetSmithingTraitItemLink(trait_num + 1)
    Log:Add("trait", self.trait)

    self.motif_num      = motif_num
    self.motif          = Smithing.MOTIF[motif_num]
    if self.motif then
        self.motif.motif_num     = motif_num
        self.motif.motif_name    = self.motif.motif_name
                                   or WritWorthy.Motif(motif_num)
        self.motif.mat_item_link = self.motif.mat_item_link
                                   or GetItemStyleMaterialLink(motif_num)
    end
    Log:Add("motif", self.motif)

    if self.request_item.school.motif_required then
        if not self.motif then
            return Fail("motif not found "..tostring(motif_num))
        end
    else
        self.motif_num = nil
    end
    if self.crafting_type == CRAFTING_TYPE_JEWELRYCRAFTING then
        self.improve_level  = Smithing.QUALITY_JEWELRY[quality_num]
    else
        self.improve_level  = Smithing.QUALITY[quality_num]
    end
    Log:Add("improve", self.improve_level)
    if not self.improve_level then
        return Fail("quality not found "..tostring(quality_num))
    end
    return self
end

-- Convert result of ParseBaseText() into  a flat list of items.
function Parser:ToMatList()
    -- Log:StartNewEvent("ToMatList: %s", self.class)
    local MatRow = WritWorthy.MatRow
    local ml = {}
    table.insert(ml, MatRow:FromName( self.request_item.school.base_mat_name
                                    , self.request_item.base_mat_ct ))
    table.insert(ml, MatRow:FromLink( self.trait.mat_link ))
    if self.motif and self.motif.mat_item_link then
        table.insert(ml, MatRow:FromLink( self.motif.mat_item_link ))
    -- elseif self.motif and self.motif.mat_name then
    --     table.insert(ml, MatRow:FromName( self.motif.mat_name ))
    end
    if 0 < self.improve_level.green_mat_ct then
        table.insert(ml, MatRow:FromName( self.request_item.school.green_mat_name
                                        , self.improve_level.green_mat_ct ))
    end
    if 0 < self.improve_level.blue_mat_ct then
        table.insert(ml, MatRow:FromName( self.request_item.school.blue_mat_name
                                        , self.improve_level.blue_mat_ct ))
    end
    if 0 < self.improve_level.purple_mat_ct then
        table.insert(ml, MatRow:FromName( self.request_item.school.purple_mat_name
                                        , self.improve_level.purple_mat_ct ))
    end
    if 0 < self.improve_level.gold_mat_ct then
        table.insert(ml, MatRow:FromName( self.request_item.school.gold_mat_name
                                        , self.improve_level.gold_mat_ct ))
    end
    self.mat_list = ml
    return self.mat_list
end

-- Do we know the required motif and traits?
function Parser:ToKnowList()
    Log:StartNewEvent("ToKnowList: %s", self.class)
    local Know = WritWorthy.Know
    local r = {}

                        -- Do you know this motif?
                        --
                        -- First see if we just know the whole book.
                        --
                        -- This works for earlier motifs that don't have
                        -- separate pages, and for Crown Store exclusives,
                        -- but NOT for paged books like Glass or Xivkyn or Ebony,
                        -- which have been seen to incorrectly return true when
                        -- you do NOT know the whole book
    if self.request_item.school.motif_required then
        local motif_known = false
        if self.motif.is_simple or self.motif.crown_id then
            motif_known = IsSmithingStyleKnown(self.motif_num)
            Log:Add("motif book IsSmithingStyleKnown("
                ..tostring(self.motif_num)..") = "..tostring(motif_known))
        end
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
        local fmt = WritWorthy.Str("know_err_motif")
        local msg   = string.format(fmt, self.motif.motif_name)
        table.insert(r, Know:New({ name     = title
                                 , is_known = motif_known
                                 , lack_msg = msg
                                 }))
    end

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
    local fmt = WritWorthy.Str("know_err_trait")
    local msg   = string.format(fmt, self.trait.trait_name, line_name)
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
        local msg   = string.format( WritWorthy.Str("know_err_trait_ct_too_low")
                               , known_trait_ct
                               , self.set_bonus.trait_ct
                               , tostring(self.set_bonus.name)
                               )
        table.insert(r, Know:New({ name     = title
                                 , is_known = self.set_bonus.trait_ct <= known_trait_ct
                                 , lack_msg = msg }))
    end
                        -- Is this a Legendary request and do you have the
                        -- passive skill to minimize the gold tempers required?
                        -- Skill not REQUIRED to craft, but worth at least a warning.
                        -- WritWorthyInventoryList will refuse to queue such an
                        -- unnecessarily expensive waste of gold tempers.
    if self.improve_level.index == 5 then
        local skill = self.request_item.school.temper_skill
        local know = skill:ToKnow()
        know.is_warn = true
        table.insert(r, know)
    end

    return r
end

function Parser:WarningText()
    if self.motif then return nil end
    if      self.request_item
        and self.request_item.school
        and not self.request_item.school.motif_require  then
        return nil
    end
    return Util.red(string.format("Unknown motif: %d", self.motif_num))
end


-- Dolgubon's Lazy Set Crafter integration -----------------------------------
--[[
styleIndex from DSC.ComboBox.Style.(selected)[1]
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
-- end notes -----------------------------------------------------------------
--]]

-- Create a Dolgubon's Lazy Set Crafter request.
function Parser:ToDolRequest(unique_id)
                        -- API struct passed to LibLazyCrafter for
                        -- eventual crafting.
    local o = {}
    o.patternIndex = self.request_item.dol_pattern_index
    o.isCP         = true
    o.level        = 150
    o.styleIndex   = self.motif_num -- 2017-08-14 no longer need + 1
    o.traitIndex   = self.trait_num + 1
    o.useUniversalStyleItem = false
    o.station      = self.request_item.school.trade_skill_type
    o.setIndex     = self.ToDolSetID(self.set_bonus)
    o.quality      = self.improve_level.index
    o.autocraft    = true
    o.reference    = unique_id
                        -- Positional arguments to LibLazyCrafter:CraftSmithingItemByLevel()
    local args = {
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
    return { ["function"]        = "CraftSmithingItemByLevel"
           , ["args"    ]        = args
           }
end


-- Temporary switch between old Dolgubon-proprietary setId numbers and
-- ESO Client setId numbers. Dolgubon dropped the proprietary numbers
-- in May 2019, in a private unreleased version of LLC/Smithing version 2.71.
-- But there's no new smithing or llc version number to use to see if this LLC
-- uses proprietary numbers or not.
--
function Parser.ToDolSetID(set_bonus)

                        -- There is no craftable ESO setId 1, but Dolgubon
                        -- used/uses setId 1 for  Ashen Grip or something. So
                        -- if LLC has an entry for setId 1, we know to use the
                        -- proprietary setIds.
    if WritWorthy.dol_private_set_id == nil then
        local llc = WritWorthyInventoryList:GetLLC()
        if llc then
            local t = llc.GetSetIndexes()
            WritWorthy.dol_private_set_id = t and (t[1] ~= nil)
        end

        if WritWorthy.dol_private_set_id then
            Log.Error("Please update LibLazyCrafting.")
            assert(not WritWorthy.dol_private_set_id, "LibLazyCrafting too old.")
        end
    end

    return set_bonus.set_id
end
