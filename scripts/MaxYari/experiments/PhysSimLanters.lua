local core = require('openmw.core')
local world = require('openmw.world')
local types = require('openmw.types')
local util = require('openmw.util')
local gutils = require('scripts/MaxYari/experiments/scripts/gutils')


local assignedNpcs = {}
local lanterns = {}
local sittingZOffset = -36
local sittingForwardOffset = -7
local swingAmplitude = 0.1
local swingSpeed = 0.05
local lanternOrigin = util.vector3(0, 0, 35) -- Adjust this value as needed
local lerpDuration = 1
local swingDirection = util.vector3(1, 1, 0) -- Default swing direction (adjustable)
local yawRotationSpeed = 0.02 -- Speed of yaw rotation (adjustable)
local yawRotationAmplitude = 0.5

local gravity = 9.8
local angularDamping = 0.99 -- Damping factor to reduce oscillations

local windForceBase = 0 -- Base wind force
local windForceBurst = 5 -- Maximum burst wind force
local windForce = windForceBase -- Current wind force
local windBurstInterval = 5 -- Average time (in seconds) between bursts
local windBurstDuration = 1 -- Duration (in seconds) of a wind burst
local windBurstTimer = 0 -- Timer to track bursts
local windBurstActive = false -- Whether a burst is currently active

local windDirection = swingDirection:normalize() -- Initial wind direction
local windDirectionTarget = swingDirection:normalize() -- Target wind direction
local windDirectionChangeSpeed = 0.1 -- Speed at which wind direction changes
local windDirectionVariance = 0.5 -- Maximum deviation for wind direction changes

local function updateWindDirection(dt)
    -- Gradually approach the target wind direction
    if (windDirection - windDirectionTarget):length() < 0.01 then
        -- Roll a new target wind direction when close enough
        local randomOffset = util.vector3(
            math.random() * windDirectionVariance * 2 - windDirectionVariance,
            math.random() * windDirectionVariance * 2 - windDirectionVariance,
            0
        )
        windDirectionTarget = (swingDirection + randomOffset):normalize()
    else
        -- Gradually move towards the target direction
        windDirection = windDirection + (windDirectionTarget - windDirection):normalize() * windDirectionChangeSpeed * dt
        windDirection = windDirection:normalize()
    end
end

local function updateWindForce(dt)
    windBurstTimer = windBurstTimer - dt
    if windBurstTimer <= 0 then
        if windBurstActive then
            -- End the current burst
            windForce = windForceBase
            windBurstActive = false
            windBurstTimer = math.random() * windBurstInterval + windBurstInterval / 2 -- Randomize time until next burst
        else
            -- Start a new burst
            windForce = windForceBurst
            windBurstActive = true
            windBurstTimer = windBurstDuration
        end
    end
end

local function assignNpcsToStools(cell)
    local stools = {}
    for _, obj in ipairs(cell:getAll()) do
        if obj.recordId == "furn_de_p_stool_01" or obj.recordId == "furn_de_p_bench_03" then
            table.insert(stools, obj)        
        end
    end

    local npcs = cell:getAll(types.NPC)
    for i = 1, math.min(#stools, #npcs) do
        local npc = npcs[i]
        npc:sendEvent("ConsiderTheStool", { stool = stools[i] })
    end
end

local function findLanterns(cell)
    for _, obj in ipairs(cell:getAll()) do
        if obj.recordId == "light_de_paper_lantern_01" then
            table.insert(lanterns, {
                object = obj,
                swingPhaseOffset = math.random() * 2 * math.pi,
                yawPhaseOffset = math.random() * 2 * math.pi
            })
        end
    end
end

local function animateLanterns(dt)
    updateWindForce(dt) -- Update wind force
    updateWindDirection(dt) -- Update wind direction

    for _, lanternData in ipairs(lanterns) do
        local lantern = lanternData.object
        local swingPhaseOffset = lanternData.swingPhaseOffset
        local yawPhaseOffset = lanternData.yawPhaseOffset

        -- Swing physics simulation
        if not lanternData.angularVelocity then
            lanternData.angularVelocity = 0
        end
        if not lanternData.swingAngle then
            lanternData.swingAngle = 0
        end

        -- Calculate forces in the 2D plane defined by windDirection and lanternOrigin
        local swingAxis = windDirection:cross(util.vector3(0, 0, 1)):normalize()
        local gravityForce = -gravity * math.sin(lanternData.swingAngle)

        -- Wind force depends on the angle between the wind direction and the current swing angle
        local windForceEffect = windForce * math.cos(lanternData.swingAngle)

        local netTorque = gravityForce + windForceEffect

        -- Update angular acceleration, velocity, and angle
        local angularAcceleration = netTorque
        lanternData.angularVelocity = (lanternData.angularVelocity + angularAcceleration * dt) * angularDamping
        lanternData.swingAngle = lanternData.swingAngle + lanternData.angularVelocity * dt

        -- Calculate swing rotation
        local swingRotation = util.transform.rotate(lanternData.swingAngle, swingAxis)

        -- Yaw rotation animation (sinusoidal with a different phase)
        local yawAngle = math.sin(core.getGameTime() * yawRotationSpeed + yawPhaseOffset) * yawRotationAmplitude
        local yawRotation = util.transform.rotateZ(yawAngle)

        -- Combine swing and yaw rotations
        local combinedRotation = swingRotation * yawRotation

        -- Calculate origin offset to keep the attachment point fixed
        local currLanternOrigin = lantern.rotation:apply(lanternOrigin)
        local newLanternOrigin = combinedRotation:apply(lanternOrigin)
        local originOffset = currLanternOrigin - newLanternOrigin

        -- Apply the combined rotation and position adjustment
        lantern:teleport(lantern.cell, lantern.position + originOffset, {rotation = combinedRotation})
    end
end

local function onCellChange()
    local player = world.players[1]
    local cell = player.cell
    assignedNpcs = {}
    lanterns = {}
    assignNpcsToStools(cell)
    findLanterns(cell)
end

local function onStoolCheckResult(ev)
    if ev.usable then
        assignedNpcs[ev.npc] = { position = ev.hitPos, facingDirection = ev.facingDirection, lerpStartTime = nil }
        print("Sending npc to walk")
        ev.npc:sendEvent('StartAIPackage', {type="Travel", destPosition = ev.hitPos, isRepeat = false})
    end
end

local lastCell = nil

local function onUpdate(dt)
    local player = world.players[1]
    if player.cell ~= lastCell then
        lastCell = player.cell
        onCellChange()
    end
    for npc, data in pairs(assignedNpcs) do
        local distance = (npc.position - data.position):length()
        if distance < 100 then
            if data.npcStandingPos == nil then
                data.npcStandingPos = npc.position
                data.npcStandingRot = npc.rotation
            end
            if data.lerpTime == nil then
                data.lerpTime = 0
            else
                data.lerpTime = data.lerpTime + dt
            end
            local lerpProgress = data.lerpTime / lerpDuration
            
            if lerpProgress >= 1 then
                lerpProgress = 1                
            end
            if lerpProgress >= 0.5 then
                npc:sendEvent('SitDownPlease')
            end
            local forwardOffset = util.vector2(data.facingDirection.x, data.facingDirection.y):normalize() * sittingForwardOffset
            local offset = util.vector3(forwardOffset.x, forwardOffset.y, sittingZOffset)
            local sittingPos = data.position + offset
            local newPosition = gutils.lerp(data.npcStandingPos, sittingPos, lerpProgress)
            
            local targetAngle = math.atan2(data.facingDirection.x, data.facingDirection.y)
            local newAngle = gutils.lerpAngle(data.npcStandingRot:getYaw(), targetAngle, lerpProgress)

            npc:teleport(npc.cell, newPosition, {rotation = util.transform.rotateZ(newAngle)})
        end
    end
    animateLanterns(dt)
end

return {
    engineHandlers = {
        onUpdate = onUpdate
    },
    eventHandlers = {
        CellChange = onCellChange,
        StoolCheckResult = onStoolCheckResult
    }
}
