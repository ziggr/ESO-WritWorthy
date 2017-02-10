function Fail(msg)
    print(msg)
end

-- SmithItem =================================================================
--
-- A single blacksmithing, clothing, or woodworking crafted item, required
-- for a Master Writ.
local SmithItem = {}


-- The four crafting schools (clothing counts as two: light and medium)
SmithItem.HEAVY = { base_mat_link    = "[Rubedite Ingot]"
                  , green_mat_link   = "[Honing Stone]"
                  , blue_mat_link    = "[Dwarven Oil]"
                  , purple_mat_link  = "[Grain Solvent]"
                  , gold_mat_link    = "[Tempering Alloy]"
                  }

SmithItem.MEDIUM = { base_mat_link   = "[Rubedo Leather]"
                   , green_mat_link  = "[Hemming]"
                   , blue_mat_link   = "[Embroidery]"
                   , purple_mat_link = "[Elegant Lining]"
                   , gold_mat_link   = "[Dreugh Wax]"
                   }

SmithItem.LIGHT  = { base_mat_link   = "[Ancestor Silk]"
                   , green_mat_link  = "[Hemming]"
                   , blue_mat_link   = "[Embroidery]"
                   , purple_mat_link = "[Elegant Lining]"
                   , gold_mat_link   = "[Dreugh Wax]"
                   }

SmithItem.WOOD   = { base_mat_link   = "[Sanded Ruby Ash]"
                   , green_mat_link  = "[Pitch]"
                   , blue_mat_link   = "[Turpen]"
                   , purple_mat_link = "[Mastic]"
                   , gold_mat_link   = "[Rosin]"
                   }

SmithItem.TRAITS_WEAPON = {
    ["Powered"]         = "[chysolite]"
,   ["Charged"]         = "[amethyst]"
,   ["Precise"]         = "[ruby]"
,   ["Infused"]         = "[jade]"
,   ["Defending"]       = "[turquoise]"
,   ["Training"]        = "[carnelian]"
,   ["Sharpened"]       = "[fire opal]"
,   ["Decisive"]        = "[citrine]"
,   ["Nirnhoned"]       = "[potent nirncrux]"
}

SmithItem.ARMOR    = {
    ["Sturdy"]          = "[quartz]"
,   ["Impenetrable"]    = "[diamond]"
,   ["Reinforced"]      = "[sardonyx]"
,   ["Well-fitted"]     = "[almandine]"
,   ["Training"]        = "[emerald]"
,   ["Infused"]         = "[bloodstone]"
,   ["Prosperous"]      = "[garnet]"
,   ["Divines"]         = "[sapphire]"
,   ["Nirnhoned"]       = "[fortified nirncrux]"
}

SmithItem.MOTIF = {
    ["Altmer"]                  = "[adamantite]"
,   ["Dunmer"]                  = "[obsidian]"
,   ["Bosmer"]                  = "[bone]"
,   ["Nord"]                    = "[corundum]"
,   ["Breton"]                  = "[molybdenum]"
,   ["Redguard"]                = "[starmetal]"
,   ["Khajiit"]                 = "[moonstone]"
,   ["Orc"]                     = "[manganese]"
,   ["Argonian"]                = "[flint]"
,   ["Imperial"]                = "[nickel]"
,   ["Ancient Elf"]             = "[palladium]"
,   ["Barbarian"]               = "[copper]"
,   ["Primal"]                  = "[argentum]"
,   ["Daedric"]                 = "[daedra heart]"
,   ["Dwemer"]                  = "[dwemer frame]"
,   ["Glass"]                   = "[malachite]"
,   ["Xivkyn"]                  = "[charcoal of remorse]"
,   ["Akaviri"]                 = "[goldscale]"
,   ["Mercenary"]               = "[laurel]"
,   ["Ancient Orc"]             = "[cassiterite]"
,   ["Trinimac"]                = "[auric tusk]"
,   ["Malacath"]                = "[potash]"
,   ["Outlaw"]                  = "[rogue's soot]"
,   ["Aldmeri Dominion"]        = "[eagle feather]"
,   ["Daggerfall Covenant"]     = "[lion fang]"
,   ["Ebonheart Pact"]          = "[dragon scute]"
,   ["Soul-shriven"]            = "[azure plasm]"
,   ["Abah's Watch"]            = "[polished shilling]"
,   ["Thieves Guild"]           = "[fine chalk]"
,   ["Assassins League"]        = "[tainted blood]"
,   ["Dro-m'athra"]             = "[defiled whiskers]"
,   ["Dark Brotherhood"]        = "[black beeswax]"
,   ["Minotaur"]                = "[oxblood fungus]"
,   ["Order of the Hour"]       = "[pearl sand]"
,   ["Yokudan"]                 = "[ferrous salts]"
,   ["Celestial"]               = "[star sapphire]"
,   ["Draugr"]                  = "[pristine shroud]"
,   ["Hollowjack"]              = "[amber marble]"
,   ["Grim Harlequin"]          = "[grinstones]"
,   ["Stahlrim Frostcaster"]    = "[stahlrim shard]"
,   ["Skinchanger"]             = "[wolfsbane incense]"
}


-- Material requirements for each possitble Master Write BS/CL/WW item.
                        -- abbreviations to make the table more concise.
local HVY = SmithItem.HEAVY
local MED = SmithItem.MEDIUM
local LGT = SmithItem.LGT
local WW  = SmithItem.WW
local WEAPON = SmithItem.TRAITS_WEAPON
local ARMOR  = SmithItem.ARMOR

SmithItem.ITEM_BASE = {
    { name = "Rubedite Sword", school = HVY, base_mat_ct = 11, trait_set = WEAPON}
,   { name = "Rubedite Helm" , school = HVY, base_mat_ct = 12, trait_set = ARMOR }
}

-- Material counts for improving to purple or gold.
SmithItem.PURPLE = { green_mat_ct   = 2
                   , blue_mat_ct    = 3
                   , purple_mat_ct  = 4
                   , gold_mat_ct    = 0
                   }

SmithItem.GOLD   = { green_mat_ct   = 2
                   , blue_mat_ct    = 3
                   , purple_mat_ct  = 4
                   , gold_mat_ct    = 8
                   }


function SmithItem:New()
    local o = {
        base_text       = nil   -- "Consume to start quest"
                                -- "\nCraft a Rubedite Sword;"
                                -- " Quality: Legendary;"
                                -- " Trait: Defending;"
                                -- " Set: Way of the Arena;"
                                -- " Style: Primal"
    ,   reward_text     = nil   -- "Reward 92 (icon) Writ Vouchers"

    ,   item_base       = nil   -- SmithItem.ITEM_BASE[x]
    ,   base_mat_mm     = nil   -- 13.42315

    ,   trait_mat_link  = nil   -- [Turquoise]
    ,   trait_mat_mm    = nil   -- 0.1315

    ,   motif_mat_link  = nil   -- [Argentum]
    ,   motif_mat_mm    = nil   -- 13.1551

    ,   improve_level   = nil   -- PURPLE, GOLD
    ,   voucher_ct      = nil   -- 92
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function SmithItem:ParseBaseText(base_text)
    self.base_text = base_text

    -- "Rubedite Sword" ==> blacksmithing, 11 Rubedite Ingot
    for _, item_base in ipairs(SmithItem.ITEM_BASE) do
        if base_text:find(item_base.name) then
            self.item_base     = item_base
            break
        end
    end
    if not self.item_base then return Fail("base not found") end

    -- "Trait: Defending" ==> [Turquoise]
    for trait_name, trait_mat_link in pairs(self.item_base.trait_set) do
        if base_text:find("Trait: "..trait_name) then
            self.trait_mat_link = trait_mat_link
            break
        end
    end
    if not self.trait_mat_link then return Fail("trait not found") end

    -- "Style: Primal" ==> [Argentum]
    for motif_name, motif_mat_link in pairs(SmithItem.MOTIF) do
        if base_text:find("Style: "..motif_name) then
            self.motif_mat_link = motif_mat_link
            break
        end
    end
    if not self.motif_mat_link then return Fail("motif not found") end
end

function SmithItem:ParseRewardText(reward_text)
    self.reward_text = reward_text
    local _,_,s = reward_text:find("Reward: (%d+)")
    if s then
        self.voucher_ct = tonumber(s)
    end
    if not self.voucher_ct then return Fail("voucher ct not found") end
end



base_text       =    "Consume to start quest"
                  .. "\nCraft a Rubedite Sword;"
                  .. " Quality: Legendary;"
                  .. " Trait: Defending;"
                  .. " Set: Way of the Arena;"
                  .. " Style: Primal"
reward_text     =    "Reward: 92 (icon) Writ Vouchers"

si = SmithItem:New()
si:ParseBaseText(base_text)
si:ParseRewardText(reward_text)
