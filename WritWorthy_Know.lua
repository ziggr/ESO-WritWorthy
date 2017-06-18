
local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Define.lua

WritWorthy.Know = {}
local Know = WritWorthy.Know
local Log  = WritWorthy.Log


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
