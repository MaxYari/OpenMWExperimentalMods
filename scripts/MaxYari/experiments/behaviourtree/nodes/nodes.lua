local _PACKAGE           = (...):match("^(.+)[%./][^%./]+"):gsub("[%./]?nodes", "")

local Task               = require(_PACKAGE .. '/node_types/node')
local Decorator          = require(_PACKAGE .. '/node_types/decorator')
local RepeaterDecorator  = require(_PACKAGE .. '/node_types/repeater_decorator')
local InterruptDecorator = require(_PACKAGE .. '/node_types/interrupt_decorator')
local g                  = _BehaviourTreeGlobals

-- Helper functions --------

-- Wrapper function to dynamically use `load` or `loadCode`
-- This aproach probably needs to be reviewed again
local loadCode           = nil
local baseLoad           = _G.load or load or loadstring
if baseLoad then
    loadCode = function(code, scope)
        local func, err = baseLoad(code)
        if func then
            setfenv(func, scope) -- Set the environment to the provided scope
            return func
        else
            return nil, err
        end
    end
else
    -- OpenMW compatibility
    loadCode = require('openmw.util').loadCode
end

-- Finding a time measureing function (should return time in seconds, used for measuring time periods, absolute value not important).
-- With built-in OpenMW compatibility.
local clock = _G.clock or os.clock or require('openmw.core').getRealTime
-------------------------------------------------------
-------------------------------------------------------

-- Helper functions ---------------------------------
local function ParseConditionToFn(config, state)
    local err = nil
    local p = config.properties
    local cleanValue = string.gsub(p.condition, "%$", "")

    local fn, err = loadCode("return " .. cleanValue, state)
    if err then
        print("Can not parse " .. config.name .. " condition: " .. cleanValue)
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
------------------------------------------------------

-- Runs a child node only if condition is met. Condition field can refer to state values using '$' sign, example: "condition: $range < 100". Condition is checked only once when this decorator is reached, it will not abort if condition outcome is changed while the child is still running.
local function StateCondition(config)
    local p = config.properties
    local conditionFn = nil

    config.start = function(self, state)
        conditionFn = ParseConditionToFn(config, state)

        if not conditionFn() then
            self:fail()
        end
    end

    return Decorator:new(config)
end

local function StateInterrupt(config)
    local p = config.properties
    local conditionFn = nil

    config.registered = function(self, state)
        conditionFn = ParseConditionToFn(config, state)
    end

    config.shouldInterrupt = function(self, state)
        local resp = not self.started and conditionFn()
        return resp
    end

    config.start = function(self, state)
        self.started = true
    end

    config.finish = function(self, state)
        self.started = false
    end

    return InterruptDecorator:new(config)
end

local function ContinuousStateCondition(config)
    local p = config.properties
    local conditionFn = nil

    -- Will not be ignored by branch nodes (Sequence, Priority e.t.c), branch node will be able to trigger it as any other regular node.
    config.branchIgnore = false

    config.registered = function(self, state)
        conditionFn = ParseConditionToFn(config, state)
    end

    config.shouldInterrupt = function(self, state)
        local resp = self.started and not conditionFn() -- Only interrupt itself, and only when condition is false
        -- If interrupted execution will bounce back to start(), where fail will be reported
        return resp
    end

    config.start = function(self, state)
        if conditionFn() then
            self.started = true
        else
            self:fail()
        end
    end

    return InterruptDecorator:new(config)
end

-- Runs a child until its done or until the time runs out, in the latter case - fails and stops the child. 'milliseconds' property specifies the amount of time.
local function LimitRuntime(config)
    -- REWRITE: Needs to use interrupt node instead of decorator now
    local p = config.properties
    local timer = config.clock or clock

    config.start = function(self, state)
        self.duration = parseRangeDuration(p.milliseconds)
        self.startedAt = timer()
    end

    config.run = function(self, state)
        if (timer() - self.startedAt) * 1000 > self.duration then
            return self.interruptWithFail()
        end
    end

    return Decorator:new(config)
end

-- Repeats a child task specified amount of time ('maxLoop' parameter, -1 = no limit). Will stop and report success after the first child task success. Will report failure if all repetitions were done without a single child success.
local function RepeatUntilSuccess(config)
    config.untilSuccess = true
    return RepeaterDecorator:new(config)
end

-- Repeats a child task specified amount of time ('maxLoop' parameter, -1 = no limit). Will stop and report success after the first child task failure. Will report failure if all repetitions were done without a single child failure.
local function RepeatUntilFailure(config)
    config.untilFailure = true
    return RepeaterDecorator:new(config)
end

-- Refuses to run the child if the time passed from the last run is less than 'milliseconds' property. Range of durations can be provided in a format "milliseconds:200,400", then the amount of time will be determined randomly withing the provided range.
local function Cooldown(config)
    local p = config.properties
    local timer = config.clock or clock

    config.start = function(self, state)
        g.print(self.name .. "started")
        self.duration = parseRangeDuration(p.milliseconds)

        local now = timer() * 1000

        if not state.lastUseTime or now - state.lastUseTime > self.duration then
            state.lastUseTime = now
            return self:success()
        else
            return self:fail()
        end
    end

    return Decorator:new(config)
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
    local props = config.properties

    -- this probably should be on start, not on run
    config.run = function(task, state)
        local roll = math.random() * 100
        if props.probability > roll then
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
    local timer = config.clock or clock

    config.start = function(t, state)
        t.duration = parseRangeDuration(p.milliseconds)
        t.startTime = timer() * 1000
    end

    config.run = function(t, state)
        local now = timer() * 1000
        if now - t.startTime > t.duration then
            t:success()
        else
            t:running()
        end
    end

    return Task:new(config)
end

local function registerPremadeNodes(reg)
    reg.register("StateCondition", StateCondition)
    reg.register("StateInterrupt", StateInterrupt)
    reg.register("ContinuousStateCondition", ContinuousStateCondition)
    reg.register("LimitRuntime", LimitRuntime)
    reg.register('RepeatUntilFailure', RepeatUntilFailure)
    reg.register('RepeatUntilSuccess', RepeatUntilSuccess)
    reg.register("Cooldown", Cooldown)
    reg.register("Succeeder", Succeeder)
    reg.register("Failer", Failer)
    reg.register("RandomOutcome", RandomOutcome)
    reg.register("Runner", Runner)
    reg.register("Wait", Wait)
end

return registerPremadeNodes
