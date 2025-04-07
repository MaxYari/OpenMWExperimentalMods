local core = require('openmw.core')
local world = require('openmw.world')
local util = require('openmw.util')
local gutils = require('scripts/MaxYari/experiments/scripts/gutils')

local lanterns = {}
local gravity = 9.8
local angularDamping = 0.99
local windDirection = util.vector3(1, -1, 0):normalize()
local yawRotationSpeed = 0.02
local yawRotationAmplitude = 0.5

local windPowerMin = 1
local windPowerMax = 2
local windBurstProbability = 0.5
local windPowerChangeInterval = 1

local function initializeLanternWindData(lantern)
    local positionLength = lantern.position:length()
    local initialTimer = math.abs(math.sin(positionLength / 1000))
    return {
        windForce = 0,
        windPowerTarget = 0,
        windPowerChangeTimer = initialTimer,
        angularVelocity = 0,
        swingAngle = 0
    }
end

local function updateLanternWindForce(lanternData, dt)
    lanternData.windPowerChangeTimer = lanternData.windPowerChangeTimer - dt
    if lanternData.windPowerChangeTimer <= 0 then
        if math.random() < windBurstProbability then
            lanternData.windPowerTarget = math.random() * (windPowerMax - windPowerMin) + windPowerMin
        else
            lanternData.windPowerTarget = 0
        end
        lanternData.windPowerChangeTimer = windPowerChangeInterval / 2 + math.random() * windPowerChangeInterval / 2
    end
    lanternData.windForce = gutils.lerpClamped(lanternData.windForce, lanternData.windPowerTarget, dt * 2)
    if lanternData.windForce < 0 then lanternData.windForce = 0 end
end

local lanternConfigs = {
    { name = "light_de_paper_lantern", offset = util.vector3(0, 0, 35) },
    { name = "light_de_lantern", offset = util.vector3(0, 0, 0) },
    { name = "active_sign_c_guild", offset = util.vector3(0, 0, 0), localSwingDirection = util.vector3(1, 0, 0), avoidYawRotation = true, weight = 1.5 },
    { name = "light_de_streetlight", offset = util.vector3(0, 0, 0) }
}

local function findLanterns(cell)
    for _, obj in ipairs(cell:getAll()) do
        for _, config in ipairs(lanternConfigs) do
            if obj.recordId:find(config.name) then
                table.insert(lanterns, {
                    object = obj,
                    swingPhaseOffset = math.random() * 2 * math.pi,
                    yawPhaseOffset = math.random() * 2 * math.pi,
                    originOffset = config.offset,
                    localSwingDirection = config.localSwingDirection,
                    avoidYawRotation = config.avoidYawRotation,
                    weight = config.weight or 1,
                    windData = initializeLanternWindData(obj)
                })
                break
            end
        end
    end
end

local function animateLanterns(dt)
    for i = #lanterns, 1, -1 do
        local lanternData = lanterns[i]
        local lantern = lanternData.object
        if lantern.count < 1 or not lantern:isValid() then
            table.remove(lanterns, i)
        else
            local windData = lanternData.windData
            local originOffset = lanternData.originOffset
            local localSwingDirection = lanternData.localSwingDirection
            local avoidYawRotation = lanternData.avoidYawRotation
            local weight = lanternData.weight or 1

            updateLanternWindForce(windData, dt)

            local swingDirection = windDirection
            if localSwingDirection then
                swingDirection = lantern.rotation:apply(localSwingDirection):normalize()
                swingDirection = (swingDirection * windDirection:dot(swingDirection)):normalize()
            end
            local swingAxis = swingDirection:cross(util.vector3(0, 0, 1)):normalize()

            local gravityForce = -gravity * math.sin(windData.swingAngle)
            local windForceEffect = (windData.windForce / weight) * math.cos(windData.swingAngle)
            local netTorque = gravityForce + windForceEffect

            local angularAcceleration = netTorque
            windData.angularVelocity = (windData.angularVelocity + angularAcceleration * dt) * angularDamping
            windData.swingAngle = windData.swingAngle + windData.angularVelocity * dt

            local swingRotation = util.transform.rotate(windData.swingAngle, swingAxis)

            local combinedRotation
            if not avoidYawRotation then
                local yawAngle = math.sin(core.getGameTime() * yawRotationSpeed + lanternData.yawPhaseOffset) * yawRotationAmplitude
                local yawRotation = util.transform.rotateZ(yawAngle)
                combinedRotation = swingRotation * yawRotation
            else
                combinedRotation = swingRotation * util.transform.rotateZ(lantern.rotation:getYaw())
            end

            local currOriginOffset = lantern.rotation:apply(originOffset)
            local newOriginOffset = combinedRotation:apply(originOffset)
            local finalOffset = currOriginOffset - newOriginOffset

            lantern:teleport(lantern.cell, lantern.position + finalOffset, {rotation = combinedRotation})
        end
    end
end

local function onCellChange(cell)
    findLanterns(cell)
end

local lastCell = nil

local function onUpdate(dt)
    local player = world.players[1]
    local cell = player.cell
    if cell ~= lastCell then        
        onCellChange(cell)
        lastCell = cell
    end

    animateLanterns(dt)
end

return {
    engineHandlers = {
        onUpdate = onUpdate
    },
    eventHandlers = {
        CellChange = onCellChange
    }
}
