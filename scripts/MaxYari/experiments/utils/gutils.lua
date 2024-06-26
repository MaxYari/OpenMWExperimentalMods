local core = require('openmw.core')
local types = require('openmw.types')
local util = require('openmw.util')


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
        local i = 1
        while i <= #self.values do
            if current_time - self.values[i].time > self.time_window then
                table.remove(self.values, i)
            else
                i = i + 1
            end
        end

        self.warmedUp = self.values[#self.values].time - self.values[1].time > self.time_window * 0.75

        -- Calculate the mean of the remaining values
        local sum = nil
        for _, v in ipairs(self.values) do
            if sum then
                sum = sum + v.value
            else
                sum = v.value
            end
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

local PosToVelSampler = {
    new = function(self, time_window)
        self.positionSampler = MeanSampler:new(time_window)
        self.velocitySampler = MeanSampler:new(time_window)
        self.time_window = time_window
        return self
    end,
    sample = function(self, pos)
        self.positionSampler:sample(pos)
        if #self.positionSampler.values - 1 > 0 then
            local lastPosSample = self.positionSampler.values[#self.positionSampler.values]
            local preLastPosSample = self.positionSampler.values[#self.positionSampler.values - 1]
            local velocity = (lastPosSample.value - preLastPosSample.value) /
                (lastPosSample.time - preLastPosSample.time)
            self.velocitySampler:sample(velocity)
        end
        self.warmedUp = self.velocitySampler.warmedUp
    end,
    mean = function(self)
        return self.velocitySampler.mean
    end
}

module.PosToVelSampler = PosToVelSampler



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


local function randomDirection()
    -- Author: ChatGPT 2024
    local angle = math.random() * 2 * math.pi
    return util.vector3(math.cos(angle), math.sin(angle), 0)
end
module.randomDirection = randomDirection

local function minHorizontalHalfSize(bounds)
    return math.abs(math.min(bounds.halfExtents.x, bounds.halfExtents.y))
end
module.minHorizontalHalfSize = minHorizontalHalfSize

local function diagonalFlatHalfSize(bounds)
    return util.vector2(bounds.halfExtents.x, bounds.halfExtents.y):length()
end
module.diagonalFlatHalfSize = diagonalFlatHalfSize

local function getDistanceToBounds(actor, target)
    local dist = (target.position - actor.position):length() -
        types.Actor.getPathfindingAgentBounds(target).halfExtents.y -
        types.Actor.getPathfindingAgentBounds(actor).halfExtents.y;
    return dist;
end
module.getDistanceToBounds = getDistanceToBounds

local function lerp(a, b, t)
    return a + (b - a) * t
end
module.lerp = lerp

local function lerpClamped(a, b, t)
    t = math.max(0, math.min(t, 1))
    return lerp(a, b, t)
end
module.lerpClamped = lerpClamped

local Actor = {
    _mt = {
        __index = function(instance, key)
            return function(...)
                return types.Actor[key](instance.gameObject, ...)
            end
        end
    },
    new = function(self, go)
        local instance = {
            gameObject = go
        }
        setmetatable(instance, self._mt)
        return instance
    end,
}

module.Actor = Actor

local function getSortedAttackTypes(weaponRecord)
    -- Author: ChatGPT 2024
    local attacks = {
        { type = "Chop",   averageDamage = (weaponRecord.chopMinDamage + weaponRecord.chopMaxDamage) / 2 },
        { type = "Slash",  averageDamage = (weaponRecord.slashMinDamage + weaponRecord.slashMaxDamage) / 2 },
        { type = "Thrust", averageDamage = (weaponRecord.thrustMinDamage + weaponRecord.thrustMaxDamage) / 2 }
    }

    table.sort(attacks, function(a, b) return a.averageDamage > b.averageDamage end)

    return attacks
end

module.getSortedAttackTypes = getSortedAttackTypes

local function getGoodAttacks(attacks)
    local bestAttack = attacks[1]
    local goodAttacks = { bestAttack.type } -- Start with the best attack

    local threshold = 0.33                  -- Threshold for damage difference

    for i = 2, #attacks do
        local currentAttack = attacks[i]
        local percentageDifference = math.abs(currentAttack.averageDamage - bestAttack.averageDamage) /
            bestAttack.averageDamage

        if percentageDifference <= threshold then
            table.insert(goodAttacks, currentAttack.type)
        else
            break -- No need to check further since attacks are sorted by averageDamage
        end
    end

    return goodAttacks
end

module.getGoodAttacks = getGoodAttacks

local function pickWeightedRandomAttackType(attacks)
    -- Author: ChatGPT 2024
    local totalAverageDamage = 0
    for _, attack in ipairs(attacks) do
        totalAverageDamage = totalAverageDamage + attack.averageDamage
    end

    local rand = math.random() * totalAverageDamage
    local cumulativeProbability = 0

    for _, attack in ipairs(attacks) do
        cumulativeProbability = cumulativeProbability + attack.averageDamage
        if rand <= cumulativeProbability then
            return attack.type
        end
    end

    return attacks[1].type
end

module.pickWeightedRandomAttackType = pickWeightedRandomAttackType

local function getWeaponSkill(weaponRecord)
    return 50
end

module.getWeaponSkill = getWeaponSkill


return module
