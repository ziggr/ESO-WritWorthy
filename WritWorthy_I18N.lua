local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Define.lua


-- Values for "how" in WritWorthy.Str()
-- These dictate how to interpret the key and convert that
-- key into a user-visible string.
WritWorthy.STR_HOW = {
                        -- Static strings such as those that appear in
                        -- LibAddOnMenu's controls, in tooltips like
                        --"Motif not known" and so on.
                        --
                        -- Key is a lookup key into
                        -- WritWorthy.I18N.static[lang][key] = "result"
  STATIC    = { name    = "static"
              , dynamic = nil
              }

                        -- Hand-crafted abbreviations for long names.
                        --
                        -- Key is a lookup key into
                        -- WritWorthy.I18N.shorten[lang][key] = "result"
, SHORTEN   = { name    = "shorten"
              , dynamic = nil
              }
                        -- Crafting materials such as Rubedite Ingot
                        -- or Blessed Thistle.
                        --
                        -- key is material's item_id such as
                        -- 64489 for Rubedite Ingot or
                        -- 30157 for Blessed Thistle
, MAT       = { name    = "mat"
              , dynamic = "I18NMatDyn"
              }

                        -- Crafted gear item such as "Rubedite Axe"
                        --
                        -- key is crafted item's example_item_id such as
                        -- 43529 for Rubedite Axe.
, GEAR      = { name    = "gear"
              , dynamic = "I18NGearDyn"
              }

                        -- Set name such as "Alessia's Bullwark"
                        --
                        -- key is set ID such as 82 for Alessia's Bullwark.
, SET       = { name    = "set"
              , dynamic = "I18NSetDyn"
              }

                        -- Motif/style name such as "Dark Elf"
                        --
                        -- key is motif id such as 4 for Dark Elf
, MOTIF     = { name    = "motif"
              , dynamic = "I18NMotifDyn"
              }

                        -- Food/Drink name such as "Orzorga's Red Frothgar"
                        --
                        -- key is fooddrink item id such as 33526 for FIshy Sticks
, FOODDRINK = { name    = "fooddrink"
              , dynamic = "I18NFoodDrinkDyn"
              }

                        -- ESO Client SI_XXX string index.
                        --
                        -- key is a string "SI_XXX" constant such as
                        -- "SI_ARMORTYPE3" for "Heavy".
                        --
                        -- Keep keys as strings so that the en.lua file is
                        -- readable: "SI_ARMORTYPE3" means a lot more to a
                        -- human than "1360".
, CLIENT_SI = { name    = "client_si"
              , dynamic = "I18NClientSIDyn"
              }
}


-- Main entry point for "give me a user-visible string."
--
-- key + how tells us how to get the string.
--
function WritWorthy.Str(key, how)
                        -- how is optional, defaults to STATIC.
    how = how or WritWorthy.STR_HOW.STATIC

    for _,lang in ipairs(WritWorthy.LangList()) do
        local static = WritWorthy.I18N[how.name][lang]
        if static and static[key] then
            return static[key]
        end

        if how.dynamic then
            local dynamic = WritWorthy[how.dynamic](key)
            if dynamic then return dynamic end
        end
    end
end

function WritWorthy.FoodDrink(key)
    return WritWorthy.Str(key, WritWorthy.STR_HOW.FOODDRINK)
end

function WritWorthy.Gear(key)
    return WritWorthy.Str(key, WritWorthy.STR_HOW.GEAR)
end

function WritWorthy.SetName(key)
    return WritWorthy.Str(key, WritWorthy.STR_HOW.SET)
end

function WritWorthy.Shorten(key)
    return WritWorthy.Str(key, WritWorthy.STR_HOW.SHORTEN)
end

function WritWorthy.SI(key)
    return WritWorthy.Str(key, WritWorthy.STR_HOW.CLIENT_SI)
end

function WritWorthy.Mat(key)
    return WritWorthy.Str(key, WritWorthy.STR_HOW.MAT)
end

function WritWorthy.Motif(key)
    return WritWorthy.Str(key, WritWorthy.STR_HOW.MOTIF)
end

function WritWorthy.LangList()
    if not WritWorthy.lang_list then
        local l = {}

                        -- Prefer forced language code if set in savedVariables,
                        -- or current client language if no forced language.
        table.insert(l, (WritWorthy.savedVariables and WritWorthy.savedVariables.lang)
                        or GetCVar("language.2"))

                        -- Fall back to US English, if not already in
                        -- first/preferred position.
        if l[0] ~= "en" then
            table.insert(l, "en")
        end

                        -- Cache result, unless we were called before
                        -- OnAddOnLoaded() loaded savedVariables: do NOT cache
                        -- results that ignore user prefs in savedVariables.
        if not WritWorthy.savedVariables then
            return l
        end
        WritWorthy.lang_list = l
    end
    return WritWorthy.lang_list
end


function WritWorthy.I18NStatic(key, lang)
    return WritWorthy.I18N["static"][lang] and WritWorthy.I18N["static"][lang][key]
end

-- Dynamic Strings, fetched from current client language ---------------------

function WritWorthy.I18NClientSIDyn(string_index)
    return GetString(_G[string_index])
end

function WritWorthy.I18NFoodDrinkDyn(fooddrink_id)
    local fmt = "|H0:item:%d:1:36:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
    local item_link = string.format(fmt, tonumber(fooddrink_id))
    return zo_strformat("<<t:1>>",GetItemLinkName(item_link))
end

function WritWorthy.I18NGearDyn(example_item_id)
    local fmt = "|H0:item:%d:308:50:0:0:0:0:0:0:0:0:0:0:0:0:2:0:0:0:0:0|h|h"
    local item_link = string.format(fmt, tonumber(example_item_id))
    return zo_strformat("<<t:1>>",GetItemLinkName(item_link))
end

function WritWorthy.I18NMotifDyn(motif_id)
    return zo_strformat("<<1>>",GetItemStyleName(motif_id))
end

function WritWorthy.I18NMatDyn(item_id)
    local fmt = "|H0:item:%d:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
    local item_link = string.format(fmt, tonumber(item_id))
    return zo_strformat("<<t:1>>",GetItemLinkName(item_link))
end

function WritWorthy.I18NSetDyn(set_id)
    return WritWorthy.LibSets() and WritWorthy.LibSets().GetSetName(set_id)
end

-- Discover ------------------------------------------------------------------
-- How Zig populates lang/en.lua with all those material names and others.
--
-- Fetches dynamic strings from current ESO client langage, and writes them
-- to WritWorthy.savedVariables.I18N in a format suitable for copy-and-paste
-- into lang/xx.lua.
--
function WritWorthy.DiscoverI18N()
    local lang = GetCVar("language.2")

                        -- Start with current strings. This includes
                        -- all the hand-crafted UI strings that do not
                        -- come from the ESO client.
    local r = WritWorthy.I18N or {}
    local rr
    local ct
                        -- Clobber current strings with
                        -- dynamic strings from every dynamic source.

                        -- Client SI string constants
                        -- Use en.lua's keys as iteration range.
                        -- Because this is a circular read+write
                        -- on I18N['client_si'], don't swap in the
                        -- results of this scan until AFTER the scan.
    rr = { [lang] = {} }
    ct = 0
    for k,_ in pairs(WritWorthy.I18N['client_si']['en']) do
        local as_num = _G[k]
        rr[lang][k] = GetString(as_num)
        ct = ct + 1
    end
    r[WritWorthy.STR_HOW.CLIENT_SI.name] = rr
    d(string.format("WritWorthy: discovered string_id:%d", ct))

                        -- Fooddrink names
    local fd = {
        [ 64221] = "Psijic Ambrosia"
    ,   [ 68251] = "Capon Tomato-Beet Casserole"
    ,   [ 68252] = "Jugged Rabbit in Preserves"
    ,   [ 68253] = "Longfin Pasty with Melon Sauce"
    ,   [ 68254] = "Withered Tree Inn Venison Pot Roast"
    ,   [ 68273] = "Senche-Tiger Single Malt"
    ,   [ 68274] = "Velothi View Vintage Malbec"
    ,   [ 68275] = "Orcrest Agony Pale Ale"
    ,   [ 68276] = "Lusty Argonian Maid Mazte"
    ,   [ 71056] = "Orzorga's Red Frothgar"
    ,   [ 71057] = "Orzorga's Tripe Trifle Pocket"
    ,   [ 71058] = "Orzorga's Blood Price Pie"
    ,   [ 71059] = "Orzorga's Smoked Bear Haunch"
    }
   rr = { [lang] = {} }
    ct = 0
    r[WritWorthy.STR_HOW.FOODDRINK.name] = rr
    for fooddrink_item_id,_ in pairs(fd) do
        rr[lang][fooddrink_item_id] = WritWorthy.I18NFoodDrinkDyn(fooddrink_item_id)
        ct = ct + 1
    end
    d(string.format("WritWorthy: discovered fooddrink:%d", ct))

                        -- Gear names
    rr = { [lang] = {} }
    ct = 0
    r[WritWorthy.STR_HOW.GEAR.name] = rr
    for k,req_item in pairs(WritWorthy.Smithing.REQUEST_ITEMS) do
        local item_id = req_item.example_item_id
        rr[lang][item_id] = WritWorthy.I18NGearDyn(item_id)
        ct = ct + 1
    end
    d(string.format("WritWorthy: discovered gear:%d", ct))

                        -- Material names
    rr = { [lang] = {} }
    ct = 0
    r[WritWorthy.STR_HOW.MAT.name] = rr
    for k,item_link in pairs(WritWorthy.LINK) do
        local item_id = GetItemLinkItemId(item_link)
        rr[lang][item_id] = WritWorthy.I18NMatDyn(item_id)
        ct = ct + 1
    end
    d(string.format("WritWorthy: discovered mats:%d", ct))

                        -- Motif names
    rr = { [lang] = {} }
    ct = 0
    r[WritWorthy.STR_HOW.MOTIF.name] = rr
    for motif_id = 1,100 do
        local s = WritWorthy.I18NMotifDyn(motif_id)
        if s and s ~= "" then
            rr[lang][motif_id] = s
            ct = ct + 1
        end
    end
    d(string.format("WritWorthy: discovered motif:%d", ct))

                        -- Set Names
    rr = { [lang] = {} }
    ct = 0
    r[WritWorthy.STR_HOW.SET.name] = rr
    for set_id = 1,1000 do
        local set_info = WritWorthy.LibSets() and WritWorthy.LibSets().GetSetInfo(set_id)
        if set_info and set_info.setTypes and set_info.setTypes.isCrafted then
            rr[lang][set_id] = set_info.names[lang]
            ct = ct + 1
        end
    end
    d(string.format("WritWorthy: discovered set:%d", ct))


                        -- Save results.
    WritWorthy.I18N = r
    WritWorthy.savedVariables.I18N = r
end

