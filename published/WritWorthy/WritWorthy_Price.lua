
local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Define.lua

-- When M.M. doesn't come up with a price for these crafting
-- materials, supply a hardcoded one.

WritWorthy.FALLBACK_PRICE = {

                            -- NPC crafting vendor sells these at 15g each.
    ["adamantite"         ] = 15
,   ["obsidian"           ] = 15
,   ["bone"               ] = 15
,   ["corundum"           ] = 15
,   ["molybdenum"         ] = 15
,   ["starmetal"          ] = 15
,   ["moonstone"          ] = 15
,   ["manganese"          ] = 15
,   ["flint"              ] = 15
,   ["nickel"             ] = 15

                            -- Some trait stones sell for so little that
                            -- some trading guilds won't have any sales
                            -- of these for weeks at a time.
,   ["quartz"             ] = 5
,   ["diamond"            ] = 5
,   ["sardonyx"           ] = 5
,   ["almandine"          ] = 5
,   ["emerald"            ] = 5      -- training armor, oftem more like 75g.
,   ["bloodstone"         ] = 5
,   ["garnet"             ] = 5
,   ["sapphire"           ] = 5      -- divines, often more like 25g.
--  ["fortified nirncrux" ] = 3100   -- nirnhoned armor
,   ["chysolite"          ] = 5
,   ["amethyst"           ] = 5
,   ["ruby"               ] = 5      -- precise, often more like 25g.
,   ["jade"               ] = 5
,   ["turquoise"          ] = 5
,   ["carnelian"          ] = 5      -- training weapon, more like 35g.
,   ["fire opal"          ] = 5      -- sharpened, more like 35b
,   ["citrine"            ] = 5      -- decisive
--  ["potent nirncrux"    ] = 10500  -- nirnhoned weapon

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
    return WritWorthy.FALLBACK_PRICE[link]
end
