local core = require('openmw.core')

-- Generic utility functions --

local module = {}

-- Helper print function
-- Author: mostly ChatGPT
local function uprint(...)
    local args = { ... }
    local lvl = args[#args]
    if type(lvl) ~= "number" then
        lvl = 1
    else
        table.remove(args)
    end
    if lvl <= DebugLevel then
        for i, v in ipairs(args) do
            args[i] = tostring(v)
        end
        print("[AI+ DEBUG]:", table.concat(args, " "))
    end
end

module.print      = uprint

-- A sampler that retains samples within specified time window and calculates their mean value
-- Author: mostly ChatGPT
local MeanSampler = {}
function MeanSampler:new(time_window)
    -- Create a new object with initial properties
    local obj = {
        time_window = time_window,
        values = {},
        mean = 0,
        warmedUp = false
    }

    -- Define the sample function for the sampler instance
    function obj:sample(value)
        -- Get the current time
        local current_time = core.getRealTime()

        -- Add the new value and its timestamp to the values array
        table.insert(self.values, { time = current_time, value = value })

        -- Remove values that are older than the specified time window
        self.warmedUp = false
        local i = 1
        while i <= #self.values do
            if current_time - self.values[i].time > self.time_window then
                table.remove(self.values, i)
                self.warmedUp = true
            else
                i = i + 1
            end
        end

        -- Calculate the mean of the remaining values
        local sum = 0
        for _, v in ipairs(self.values) do
            sum = sum + v.value
        end
        if #self.values > 0 then
            self.mean = sum / #self.values
        else
            self.mean = 0
        end
    end

    -- Set the metatable for the new object to use the class methods
    setmetatable(obj, self)
    self.__index = self

    return obj
end

module.MeanSampler = MeanSampler

local function findField(dictionary, value)
    for field, val in pairs(dictionary) do
        if val == value then
            return field
        end
    end
    return nil
end
module.findField = findField

local function cache(fn, delay)
    delay = delay or 0.25 -- default delay is 0.25 seconds
    local lastExecution = 0
    local c1, c2 = nil, nil

    return function(...)
        local currentTime = core.getRealTime()
        if currentTime - lastExecution < delay then
            return c1, c2, "cached"
        end

        lastExecution = currentTime
        c1, c2 = fn(...)
        return c1, c2, "new"
    end
end
module.cache = cache

-- Function to find a point on the circle's circumference
-- Author: ChatGPT
local function pointOnCircle(center, radius, start, distance, direction)
    -- Calculate the angle from the center to the starting point
    local dx = start.x - center.x
    local dy = start.y - center.y
    local startAngle = math.atan2(dy, dx)

    -- Calculate the angle to travel along the circumference
    local travelAngle = distance / radius

    -- Calculate the new angle
    local newAngle = startAngle + (travelAngle * direction)

    -- Compute the new point on the circle
    local newPoint = {
        x = center.x + radius * math.cos(newAngle),
        y = center.y + radius * math.sin(newAngle)
    }

    return newPoint
end
module.pointOnCircle = pointOnCircle

return module