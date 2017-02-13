
local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Util.lua

WritWorthy.MatRow = {}
local MatRow = WritWorthy.MatRow
local Fail   = WritWorthy.Util.Fail

-- requires WritWorthy.LINK[]
-- requires WritWorthy.MMPrice()
-- requires WritWorthy.Util.ToMoney()

-- MatRow ====================================================================
--
-- One row of a materials list.
--
function MatRow:New()
    local o = {
        name    = nil   -- "rubedite"
    ,   link    = nil   -- "|H0:item:64489:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
    ,   ct      = nil   -- 13
    ,   mm      = nil   -- 13.42315
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function MatRow:FromName(mat_name, ct)
    local o  = MatRow:New()
    o.name = mat_name
    o.link = WritWorthy.LINK[mat_name]
    if not o.link then return Fail("link not found:"..tostring(mat_name)) end
    if ct then
        o.ct = tonumber(ct)
    else
        o.ct = 1
    end
    o.mm = WritWorthy.Util.MMPrice(o.link)
    if not o.mm then return Fail("MM not found: " ..tostring(mat_name)) end
    return o
end

function MatRow:FromLink(mat_link, ct)
    local o  = MatRow:New()
    o.name = GetItemLinkName(mat_link)
    o.link = mat_link
    if not o.link then return Fail("name not found:"..tostring(mat_link)) end
    if ct then
        o.ct = tonumber(ct)
    else
        o.ct = 1
    end
    o.mm = WritWorthy.Util.MMPrice(o.link)
    if not o.mm then return Fail("MM not found: " ..tostring(mat_name)) end
    return o
end

function MatRow:Total()
    if not self.ct then return 0 end
    if not self.mm then return 0 end
    return self.ct * self.mm
end

-- list functions ------------------------------------------------------------

function MatRow.ListDump(mat_list)
    local total = 0
    local ToMoney = WritWorthy.Util.ToMoney

    for _, row in ipairs(mat_list) do
        local row_total = row:Total()
        total = total + row_total
        d(ToMoney(row_total) .. "g = "
         .. tostring(row.ct) .. "x "
         .. ToMoney(row.mm) .. " "
         .. tostring(row.link) )
    end
    d(ToMoney(total) .. "g total")
end

function MatRow.ListTotal(mat_list)
    local total = 0
    for _, row in ipairs(mat_list) do
        total = total + row:Total()
    end
    return total
end
