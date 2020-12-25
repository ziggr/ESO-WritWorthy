
local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Define.lua

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
    ,   mm      = nil   -- 13.42315  Can be nil if MM not loaded, or lacks a price for this material.

                        -- Intentionally NOT caching inventory count here.
                        -- Inventory decreases as we craft, shop, trade, loot,
                        -- and I don't want the cache invalidation complexity.
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function MatRow:FromName(mat_name, ct)
    local o  = MatRow:New()
    o.name = mat_name
    o.link = WritWorthy.FindLink(mat_name)
    if not o.link then return Fail("link not found:"..tostring(mat_name)) end
    o.name_tr = o.name
    o.item_id = GetItemLinkItemId(o.link)
    o.name    = WritWorthy.Mat(o.item_id)
    if ct then
        o.ct = tonumber(ct)
    else
        o.ct = 1
    end
    o.mm = WritWorthy.Util.MatPrice(o.link)
    return o
end

function MatRow:FromLink(mat_link, ct)
    local o  = MatRow:New()
    o.name = GetItemLinkName(mat_link)
    o.link = mat_link
    if not o.link then return Fail("name not found:"..tostring(mat_link)) end
    o.name_tr = o.name
    o.item_id = GetItemLinkItemId(o.link)
    o.name    = WritWorthy.Mat(o.item_id)
    if ct then
        o.ct = tonumber(ct)
    else
        o.ct = 1
    end
    o.mm = WritWorthy.Util.MatPrice(o.link)
    return o
end

-- Return number amount of gold or WritWorthy.GOLD_UNKNOWN (aka nil) if unknown.
function MatRow:Total()
    if not self.ct then return WritWorthy.GOLD_UNKNOWN end
    if not self.mm then return WritWorthy.GOLD_UNKNOWN end
    return self.ct * self.mm
end

function MatRow:HaveCt()
    return WritWorthy.Util.MatHaveCt(self.link)
end

-- list functions ------------------------------------------------------------

function MatRow.ListDump(mat_list)
    if not mat_list then return end
    local ToMoney = WritWorthy.Util.ToMoney
    for _, row in ipairs(mat_list) do
        local row_total = row:Total()
        d(ToMoney(row_total) .. "g = "
         .. tostring(row.ct) .. "x "
         .. ToMoney(row.mm) .. "g "
         .. tostring(row.link) )
    end
    local total = MatRow.ListTotal(mat_list)
    d(ToMoney(total) .. "g total")
end

function MatRow.ListTotal(mat_list)
    if not mat_list then return end
    local total = 0
    for _, row in ipairs(mat_list) do
        local row_total = row:Total()
        if row_total and total then
            total = total + row_total
        else
            total = WritWorthy.GOLD_UNKNOWN
        end
    end
    return total
end
