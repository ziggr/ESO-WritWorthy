
local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Define.lua

-- When M.M. doesn't come up with a price for these crafting
-- materials, supply a hardcoded one.

WritWorthy.FALLBACK_PRICE = {

                            -- NPC crafting vendor sells these at 15g each.

                            -- Some trait stones sell for so little that
                            -- some trading guilds won't have any sales
                            -- of these for weeks at a time.

                            -- Most of these prices are PC NA Master Merchant,
                            -- circa 2018-07, rounded to some nearby multiple
                            -- of 5 or 10 or whatever.

                            -- Jewelry fallbacks are either:
                            -- 10x their corresponding blacksmithing material,
                            -- since it takes 10x grains/dust to create one
                            -- refined/trait/improvement material, or for
                            -- jewelry trait stones gated behind PvP or
                            -- other long-duration grinds, 10 * Potent Nirncrux.

    ["ancestor silk"      ] =   40
,   ["rubedo leather"     ] =   15
,   ["rubedite"           ] =   10
,   ["ruby ash"           ] =   20
,   ["platinum"           ] =   20

,   ["hemming"            ] =   15
,   ["embroidery"         ] =   15
,   ["elegant lining"     ] =  125
,   ["dreugh wax"         ] = 4000

,   ["honing stone"       ] =   20
,   ["dwarven oil"        ] =   35
,   ["grain solvent"      ] =  500
,   ["tempering alloy"    ] = 5000

,   ["pitch"              ] =   50
,   ["turpen"             ] =   25
,   ["mastic"             ] =  500
,   ["rosin"              ] = 2500

,   ["terne"              ] =  1250
,   ["iridium"            ] =  3750
,   ["zircon"             ] = 21000
,   ["chromium"           ] = 73000

,   ["adamantite"         ] =   15
,   ["obsidian"           ] =   15
,   ["bone"               ] =   15
,   ["corundum"           ] =   15
,   ["molybdenum"         ] =   15
,   ["starmetal"          ] =   15
,   ["moonstone"          ] =   15
,   ["manganese"          ] =   15
,   ["flint"              ] =   15
,   ["nickel"             ] =   15
,   ["palladium"          ] =   15
,   ["copper"             ] =   15
,   ["argentum"           ] =   10
,   ["daedra heart"       ] =   15
,   ["dwemer frame"       ] =  300
,   ["malachite"          ] =  175
,   ["charcoal of remorse"] =   75
,   ["goldscale"          ] =  100
,   ["laurel"             ] =   30
,   ["cassiterite"        ] =   40
,   ["auric tusk"         ] =  100
,   ["potash"             ] =  100
,   ["rogue's soot"       ] =   85
,   ["eagle feather"      ] =  150
,   ["lion fang"          ] =  150
,   ["dragon scute"       ] =  150
,   ["azure plasm"        ] =   10
,   ["fine chalk"         ] =   75
,   ["polished shilling"  ] =   75
,   ["tainted blood"      ] =  100
,   ["defiled whiskers"   ] =  150
,   ["black beeswax"      ] =  100
,   ["oxblood fungus"     ] =   50
,   ["pearl sand"         ] =  100
,   ["ferrous salts"      ] =   25
,   ["star sapphire"      ] =   75
,   ["pristine shroud"    ] =   50
,   ["amber marble"       ] =   35
,   ["grinstones"         ] = 3500
,   ["stalhrim shard"     ] = 3000
,   ["wolfsbane incense"  ] =  200
,   ["ancient sandstone"  ] =   25
,   ["leviathan scrimshaw"] =  750
,   ["night pumice"       ] = 2000
,   ["distilled slowsilver"  ] =  150
,   ["ash canvas"            ] =   50
,   ["volcanic viridian"     ] =  250
,   ["lustrous sphalerite"   ] =  175
,   ["boiled carapace"       ] =   50
,   ["polished scarab elytra"] =  300
,   ["refined bonemold resin"] = 5000
,   ["wrought ferrofungus"   ] =  250
,   ["bloodroot flux"        ] =  175
,   ["minotaur bezoar"       ] =   75
,   ["tempered brass"        ] =  400
,   ["tenebrous cord"        ] =  175
,   ["dragon bone"           ] = 1000
,   ["infected flesh"        ] =  750
,   ["culanda lacquer"       ] = 3250
,   ["vitrified malondo"     ] =  600
,   ["sea serpent hide"      ] =  300
,   ["desecrated grave soil" ] =  100
,   ["gryphon plume"         ] = 1000
,   ["warrior's heart ashes" ] =  400

,   ["quartz"             ] =     5
,   ["diamond"            ] =     5
,   ["sardonyx"           ] =     5
,   ["almandine"          ] =     5
,   ["emerald"            ] =    15
,   ["bloodstone"         ] =     5
,   ["garnet"             ] =     5
,   ["sapphire"           ] =     5
,   ["fortified nirncrux" ] =   750
,   ["chysolite"          ] =     5
,   ["amethyst"           ] =     5
,   ["ruby"               ] =     5
,   ["jade"               ] =     5
,   ["turquoise"          ] =     5
,   ["carnelian"          ] =     5
,   ["fire opal"          ] =     5
,   ["citrine"            ] =     5
,   ["potent nirncrux"    ] = 13000
,   ["cobalt"             ] =   450
,   ["antimony"           ] =   300
,   ["zinc"               ] =   350
,   ["dawn-prism"         ] = 20000
,   ["dibellium"          ] = 12000
,   ["gilding wax"        ] = 20000
,   ["aurbic amber"       ] =  8250
,   ["titanium"           ] =  2500
,   ["slaughterstone"     ] =  6500

,   ["blessed thistle"    ] =   200
,   ["blue entoloma"      ] =    35
,   ["bugloss"            ] =   100
,   ["columbine"          ] =   225
,   ["corn flower"        ] =   250
,   ["dragonthorn"        ] =    50
,   ["emetic russula"     ] =    50
,   ["imp stool"          ] =    50
,   ["lady's smock"       ] =   175
,   ["luminous russula"   ] =    50
,   ["mountain flower"    ] =    50
,   ["namira's rot"       ] =   250
,   ["nirnroot"           ] =    50
,   ["stinkhorn"          ] =    50
,   ["violet coprinus"    ] =    75
,   ["water hyacinth"     ] =   100
,   ["white cap"          ] =    35
,   ["wormwood"           ] =    50
,   ["beetle scuttle"     ] =   150
,   ["butterfly wing"     ] =    75
,   ["fleshfly larva"     ] =    25
,   ["mudcrab chitin"     ] =    50
,   ["nightshade"         ] =    75
,   ["scrib jelly"        ] =    65
,   ["spider egg"         ] =    30
,   ["torchbug thorax"    ] =   100

,   ["lorkhan's tears"    ] =    20
,   ["alkahest"           ] =     1
,   ["clear water"        ] =     5

,   ["guts"               ] =    15
,   ["worms"              ] =    25
,   ["crawlers"           ] =     5

,   ["acai berry"         ] =     5
,   ["apples"             ] =     5
,   ["bananas"            ] =     5
,   ["barley"             ] =     5
,   ["beets"              ] =     5
,   ["bervez juice"       ] =    50
,   ["bittergreen"        ] =     5
,   ["carrots"            ] =     5
,   ["cheese"             ] =     5
,   ["coffee"             ] =     5
,   ["comberry"           ] =     5
,   ["corn"               ] =     5
,   ["fish"               ] =     5
,   ["flour"              ] =    25
,   ["frost mirriam"      ] =    75
,   ["game"               ] =     5
,   ["garlic"             ] =     5
,   ["ginger"             ] =     5
,   ["ginkgo"             ] =     5
,   ["ginseng"            ] =     5
,   ["greens"             ] =     5
,   ["guarana"            ] =     5
,   ["honey"              ] =     5
,   ["isinglass"          ] =     5
,   ["jasmine"            ] =     5
,   ["jazbay grapes"      ] =     5
,   ["lemon"              ] =     5
,   ["lotus"              ] =     5
,   ["melon"              ] =     5
,   ["metheglin"          ] =     5
,   ["millet"             ] =     5
,   ["mint"               ] =     5
,   ["perfect roe"        ] = 10000
,   ["potato"             ] =     5
,   ["poultry"            ] =     5
,   ["pumpkin"            ] =     5
,   ["radish"             ] =     5
,   ["red meat"           ] =     5
,   ["rice"               ] =     5
,   ["rose"               ] =     5
,   ["rye"                ] =     5
,   ["saltrice"           ] =     5
,   ["seasoning"          ] =     5
,   ["seaweed"            ] =     5
,   ["small game"         ] =    30
,   ["surilie grapes"     ] =     5
,   ["tomato"             ] =     5
,   ["wheat"              ] =     5
,   ["white meat"         ] =    25
,   ["yeast"              ] =     5
,   ["yerba mate"         ] =     5

,   ["rejera"             ] =    10
,   ["repora"             ] =   160
,   ["jehade"             ] =     9
,   ["itade"              ] =    30

,   ["dekeipa"            ] =     5
,   ["deni"               ] =     5
,   ["denima"             ] =     5
,   ["deteri"             ] =    15
,   ["haoko"              ] =    10
,   ["hakeijo"            ] = 11000
,   ["kaderi"             ] =     5
,   ["kuoko"              ] =     5
,   ["makderi"            ] =    30
,   ["makko"              ] =     5
,   ["makkoma"            ] =     5
,   ["meip"               ] =     5
,   ["oko"                ] =    44
,   ["okoma"              ] =     5
,   ["okori"              ] =    15
,   ["oru"                ] =     5
,   ["rakeipa"            ] =   175
,   ["taderi"             ] =    25
,   ["rekuta"             ] =    50
,   ["kuta"               ] =  2250
}


-- The above table initially has keys for our internal material names, not
-- item IDs. Add item_id keys so that we can look things up by (disassembled)
-- item_links, matching MMPrice() API as well as the links that the ZOS recipe
-- ingredient API returns.
--
-- Do NOT use item_link as a key: the ZOS recipe ingredient API will return
-- links with slightly varying digits in insignificant positions that will
-- will cause lookup failures.
--
function WritWorthy.PopulateTableWithItemIds()
    if WritWorthy.FALLBACK_PRICE.filled_with_item_id_goodness then return end
    local name_list = {}
                        -- Do this in two passes because I'm not sure how
                        -- Lua handles "modifying a table while you're
                        -- iterating over it."
    for name, _ in pairs(WritWorthy.FALLBACK_PRICE) do
        table.insert(name_list, name)
    end
    for _, name in ipairs(name_list) do
        local link  = WritWorthy.FindLink(name)
        local w     = WritWorthy.Util.ToWritFields(link)
        WritWorthy.FALLBACK_PRICE[w.item_id] = WritWorthy.FALLBACK_PRICE[name]
    end
    WritWorthy.FALLBACK_PRICE.filled_with_item_id_goodness = true
end

-- If the material is in the FALLBACK_PRICE table, return its fallback price.
-- If not, return nil.
function WritWorthy.FallbackPrice(link)
    local w     = WritWorthy.Util.ToWritFields(link)
    if not WritWorthy.FALLBACK_PRICE[w.item_id] then
        WritWorthy.PopulateTableWithItemIds()
    end
-- d("fallback:"..tostring(WritWorthy.FALLBACK_PRICE[w.item_id])
--    .." item_id:"..tostring(w.item_id).." link:"..tostring(link))
    return WritWorthy.FALLBACK_PRICE[w.item_id]
end
