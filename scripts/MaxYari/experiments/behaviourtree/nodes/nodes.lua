local _PACKAGE                     = (...):match("^(.+)[%./][^%./]+"):gsub("[%./]?node_types", "")

local Task                         = require(_PACKAGE .. '/node_types/node')
local ConditionDecorator           = require(_PACKAGE .. '/node_types/condition_decorator')
local ContinuousConditionDecorator = require(_PACKAGE .. '/node_types/continuous_condition_decorator')
local g                            = _BehaviourTreeGlobals

-- Helper functions --------
local function ParseConditionToFn(config)
    local fn = nil
    local p = config.properties
    local cleanValue = string.gsub(p.condition, "%$", "state.")
    fn, error = load("return " .. cleanValue)
    if error then
        error("Can not parse " .. config.name .. "condition")
    end
    if fn == nil then
        fn = function(x) return false end
    end
    return fn
end

local function parseRangeDuration(input)
    -- Written by ChatGPT :)
    if type(input) == "number" then
        return input
    end

    -- Check if input is a string in the format "number, number"
    if type(input) == "string" then
        -- Extract the two numbers from the string
        local num1, num2 = input:match("(%d+),%s*(%d+)")
        if num1 and num2 then
            -- Convert extracted strings to numbers
            num1 = tonumber(num1)
            num2 = tonumber(num2)
            if num1 and num2 then
                -- Ensure num1 is less than num2 for range generation
                if num1 > num2 then
                    num1, num2 = num2, num1
                end
                -- Generate and return a random number between num1 and num2
                return math.random(num1, num2)
            else
                error("Input string is not in the correct format or contains non-numeric values.")
            end
        else
            error("Input string is not in the correct format.")
        end
    end

    error("Unsupported input type. Only numbers and strings are supported.")
end

local function getTime(conf)
    if conf.timer ~= nil then
        return conf.timer()
    else
        return os.clock()
    end
end
------------------------------

-- Runs the child node only if condition is met. Condition field can refer to state values using '$' sign, example: "condition: $range < 100". Condition is checked only once when this decorator is reached, it will not abort if condition outcome is changed while the child is still running.
local function StateCondition(config)
    local p = config.properties
    local conditionFn = nil

    config.condition = function(task, state)
        if conditionFn == nil then
            conditionFn = ParseConditionToFn(config)
        end
        return conditionFn()
    end

    return ConditionDecorator:new(config)
end

-- Runs the child node only if condition is met. Condition field can refer to state values using '$' sign, example: "condition: $range < 100". Condition is checked every frame, it will abort if condition outcome is changed while the child is still running.
local function ContinuousStateCondition(config)
    local p = config.properties
    local conditionFn = nil

    config.condition = function(task, state)
        if conditionFn == nil then
            conditionFn = ParseConditionToFn(config)
        end
        return conditionFn()
    end

    return ContinuousConditionDecorator:new(config)
end

-- Refuses to run the child if the time passed from the last run is less than 'milliseconds' property. Range of durations can be provided in a format "milliseconds:200,400", then the amount of time will be determined randomly withing the provided range.
local function Cooldown(config)
    local p = config.properties

    config.start = function(self, state)
        g.print(self.rname .. "started")
        self.duration = parseRangeDuration(p.milliseconds)
    end

    config.condition = function(self, state)
        local now = getTime(config) * 1000

        if not state.lastUseTime or now - state.lastUseTime > self.duration then
            state.lastUseTime = now
            return true
        end

        return false
    end

    return ContinuousConditionDecorator:new(config)
end

-- This task always succeeds
local function Succeeder(config)
    config.run = function(self, state)
        self:success()
    end
    return Task:new(config)
end

-- This task always fails
local function Failer(config)
    config.run = function(self, state)
        self:fail()
    end
    return Task:new(config)
end

function RandomOutcome(config)
    local props = config.props

    config.run = function(task, state)
        if props.probability > math.random() * 100 then
            task:success()
        else
            task:fail()
        end
    end

    return Task:new(config)
end

-- This task runs indefinitely
local function Runner(config)
    config.run = function(self, state)
        self:running()
    end
    return Task:new(config)
end

-- This task will run for a specified amount of time ('milliseconds' property). Range of durations can be provided in a format "milliseconds:200,400", then the amount of time will be determined randomly withing the provided range.
local function Wait(config)
    local p = config.properties

    config.start = function(t, state)
        g.print(t.rname .. "started")
        t.duration = parseRangeDuration(p.milliseconds)
        t.startTime = getTime(config) * 1000
    end

    config.run = function(t, state)
        local now = getTime(config) * 1000
        if now - t.startTime > t.duration then
            t:success()
        else
            t:running()
        end
    end

    config.finish = function(t, state)
        g.print(t.rname .. " finished")
    end
end

local function registerPremadeNodes(reg)
    reg.register("StateCondition", StateCondition)
    reg.register("ContinuousStateCondition", ContinuousStateCondition)
    reg.register("Cooldown", Cooldown)
    reg.register("Succeeder", Succeeder)
    reg.register("Failer", Failer)
    reg.register("RandomOutcome", RandomOutcome)
    reg.register("Runner", Runner)
    reg.register("Wait", Wait)
end

return registerPremadeNodes
