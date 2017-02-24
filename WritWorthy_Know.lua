
local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Util.lua

WritWorthy.Know = {}
local Know = WritWorthy.Know


-- Know ====================================================================
--
-- One piece of required knowledge such as recipe, trait, trait count.
--
function Know:New(args)
    local o = {
        name      = args.name       -- "recipe"
    ,   is_known  = args.is_known   -- false
    ,   lack_msg  = args.lack_msg   -- "Recipe not known"
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Know:DebugText()
    return string.format("%s:%s", self.name, tostring(self.is_known))
end

function Know:TooltipText()
    if self.is_known then return nil end
    d(self.lack_msg)
    return WritWorthy.Util.red(self.lack_msg)
end
