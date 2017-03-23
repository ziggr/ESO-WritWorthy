-- Record writ item links, inputs, and decisions.
--
-- Operate as a fixed-length queue of the N most recent writs.

local WritWorthy = _G['WritWorthy'] -- defined in WritWorthy_Util.lua

WritWorthy.Log = {
    event_queue = {}
,   queue_left_index = 0
,   queue_right_index = -1

,   current = nil

,   MAX_EVENT_CT = 10
}

local Log = WritWorthy.Log

-- Generic Queue -------------------------------------------------------------

function Log:PushRight(e)
    self.queue_right_index = self.queue_right_index + 1
    self.event_queue[self.queue_right_index] = e
    return e
end

function Log:PopLeft()
    if self.queue_right_index < self.queue_left_index then return nil end
    local e = self.event_queue[self.queue_left_index]
    self.queue_left_index = self.queue_left_index + 1
    self.event_queue[self.queue_left_index] = nil
    return e
end

function Log:EventCt()
    return 1 + self.queue_right_index - self.queue_left_index
end

-- Event ---------------------------------------------------------------------

function Log:StartNewEvent(args)
    self:TruncateEventList()
    self.current = self:PushRight(args)
    return self.current
end

-- If we're at max capacity, throw out the oldest event.
function Log:TruncateEventList()
    if self:EventCt() < self.MAX_EVENT_CT then return end
    self:PopLeft()
end

-- Set one field in the current event.
function Log:Set(key, value)
    if not self.current then
        self:StartNewEvent()
    end
    self.current[key] = value
end


