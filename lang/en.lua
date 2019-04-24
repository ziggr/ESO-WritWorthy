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

, ["currency_suffix_gold"       ] = "g"

}
