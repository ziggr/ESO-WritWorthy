-- Record writ item links, inputs, and decisions.
--
-- Operate as a fixed-length queue of the N most recent writs.

local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Define.lua

WritWorthy.Log = {
    q = {
        left_index = 0
    ,   right_index = -1
    ,   current = nil
    }
,   MAX_EVENT_CT = 20
}

local Log = WritWorthy.Log

-- Generic Queue -------------------------------------------------------------

function Log:PushRight(e)
    self.q.right_index = self.q.right_index + 1
    self.q[self.q.right_index] = e
    return e
end

function Log:PopLeft()
    if self.q.right_index < self.q.left_index then return nil end
    local e = self.q[self.q.left_index]
    self.q.left_index = self.q.left_index + 1
    self.q[self.q.left_index] = nil
    return e
end

function Log:EventCt()
    return 1 + self.q.right_index - self.q.left_index
end

-- Event ---------------------------------------------------------------------

function Log:StartNewEvent()
    self:TruncateEventList()
    self.current = self:PushRight({})
    return self.current
end

-- If we're at max capacity, throw out the oldest event.
function Log:TruncateEventList()
    if self:EventCt() < self.MAX_EVENT_CT then return end
    self:PopLeft()
end

-- Append one value to the current event
function Log:Add(value)
    if not self.current then
        self:StartNewEvent()
    end
    table.insert(self.current,  value)
end

-- File I/O (well, just I) ---------------------------------------------------

-- If prev_q looks like a valid saved copy of Log.q, then use prev_q as
-- our new Log.q.  If not, NOP, leaving our default Log.q in place.
function Log:LoadPreviousQueue(prev_q)
                        -- Validate: don't let corruption in SavedVariables
                        -- afflict us after a /reloadui.
    if not prev_q then return end
    if not prev_q.left_index then return end
    if not prev_q.right_index then return end
                        -- Too many events in log, just start empty rather
                        -- than try to purge the oldest.
    if Log.MAX_EVENT_CT <= (prev_q.right_index - prev_q.left_index) then
        return
    end
                        -- Make sure everything between the head and tail
                        -- pointers are filled. And while scanning, retain
                        -- ONLY those elements in this range, skipping any
                        -- that try to sneak in from outside the range, and
                        -- sliding everyone down to 0 again while we're at it.
    local new_q = {}
    for i = prev_q.left_index+1,prev_q.right_index do
        if not prev_q[i] then return end
        table.insert(new_q, prev_q[i])
    end
    new_q.right_index = #new_q - 1
    new_q.left_index = 0
    new_q.current = nil
    self.q = new_q
end

