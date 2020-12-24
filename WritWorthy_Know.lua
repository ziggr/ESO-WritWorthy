
local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Define.lua

WritWorthy.Know = {}
local Know = WritWorthy.Know
local Log  = WritWorthy.Log

-- Which knowledge tooltips duplicate information that Marify also shows in
-- Marify's Confirm Master Writ? We'll hide those tooltip lines if the user
-- deselects WW settings checkbox for show_confirm_master_writ_duplicates.
Know.KNOW = {
    MOTIF                = { cmw = true  }
,   RECIPE               = { cmw = true  }
,   TRAIT                = { cmw = true  }
,   TRAIT_CT_FOR_SET     = { cmw = true  }
,   SKILL_COST_REDUCTION = { cmw = false }
,   SKILL_REQUIRED       = { cmw = true  }
,   LIBLAZYCRAFTING      = { cmw = false }
}

-- Know ====================================================================
--
-- One piece of required knowledge such as recipe, trait, trait count.
--
function Know:New(args)
    local o = {
        name      = args.name       -- "recipe"
    ,   is_known  = args.is_known   -- false
    ,   is_warn   = args.is_warn    -- not required, but increases mat cost.
                                    -- WritWorthy will refuse to queue for
                                    -- LibLazyCrafting.

    ,   lack_msg  = args.lack_msg   -- "Recipe not known"
    ,   how       = args.how         -- WW.Know.KNOW.MOTIF
    }
    setmetatable(o, self)
    self.__index = self
    Log:Add("is_known:"..tostring(args.is_known)
            .." name:"..tostring(args.name)
            .." lack_msg:"..tostring(args.lack_msg))
    return o
end

function Know:DebugText()
    return string.format("%s:%s", self.name, tostring(self.is_known))
end

function Know:TooltipText()
    if self.is_known then return nil end
    color = WritWorthy.Util.COLOR_RED
    if self.is_warn then color = WritWorthy.Util.COLOR_ORANGE end
    return WritWorthy.Util.color(color, self.lack_msg)
end
