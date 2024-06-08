local _PACKAGE                     = (...):match("^(.+)[%./][^%./]+"):gsub("[%./]?node_types", "")

local Task                         = require(_PACKAGE .. '/node_types/node')
local ConditionDecorator           = require(_PACKAGE .. '/node_types/condition_decorator')
local ContinuousConditionDecorator = require(_PACKAGE .. '/node_types/continuous_condition_decorator')


-- Helper functions --------
local function ParseConditionToFn(config)
    local fn = nil
    local p = config.properties
    local cleanValue = string.gsub(p.condition, "%$", "state.")
    fn, error = load("return " .. cleanValue)
    if error then
        error("Can not parse " .. config.node.name .. "condition")
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

-- Randomly determines if the child node will run or not depending on the probability
local function RandomCondition(config)
    local p = config.properties

    return ConditionDecorator:new({
        --this is a child node
        node = config.childNode,
        condition = function(task, state)
            if p.probability > math.random() * 100 then
                return true
            else
                return false
            end
        end
    })
end

-- Runs the child node only if condition is met. Condition field can refer to state values using '$' sign, example: "condition: $range < 100". Condition is checked only once when this decorator is reached, it will not abort if condition outcome is changed while the child is still running.
local function StateCondition(config)
    local p = config.properties
    local conditionFn = nil

    return ConditionDecorator:new({
        node = config.childNode,

        concondition = function(task, state)
            if conditionFn == nil then
                conditionFn = ParseConditionToFn(config)
            end
            return conditionFn()
        end
    })
end

-- Runs the child node only if condition is met. Condition field can refer to state values using '$' sign, example: "condition: $range < 100". Condition is checked every frame, it will abort if condition outcome is changed while the child is still running.
local function ContinuousStateCondition(config)
    local p = config.properties
    local conditionFn = nil

    return ContinuousConditionDecorator:new({
        node = config.childNode,

        condition = function(task, state)
            if conditionFn == nil then
                conditionFn = ParseConditionToFn(config)
            end
            return conditionFn()
        end
    })
end

-- Refuses to run the child if the time passed from the last run is less than 'milliseconds' property. Range of durations can be provided in a format "milliseconds:200,400", then the amount of time will be determined randomly withing the provided range.
local function Cooldown(config)
    local p = config.properties

    return ContinuousConditionDecorator:new({
        rname = "Cooldown",
        duration = 0,
        node = config.childNode,

        start = function(t, state)
            print(t.rname .. "started")
            t.duration = parseRangeDuration(p.milliseconds)
        end,

        condition = function(t, state)
            local now = getTime(config) * 1000

            if not state.lastUseTime or now - state.lastUseTime > t.duration then
                state.lastUseTime = now
                return true
            end

            return false
        end
    })
end

-- This task always succeeds
local function Succeeder(config)
    return Task:new({
        run = function(t, state)
            t:success()
        end
    })
end

-- This task always fails
local function Failer(config)
    return Task:new({
        run = function(t, state)
            t:fail()
        end
    })
end

-- This task runs indefinitely
local function Runner(config)
    return Task:new({
        run = function(t, state)
            t:running()
        end
    })
end

-- This task will run for a specified amount of time ('milliseconds' property). Range of durations can be provided in a format "milliseconds:200,400", then the amount of time will be determined randomly withing the provided range.
local function Wait(config)
    local p = config.properties

    return Task:new({
        rname = 'wait',
        duration = 0,

        start = function(t, state)
            print(t.rname .. "started")
            t.duration = parseRangeDuration(p.milliseconds)
            t.startTime = getTime(config) * 1000
        end,

        run = function(t, state)
            local now = getTime(config) * 1000
            if now - t.startTime > t.duration then
                t:success()
            else
                t:running()
            end
        end,

        finish = function(t, state)
            print(t.rname .. " finished")
        end
    })
end

local function registerPremadeNodes(reg)
    reg.register("RandomCondition", RandomCondition)
    reg.register("StateCondition", StateCondition)
    reg.register("ContinuousStateCondition", ContinuousStateCondition)
    reg.register("Cooldown", Cooldown)
    reg.register("Succeeder", Succeeder)
    reg.register("Failer", Failer)
    reg.register("Runner", Runner)
    reg.register("Wait", Wait)
end

return registerPremadeNodes
