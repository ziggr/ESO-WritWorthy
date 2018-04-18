
local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Define.lua

-- When M.M. doesn't come up with a price for these crafting
-- materials, supply a hardcoded one.

WritWorthy.FALLBACK_PRICE = {

                            -- NPC crafting vendor sells these at 15g each.

                            -- Some trait stones sell for so little that
                            -- some trading guilds won't have any sales
                            -- of these for weeks at a time.

                            -- Most of these prices are PC NA Master Merchant,
                            -- circa 2018-04, rounded to some nearby multiple
                            -- of 5 or 10 or whatever.

                            -- Jewelry fallbacks are either:
                            -- 10x their corresponding blacksmithing material,
                            -- since it takes 10x grains/dust to create one
                            -- refined/trait/improvement material, or for
                            -- jewelry trait stones gated behind PvP or
                            -- other long-duration grinds, 10 * Potent Nirncrux.

    ["ancestor silk"      ] =   50
,   ["rubedo leather"     ] =   20
,   ["rubedite"           ] =   10
,   ["ruby ash"           ] =   20
,   ["platinum"           ] =   10 * 10

,   ["hemming"            ] =   20
,   ["embroidery"         ] =   20
,   ["elegant lining"     ] =  125
,   ["dreugh wax"         ] = 4000

,   ["honing stone"       ] =   25
,   ["dwarven oil"        ] =   35
,   ["grain solvent"      ] =  550
,   ["tempering alloy"    ] = 6750

,   ["pitch"              ] =   75
,   ["turpen"             ] =   25
,   ["mastic"             ] =  550
,   ["rosin"              ] = 2750

,   ["terne"              ] =   25 * 10
,   ["iridium"            ] =   35 * 10
,   ["zircon"             ] =  550 * 10
,   ["chromium"           ] = 6750 * 10

,   ["adamantite"         ] =   15
,   ["obsidian"           ] =   15
,   ["bone"               ] =   15
,   ["corundum"           ] =   15
,   ["molybdenum"         ] =   15
,   ["starmetal"          ] =   15
,   ["moonstone"          ] =   15
,   ["manganese"          ] =   15
,   ["flint"              ] =   15
,   ["nickel"             ] =   25
,   ["palladium"          ] =   25
,   ["copper"             ] =   15
,   ["argentum"           ] =   10
,   ["daedra heart"       ] =   25
,   ["dwemer frame"       ] =  550
,   ["malachite"          ] =  275
,   ["charcoal of remorse"] =  100
,   ["goldscale"          ] =  150
,   ["laurel"             ] =   50
,   ["cassiterite"        ] =   50
,   ["auric tusk"         ] =  150
,   ["potash"             ] =  125
,   ["rogue's soot"       ] =  175
,   ["eagle feather"      ] =  225
,   ["lion fang"          ] =  375
,   ["dragon scute"       ] =  350
,   ["azure plasm"        ] =   10
,   ["fine chalk"         ] =  100
,   ["polished shilling"  ] =   30
,   ["tainted blood"      ] =  150
,   ["defiled whiskers"   ] =  150
,   ["black beeswax"      ] =  150
,   ["oxblood fungus"     ] =  100
,   ["pearl sand"         ] =  100
,   ["ferrous salts"      ] =   50
,   ["star sapphire"      ] =  100
,   ["pristine shroud"    ] =   75
,   ["amber marble"       ] =   35
,   ["grinstones"         ] = 2500
,   ["stalhrim shard"     ] = 2500
,   ["wolfsbane incense"  ] =  175
,   ["ancient sandstone"  ] =   25
,   ["leviathan scrimshaw"] = 1275
,   ["night pumice"       ] = 1600
,   ["distilled slowsilver"  ] =  200
,   ["ash canvas"            ] =   50
,   ["volcanic viridian"     ] =  450
,   ["lustrous sphalerite"   ] =  475
,   ["boiled carapace"       ] =  100
,   ["polished scarab elytra"] =  300
,   ["refined bonemold resin"] = 2500
,   ["wrought ferrofungus"   ] =  400
,   ["bloodroot flux"        ] =  225
,   ["minotaur bezoar"       ] =  325
,   ["tempered brass"        ] =  750
,   ["tenebrous cord"        ] =  325

,   ["quartz"             ] =     5
,   ["diamond"            ] =     5
,   ["sardonyx"           ] =     5
,   ["almandine"          ] =     5
,   ["emerald"            ] =    30
,   ["bloodstone"         ] =     5
,   ["garnet"             ] =     5
,   ["sapphire"           ] =     5
,   ["fortified nirncrux" ] =  1000
,   ["chysolite"          ] =     5
,   ["amethyst"           ] =     5
,   ["ruby"               ] =     5
,   ["jade"               ] =     5
,   ["turquoise"          ] =     5
,   ["carnelian"          ] =     5
,   ["fire opal"          ] =     5
,   ["citrine"            ] =     5
,   ["potent nirncrux"    ] = 14000
,   ["cobalt"             ] =     5
,   ["antimony"           ] =     5
,   ["zinc"               ] =     5
,   ["dawn-prism"         ] = 14000 * 10
,   ["dibellium"          ] = 14000 * 10
,   ["gilding wax"        ] = 14000 * 10
,   ["aurbic amber"       ] = 14000 * 10
,   ["titanium"           ] = 14000 * 10
,   ["slaughterstone"     ] = 14000 * 10

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
,   ["worms"              ] =    15
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
,   ["hakeijo"            ] = 11600
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
,   ["kuta"               ] =  2750
}

-- The above table uses our internal material names, not item links.
-- Material names are easier to read and debug. But Util.MMPrice()
-- uses item links.  So fill the above table with links, too.
function WritWorthy.PopulateTableWithLinks()
    if WritWorthy.FALLBACK_PRICE.filled_with_linky_goodness then return end
    local name_list = {}
                        -- Do this in two passes because I'm not sure how
                        -- Lua handles "modifying a table while you're
                        -- iterating over it."
    for name, _ in pairs(WritWorthy.FALLBACK_PRICE) do
        table.insert(name_list, name)
    end
    for _, name in pairs(name_list) do
        local link  = WritWorthy.FindLink(name)
        WritWorthy.FALLBACK_PRICE[link] = WritWorthy.FALLBACK_PRICE[name]
    end
    WritWorthy.FALLBACK_PRICE.filled_with_linky_goodness = true
end

-- If the material is in the FALLBACK_PRICE table, return its fallback price.
-- If not, return nil.
function WritWorthy.FallbackPrice(link)
    if not WritWorthy.FALLBACK_PRICE[link] then
        WritWorthy.PopulateTableWithLinks()
    end
d("fallback:"..tostring(WritWorthy.FALLBACK_PRICE[link]).." link:"..tostring(link))
    return WritWorthy.FALLBACK_PRICE[link]
end
