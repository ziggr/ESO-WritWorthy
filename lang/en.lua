local WW = WritWorthy or {}

WW.STR = {
  ["empty"                      ] = ""

-- "lam" is "LibAddonMenu", the settings pane that appears
-- Settings > Addons > WritWorthy

, ["lam_mat_price_tt_title"     ] = "Show material price in tooltip"
, ["lam_mat_price_tt_desc"      ] = "Insert text into tooltip with the cost of all the"
                                    .." materials that crafting this writ would consume."

, ["lam_mat_list_title"         ] = "Show material list in chat"
, ["lam_mat_list_desc"          ] = "Write several lines of materials to chat each"
                                    .." time a Master Writ tooltip appears."
, ["lam_mat_list_off"           ] = "Off"
, ["lam_mat_list_all"           ] = "All"
, ["lam_mat_list_alchemy_only"  ] = "Alchemy Only"

, ["lam_mm_fallback_title"      ] = "M.M. Fallback: hardcoded prices if no M.M. data"
, ["lam_mm_fallback_desc"       ] = "If M.M. has no price average for some materials:"
                                    .."\n* use 15g for basic style materials such as Molybdenum"
                                    .."\n* use 5g for common trait materials such as Quartz."

, ["lam_station_colors_title"   ] = "Station colors in window"
, ["lam_station_colors_desc"    ] = "Use different colors for blacksmithing, clothing, and"
                                    .." woodworking items in the WritWorthy window."

, ["lam_banked_vouchers_title"  ] = "Include writs from bank in auto-crafting window"
, ["lam_banked_vouchers_desc"   ] = "Scan bank and include those writs in the list of"
                                    .." writs available to automatically craft."
                                    .."\n|cFF3333BE CAREFUL if you craft on multiple"
                                    .." characters! WritWorthy will not warn you if you"
                                    .." craft the same banked writ on multiple"
                                    .." characters.|r"

, ["slash_writworthy_desc"      ] = "Show/hide WritWorthy window"
, ["slash_discover"             ] = "discover"
, ["slash_discover_desc"        ] = "Dump item_link writ fields to tables in log"
, ["slash_forget"               ] = "forget"
, ["slash_forget_desc"          ] = "Forget this character's crafted master writs"
, ["slash_count"                ] = "count"
, ["slash_count_desc"           ] = "How many master writs in this character's inventory/bank?"
, ["slash_auto"                 ] = "auto"
, ["slash_auto_desc"            ] = "Automatically accept quests from inventory."

, ["status_discover"            ] = "scanning writ fields..."
, ["status_forget"              ] = "forgetting everything this character already crafted..."
, ["count_writs_vouchers"       ] = "%d writs, %s vouchers"

, ["err_could_not_parse"        ] = "Could not parse."

-- Tooltip text fragments.
, ["tooltip_mat_total"          ] = "Mat total"
, ["tooltip_purchase"           ] = "Purchase"
, ["tooltip_per_voucher"        ] = "Per voucher"

, ["tooltip_sell_for"           ] = "Sell for %s g"
, ["tooltip_sell_for_cannot"    ] = "Cannot sell for %s g"

, ["tooltip_queued"             ] = "queued for crafting"
, ["tooltip_crafted"            ] = "crafting completed"

, ["skill_not_maxed"            ] = "!Insufficient skill '%s': %d/%d"
, ["skill_missing"              ] = "!Missing skill: %s"
, ["motif_not_known"            ] = "!Motif %s not known"
, ["trait_not_known"            ] = "!Trait %s %s not known"
, ["trait_ct_too_low"           ] = "!%d of %d traits required for set %s"
, ["recipe_not_known"           ] = "!Recipe not known"

, ["currency_suffix_gold"            ] = "g"
, ["currency_suffix_voucher"         ] = "v"
, ["currency_suffix_gold_per_voucher"] = "g/v"

-- WritWorthy main window
    -- Column headers
, ["header_Type"                ] = "Type"
, ["header_V"                   ] = "V"         -- Voucher Count, but only room for 1 character.
, ["header_Detail 1"            ] = "Detail 1"
, ["header_Detail 2"            ] = "Detail 2"
, ["header_Detail 3"            ] = "Detail 3"
, ["header_Detail 4"            ] = "Detail 4"
, ["header_Detail 5"            ] = "Detail 5"
, ["header_Q"                   ] = "Q"         -- Enqueued checkboxes, only room for 1 character.

, ["header_tooltip_Type"        ] = nil
, ["header_tooltip_V"           ] = "Voucher count"
, ["header_tooltip_Detail1"     ] = nil
, ["header_tooltip_Detail2"     ] = nil
, ["header_tooltip_Detail3"     ] = nil
, ["header_tooltip_Detail4"     ] = nil
, ["header_tooltip_Detail5"     ] = nil
, ["header_tooltip_Q"           ] = "Enqueued for crafting"

, ["button_enqueue_all"         ] = "Enqueue All"
, ["button_dequeue_all"         ] = "Dequeue All"
, ["button_sort_by_station"     ] = "Sort by Station"

, ["title_writ_inventory_player"            ] = "Writ Inventory: %s"
, ["title_writ_inventory_player_bank"       ] = "Writ Inventory: %s + bank"

, ["summary_queued_voucher_ct"              ] = "total vouchers queued"
, ["summary_queued_mat_cost"                ] = "total materials queued"
, ["summary_queued_average_voucher_cost"    ] = "average queued voucher cost"

, ["summary_completed_voucher_ct"           ] = "total vouchers completed"
, ["summary_completed_mat_cost"             ] = "total materials completed"
, ["summary_completed_average_voucher_cost" ] = "average completed voucher cost"

, ["status_list_empty_no_writs"             ] = "This character has no sealed master writs in its inventory."

-- Awesome Guild Store integration
, ["ags_label"                   ] = "!WritWorthy cost per voucher"

-- Enchanting
, ["enchanting_cp150"            ] = "Superb"
, ["enchanting_cp160"            ] = "Truly Superb"

, ["glyph_magicka"               ] = "Magicka"
, ["glyph_stamina"               ] = "Stamina"
, ["glyph_health"                ] = "Health"
, ["glyph_prismatic_defense"     ] = "Prismatic Defense"
, ["glyph_flame"                 ] = "Flame"
, ["glyph_decrease_health"       ] = "Decrease Health"
, ["glyph_weapon_damage"         ] = "Weapon Damage"
, ["glyph_foulness"              ] = "Foulness"
, ["glyph_poison"                ] = "Poison"
, ["glyph_frost"                 ] = "Frost"
, ["glyph_shock"                 ] = "Shock"
, ["glyph_hardening"             ] = "Hardening"
, ["glyph_crushing"              ] = "Crushing"
, ["glyph_weakening"             ] = "Weakening"
, ["glyph_absorb_health"         ] = "Absorb Health"
, ["glyph_absorb_stamina"        ] = "Absorb Stamina"
, ["glyph_absorb_magicka"        ] = "Absorb Magicka"
, ["glyph_prismatic_onslaught"   ] = "Prismatic Onslaught"
, ["glyph_frost_resist"          ] = "Frost Resist"
, ["glyph_stamina_recovery"      ] = "Stamina Recovery"
, ["glyph_reduce_feat_cost"      ] = "Reduce Feat Cost"
, ["glyph_disease_resist"        ] = "Disease Resist"
, ["glyph_bashing"               ] = "Bashing"
, ["glyph_shielding"             ] = "Shielding"
, ["glyph_poison_resist"         ] = "Poison Resist"
, ["glyph_increase_magical_harm" ] = "Increase Magical Harm"
, ["glyph_decrease_spell_harm"   ] = "Decrease Spell Harm"
, ["glyph_magicka_recovery"      ] = "Magicka Recovery"
, ["glyph_reduce_spell_cost"     ] = "Reduce Spell Cost"
, ["glyph_shock_resist"          ] = "Shock Resist"
, ["glyph_health_recovery"       ] = "Health Recovery"
, ["glyph_potion_boost"          ] = "Potion Boost"
, ["glyph_potion_speed"          ] = "Potion Speed"
, ["glyph_flame_resist"          ] = "Flame Resist"
, ["glyph_increase_physical_harm"] = "Increase Physical Harm"
, ["glyph_decrease_physical_harm"] = "Decrease Physical Harm"

}


-- list window, abbreviations/shortenings to keep strings short enough
-- to fit in narrow column widths.
--
-- Keys on the left
WW.SHORTEN = {
-- DO NOT change the              DO CHANGE the
-- keys on the left               strings on the
-- here! These are                right.
-- internal keys, NOT
-- translated.
--
-- DO NOT CHANGE left             DO CHANGE right
--   |  |  |                       |  |  |
--   v  v  v                       v  v  v
--
  ["Alchemy"                  ] = "Alchemy"
, ["Enchanting"               ] = "Enchant"
, ["Provisioning"             ] = "Provis"

-- , ["Rubedite Axe"             ] = "1h axe"
-- , ["Rubedite Mace"            ] = "1h mace"
-- , ["Rubedite Sword"           ] = "1h sword"
-- , ["Rubedite Greataxe"        ] = "2h battle axe"
-- , ["Rubedite Greatsword"      ] = "2h greatsword"
-- , ["Rubedite Maul"            ] = "2h maul"
-- , ["Rubedite Dagger"          ] = "dagger"

-- , ["Rubedite Cuirass"         ] = "cuirass"
-- , ["Rubedite Sabatons"        ] = "sabatons"
-- , ["Rubedite Gauntlets"       ] = "gauntlets"
-- , ["Rubedite Helm"            ] = "helm"
-- , ["Rubedite Greaves"         ] = "greaves"
-- , ["Rubedite Pauldron"        ] = "pauldron"
-- , ["Rubedite Girdle"          ] = "girdle"

-- , ["Ancestor Silk Robe"       ] = "robe"
-- , ["Ancestor Silk Jerkin"     ] = "shirt"
-- , ["Ancestor Silk Shoes"      ] = "shoes"
-- , ["Ancestor Silk Gloves"     ] = "gloves"
-- , ["Ancestor Silk Hat"        ] = "hat"
-- , ["Ancestor Silk Breeches"   ] = "breeches"
-- , ["Ancestor Silk Epaulets"   ] = "epaulets"
-- , ["Ancestor Silk Sash"       ] = "sash"

-- , ["Rubedo Leather Jack"      ] = "jack"
-- , ["Rubedo Leather Boots"     ] = "boots"
-- , ["Rubedo Leather Bracers"   ] = "bracers"
-- , ["Rubedo Leather Helmet"    ] = "helmet"
-- , ["Rubedo Leather Guards"    ] = "guards"
-- , ["Rubedo Leather Arm Cops"  ] = "arm cops"
-- , ["Rubedo Leather Belt"      ] = "belt"

-- , ["Ruby Ash Bow"             ] = "bow"
-- , ["Ruby Ash Inferno Staff"   ] = "flame"
-- , ["Ruby Ash Frost Staff"     ] = "frost"
-- , ["Ruby Ash Lightning Staff" ] = "lightning"
-- , ["Ruby Ash Healing Staff"   ] = "resto"
-- , ["Ruby Ash Shield"          ] = "shield"

, ["Whitestrake's Retribution"] = "Whitestrake's"
, ["Armor of the Seducer"     ] = "Seducer"
, ["Night Mother's Gaze"      ] = "Night Mother's"
, ["Alessia's Bulwark"        ] = "Alessia's"
, ["Pelinal's Aptitude"       ] = "Pelinal's"

}

