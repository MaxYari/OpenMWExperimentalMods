local _PACKAGE           = (...):match("^(.+)[%./][^%./]+"):gsub("[%./]?nodes", "")

local Task               = require(_PACKAGE .. '/node_types/node')
local Decorator          = require(_PACKAGE .. '/node_types/decorator')
local RepeaterDecorator  = require(_PACKAGE .. '/node_types/repeater_decorator')
local InterruptDecorator = require(_PACKAGE .. '/node_types/interrupt_decorator')
local g                  = _BehaviourTreeGlobals


local function RandomThrough(config)
    local p = config.properties

    config.start = function(self, state)
        if math.random() * 100 > p.probability() then
            self:fail()
        end
    end

    return Decorator:new(config)
end

local function StateCondition(config)
    local p = config.properties

    config.start = function(self, state)
        if not p.condition() then
            self:fail()
        end
    end

    return Decorator:new(config)
end

local function StateInterrupt(config)
    local p = config.properties

    config.shouldInterrupt = function(self, state)
        local resp = not self.started and p.condition()
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

    -- Will not be ignored by branch nodes (Sequence, Priority e.t.c), branch node will be able to trigger it as any other regular node.
    config.isStealthy = false

    config.shouldInterrupt = function(self, state)
        local resp = self.started and not p.condition() -- Only interrupt itself, and only when condition is false
        -- If interrupted execution will bounce back to start(), where fail will be reported
        return resp
    end

    config.start = function(self, state)
        if p.condition() then
            self.started = true
        else
            self:fail()
        end
    end

    config.triggered = function(self, state)
        self:fail() -- Refuse to execute after interrupt is triggered, otherwise the node will start. But for this one it was already running and we only want to escape.
    end

    return InterruptDecorator:new(config)
end


local function LimitRunTime(config)
    local p = config.properties
    local timer = config.clock or g.clock

    local duration = 0
    local wasTriggered = false

    config.isStealthy = false

    config.start = function(self, state)
        self.duration = p.duration()
        self.startedAt = timer()
        self.started = true
    end

    config.shouldInterrupt = function(self, state)
        if self.started and ((timer() - self.startedAt) > self.duration) then
            return true
        end
    end

    -- Upon self-interrupt a following sequence of events will attempt to playout: [Current Task]finish()--[Interrupt]triggered()--[Interrupt]start()--...
    -- But in the case of this interrupt node - "Current Task" and "Interrupt" are the same node/task, since we are using interrupt to break out of itself.
    -- Naturally we have no interest in starting again after this task broke out of itself, so to finish breaking out - we can fail() in triggered().
    -- It is also possible to fail() in start(), but then we will have difficulties distinguishing between a start() after an interrupt and a natural start() due
    -- to the execution flow reaching the node. In some nodes this distinction will not matter, in this node - it does, hence it's much simpler to break out in triggered().
    config.triggered = function(self, state)
        self:fail()
    end

    return InterruptDecorator:new(config)
end


local function RepeatUntilSuccess(config)
    local p = config.properties
    config.untilSuccess = true
    -- Issue here is that maxLoop will be resolved only on init, instead of every start, which is not that good
    config.maxLoop = p.maxLoop()
    return RepeaterDecorator:new(config)
end


local function RepeatUntilFailure(config)
    local p = config.properties
    config.untilFailure = true
    config.maxLoop = p.maxLoop()
    return RepeaterDecorator:new(config)
end


local function Cooldown(config)
    -- Also - how can we add a cooldown for an interrupt, without triggering an interrup?
    local p = config.properties
    local timer = config.clock or g.clock
    local lastUseTime = nil
    local duration = nil


    config.start = function(self, state)
        if not duration then duration = p.duration() end

        local now = timer()
        self.gotThrough = false

        if not lastUseTime or now - lastUseTime > duration then
            lastUseTime = now
            duration = p.duration()
            self.gotThrough = true
        else
            return self:fail()
        end
    end

    config.finish = function(self, state)
        -- Rejecting is also finished, so this will be forever locked
        if self.gotThrough and p.hotWhileRunning() then
            lastUseTime = timer()
        end
    end

    return Decorator:new(config)
end


local function SetState(config)
    local p = config.properties

    config.start = function(self, state)
        for key, val in pairs(p) do
            state[key] = val()
        end
        return self:success()
    end

    return Task:new(config)
end


local function Succeeder(config)
    config.run = function(self, state)
        self:success()
    end
    return Task:new(config)
end


local function Failer(config)
    config.run = function(self, state)
        self:fail()
    end
    return Task:new(config)
end

function RandomSuccess(config)
    local props = config.properties

    -- this probably should be on start, not on run
    config.run = function(task, state)
        local roll = math.random() * 100
        if props.probability() > roll then
            task:success()
        else
            task:fail()
        end
    end

    return Task:new(config)
end

local function Runner(config)
    config.run = function(self, state)
        self:running()
    end
    return Task:new(config)
end

local function Wait(config)
    local p = config.properties
    local timer = config.clock or g.clock

    config.start = function(t, state)
        t.duration = p.duration()
        t.startTime = timer()
    end

    config.run = function(t, state)
        local now = timer()
        if now - t.startTime > t.duration then
            t:success()
        else
            t:running()
        end
    end

    return Task:new(config)
end


local function registerPremadeNodes(reg)
    reg.register("RandomThrough", RandomThrough)
    reg.register("StateCondition", StateCondition)
    reg.register("StateInterrupt", StateInterrupt)
    reg.register("ContinuousStateCondition", ContinuousStateCondition)
    reg.register("LimitRunTime", LimitRunTime)
    reg.register('RepeatUntilFailure', RepeatUntilFailure)
    reg.register('RepeatUntilSuccess', RepeatUntilSuccess)
    reg.register("Cooldown", Cooldown)
    reg.register("SetState", SetState)
    reg.register("Succeeder", Succeeder)
    reg.register("Failer", Failer)
    reg.register("RandomSuccess", RandomSuccess)
    reg.register("Runner", Runner)
    reg.register("Wait", Wait)
end

return registerPremadeNodes
