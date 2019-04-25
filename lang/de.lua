local WW = WritWorthy or {}

WW.STR_L10N = {
  ["empty"                      ] = ""

-- "lam" is "LibAddonMenu", the settings pane that appears
-- Settings > Addons > WritWorthy

, ["lam_mat_price_tt_title"     ] = "Materialpreis in Tooltip anzeigen"
, ["lam_mat_price_tt_desc"      ] = "Fügen Sie den Text in die QuickInfo ein,"
                                    .." wobei die Kosten für alle Materialien"
                                    .." in Rechnung gestellt werden, die für"
                                    .." die Erstellung dieses Dokuments"
                                    .." erforderlich sind."

, ["lam_mat_list_title"         ] = "Materialliste im Chat anzeigen"
, ["lam_mat_list_desc"          ] = "Schreiben Sie jedes Mal mehrere Zeilen"
                                    .." für den Chat, wenn ein Tool-Tipp für"
                                    .." Master Writ angezeigt wird."
, ["lam_mat_list_off"           ] = "Aus"
, ["lam_mat_list_all"           ] = "Alles"
, ["lam_mat_list_alchemy_only"  ] = "nur Alchemie"

, ["lam_mm_fallback_title"      ] = "Preise Zurückfallen"
, ["lam_mm_fallback_desc"       ] = "Wenn MM, ATT und TTC für einige"
                                    .." Materialien kein durchschnittlicher"
                                    .." Preis vorliegt, verwenden Sie interne,"
                                    .." fest codierte Preise."

, ["lam_station_colors_title"   ] = "Stationsfarben im Fenster"
, ["lam_station_colors_desc"    ] = "Verwenden Sie verschiedene Farben für"
                                    .." Schmiedekunst, Kleidung und"
                                    .." Holzbearbeitung im WritWorthy-Fenster."

, ["lam_banked_vouchers_title"  ] = "Schreibe Schreibvorgänge von Bank in das WritWorthy-Fenster"
, ["lam_banked_vouchers_desc"   ] = "Scannen Sie die Bank und fügen Sie diese"
                                    .." Schreibvorgänge in die Liste der"
                                    .." verfügbaren Schreibvorgänge ein, die"
                                    .." automatisch erstellt werden können."
                                    .."\n|cFF3333ACHTUNG Wenn du mehrere"
                                    .." Charaktere bastelst! WritWorthy warnt"
                                    .." Sie nicht, wenn Sie für mehrere"
                                    .." Zeichen dieselbe Schreibschrift"
                                    .." verwenden.|r"

, ["slash_writworthy_desc"      ] = "WritWorthy-Fenster ein- / ausblenden"
-- , ["slash_discover"             ] = "discover"
-- , ["slash_discover_desc"        ] = "Dump item_link writ fields to tables in log"
, ["slash_forget"               ] = "vergessen"
, ["slash_forget_desc"          ] = "Vergessen die handwerklichen Meisterschreiben dieses Charakters"
, ["slash_count"                ] = "wieviele"
, ["slash_count_desc"           ] = "Wie viele Meisterschreib das Inventar / die Bank dieses Charakters?"
-- , ["slash_auto"                 ] = "auto"
-- , ["slash_auto_desc"            ] = "Automatically accept quests from inventory."

-- , ["status_discover"            ] = "scanning writ fields..."
, ["status_forget"              ] = "alles vergessen, was dieser Charakter schon geschaffen hat ..."
, ["count_writs_vouchers"       ] = "%d Schreib, %s Schriebscheine"

, ["err_could_not_parse"        ] = "Konnte nicht analysieren."

-- Tooltip text fragments.
, ["tooltip_mat_total"          ] = "Mat insgesamt"
, ["tooltip_purchase"           ] = "Kauf"
, ["tooltip_per_voucher"        ] = "Per Schriebscheine"

, ["tooltip_sell_for"           ] = "Verkaufen für %s g"
, ["tooltip_sell_for_cannot"    ] = "Kann nicht verkaufen für %s g"

, ["tooltip_queued"             ] = "zum Basteln in die Warteschlange gestellt"
, ["tooltip_crafted"            ] = "fertigung abgeschlossen"

, ["skill_not_maxed"            ] = "Unzureichende Fähigkeit '%s': %d/%d"
, ["skill_missing"              ] = "Fehlende Fähigkeit: %s"
, ["motif_not_known"            ] = "Stil %s nicht bekannt"
, ["trait_not_known"            ] = "Eigenschaft %s %s nicht bekannt"
, ["trait_ct_too_low"           ] = "%d/%d Eigenschaften erforderlich für Set %s"
, ["recipe_not_known"           ] = "Rezept nicht bekannt"

, ["currency_suffix_gold"            ] = "g"
, ["currency_suffix_voucher"         ] = "v"
, ["currency_suffix_gold_per_voucher"] = "g/v"

-- WritWorthy main window
    -- Column headers
, ["header_Type"                ] = "Art"
, ["header_V"                   ] = "V"         -- Voucher Count, but only room for 1 character.
, ["header_Detail 1"            ] = "Detail 1"
, ["header_Detail 2"            ] = "Detail 2"
, ["header_Detail 3"            ] = "Detail 3"
, ["header_Detail 4"            ] = "Detail 4"
, ["header_Detail 5"            ] = "Detail 5"
, ["header_Q"                   ] = "Q"         -- Enqueued checkboxes, only room for 1 character.

, ["header_tooltip_Type"        ] = nil
, ["header_tooltip_V"           ] = "Schriebscheinezählung"
, ["header_tooltip_Detail1"     ] = nil
, ["header_tooltip_Detail2"     ] = nil
, ["header_tooltip_Detail3"     ] = nil
, ["header_tooltip_Detail4"     ] = nil
, ["header_tooltip_Detail5"     ] = nil
, ["header_tooltip_Q"           ] = "Zum Basteln in die Warteschlange gestellt"

, ["button_enqueue_all"         ] = "Alles Enqueue"
, ["button_dequeue_all"         ] = "Alles Dequeue"
, ["button_sort_by_station"     ] = "Sortieren nach Station"

, ["title_writ_inventory_player"            ] = "Schrieb Inventar: %s"
, ["title_writ_inventory_player_bank"       ] = "Schrieb Inventar: %s + Bank"

, ["summary_queued_voucher_ct"              ] = "Gesamtschreiben in der Warteschlange"
, ["summary_queued_mat_cost"                ] = "Gesamtmaterial in der Warteschlange"
, ["summary_queued_average_voucher_cost"    ] = "durchschnittliche Voucher-Kosten in der Warteschlange"

, ["summary_completed_voucher_ct"           ] = "Gesamtschreiben abgeschlossen"
, ["summary_completed_mat_cost"             ] = "Gesamtmaterial abgeschlossen"
, ["summary_completed_average_voucher_cost" ] = "durchschnittliche Voucher-Kosten abgeschlossen"

, ["status_list_empty_no_writs"             ] = "Dieser Charakter hat keine versiegelten Hauptschriften in seinem Inventar."

-- Awesome Guild Store integration
, ["ags_label"                   ] = "!WritWorthy Kosten pro Schriebscheine"

-- Enchanting
, ["enchanting_cp150"            ] = "prächtige"
, ["enchanting_cp160"            ] = "wahrlich prächtige"

, ["glyph_magicka"               ] = "Magicka"
, ["glyph_stamina"               ] = "Ausdauer"
, ["glyph_health"                ] = "Lebens"
, ["glyph_prismatic_defense"     ] = "prismatischen Verteidigung"
, ["glyph_flame"                 ] = "flame"
, ["glyph_decrease_health"       ] = "lebensminderung"
, ["glyph_weapon_damage"         ] = "waffenkraft"
, ["glyph_foulness"              ] = "fäulnis"
, ["glyph_poison"                ] = "gifts"
, ["glyph_frost"                 ] = "frosts"
, ["glyph_shock"                 ] = "schocks"
, ["glyph_hardening"             ] = "abhärtung"
, ["glyph_crushing"              ] = "zerschmetterns"
, ["glyph_weakening"             ] = "schwächung"
, ["glyph_absorb_health"         ] = "lebensabsorption"
, ["glyph_absorb_stamina"        ] = "ausdauerabsorption"
, ["glyph_absorb_magicka"        ] = "magickaabsorption"
, ["glyph_prismatic_onslaught"   ] = "prismatischen Ansturms"
, ["glyph_frost_resist"          ] = "frostresistenz"
, ["glyph_stamina_recovery"      ] = "ausdauerregeneration"
, ["glyph_reduce_feat_cost"      ] = "fähigkeitenkostenminderung"
, ["glyph_disease_resist"        ] = "seuchenresistenz"
, ["glyph_bashing"               ] = "einschlagens"
, ["glyph_shielding"             ] = "abschirmens"
, ["glyph_poison_resist"         ] = "giftresistenz"
, ["glyph_increase_magical_harm" ] = "erhöhten magischen schadens"
, ["glyph_decrease_spell_harm"   ] = "verringerten magischen schadens"
, ["glyph_magicka_recovery"      ] = "magickaregeneration"
, ["glyph_reduce_spell_cost"     ] = "zauberkostenminderung"
, ["glyph_shock_resist"          ] = "schockresistenz"
, ["glyph_health_recovery"       ] = "lebensregeneration"
, ["glyph_potion_boost"          ] = "trankverbesserung"
, ["glyph_potion_speed"          ] = "tranktempos"
, ["glyph_flame_resist"          ] = "flammenresistenz"
, ["glyph_increase_physical_harm"] = "erhöhten physischen schadens"
, ["glyph_decrease_physical_harm"] = "verringerten physischen schadens"

}


-- list window, abbreviations/shortenings to keep strings short enough
-- to fit in narrow column widths.
--
-- Long strings on the left will be replaced by strings on the right.
WW.SHORTEN_L10N = {
  ["Rubedite Axe"                   ] = "1h axe"
, ["Rubedite Mace"                  ] = "1h mace"
, ["Rubedite Sword"                 ] = "1h sword"
, ["Rubedite Battle Axe"            ] = "2h battle axe"
, ["Rubedite Greatsword"            ] = "2h greatsword"
, ["Rubedite Maul"                  ] = "2h maul"
, ["Rubedite Dagger"                ] = "dagger"

, ["Rubedite Cuirass"               ] = "cuirass"
, ["Rubedite Sabatons"              ] = "sabatons"
, ["Rubedite Gauntlets"             ] = "gauntlets"
, ["Rubedite Helm"                  ] = "helm"
, ["Rubedite Greaves"               ] = "greaves"
, ["Rubedite Pauldron"              ] = "pauldron"
, ["Rubedite Girdle"                ] = "girdle"

, ["Ancestor Silk Robe"             ] = "robe"
, ["Ancestor Silk Jerkin"           ] = "shirt"
, ["Ancestor Silk Shoes"            ] = "shoes"
, ["Ancestor Silk Gloves"           ] = "gloves"
, ["Ancestor Silk Hat"              ] = "hat"
, ["Ancestor Silk Breeches"         ] = "breeches"
, ["Ancestor Silk Epaulets"         ] = "epaulets"
, ["Ancestor Silk Sash"             ] = "sash"

, ["Rubedo Leather Jack"            ] = "jack"
, ["Rubedo Leather Boots"           ] = "boots"
, ["Rubedo Leather Bracers"         ] = "bracers"
, ["Rubedo Leather Helmet"          ] = "helmet"
, ["Rubedo Leather Guards"          ] = "guards"
, ["Rubedo Leather Arm Cops"        ] = "arm cops"
, ["Rubedo Leather Belt"            ] = "belt"

, ["Ruby Ash Bow"                   ] = "bow"
, ["Ruby Ash Inferno Staff"         ] = "flame"
, ["Ruby Ash Ice Staff"             ] = "frost"
, ["Ruby Ash Lightning Staff"       ] = "lightning"
, ["Ruby Ash Restoration Staff"     ] = "resto"
, ["Ruby Ash Shield"                ] = "shield"

, ["Whitestrake's Retribution"      ] = "Whitestrake's"
, ["Armor of the Seducer"           ] = "Seducer"
, ["Night Mother's Gaze"            ] = "Night Mother's"
, ["Alessia's Bulwark"              ] = "Alessia's"
, ["Pelinal's Aptitude"             ] = "Pelinal's"

}

