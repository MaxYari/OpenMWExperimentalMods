local core = require('openmw.core')
local world = require('openmw.world')
local util = require('openmw.util')
local gutils = require('scripts/MaxYari/experiments/scripts/gutils')

local currentCell = nil
local currentCellsGroup = nil
local player = world.players[1]

local activeLanternDistance = 100*69
local lanterns = {}
local gravity = 9.8
local angularDamping = 0.99
local windDirection = util.vector3(1, -1, 0):normalize()
local yawRotationSpeed = 0.02
local yawRotationAmplitude = 0.5

local windPowerMin = 0
local windPowerMax = 0
local extWindPowerMin = 1
local extWindPowerMax = 2
local intWindPowerMin = 0
local intWindPowerMax = 0.5
local windBurstProbability = 0.5
local windPowerChangeInterval = 1

--if true then return end


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
    { name = "tr_l_de_lantern", offset = util.vector3(0, 0, 0) },
    { name = "light_ashl_lantern", offset = util.vector3(0, 0, 25) },
    { name = "light_com_lantern", offset = util.vector3(0, 0, 0) },
    { name = "active_sign_c_guild", offset = util.vector3(0, 0, 0), localSwingDirection = util.vector3(1, 0, 0), avoidYawRotation = true, weight = 1.5 },
    { name = "furn_sign_inn", offset = util.vector3(0, 0, 0), localSwingDirection = util.vector3(1, 0, 0), avoidYawRotation = true, weight = 1.5 },
    { name = "light_de_streetlight", offset = util.vector3(0, 0, 0) }
}

local function getCellsAround(centerCell)
    local ret = {}
    local centerX, centerY = centerCell.gridX, centerCell.gridY
    table.insert(ret, centerCell)

    if centerCell.isExterior then
        -- Iterate over the surrounding cells
        for dx = -1, 1 do
            for dy = -1, 1 do
                local cellX = centerX + dx
                local cellY = centerY + dy
                local cell = world.getExteriorCell(cellX, cellY)
                table.insert(ret, cell)
            end
        end
    end

    return ret
end

local function findLanterns()
    if not currentCellsGroup then
        error("Current cells group is not set, but we are trying to find lanterns. This should never happen", 2)
        return
    end
    for _, cell in ipairs(currentCellsGroup) do
        for _, obj in ipairs(cell:getAll()) do
            for _, config in ipairs(lanternConfigs) do
                local model = obj.type.record(obj).model
                if obj.recordId:find(config.name) or (model and model:find(config.name)) then
                    print("Found a lantern",obj)
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
    
end

local function cleanUpLanterns()
    if not currentCellsGroup then return end

    for i = #lanterns, 1, -1 do
        local lanternData = lanterns[i]
        if not lanternData.object:isValid() or not gutils.arrayContains(currentCellsGroup,lanternData.object.cell) then
            print("Removed a lantern", lanternData.object)
            table.remove(lanterns, i)
        end
    end
end

local function animateLanterns(dt)
    local lookDir = gutils.lookDirection(player)
    for i = #lanterns, 1, -1 do
        local lanternData = lanterns[i]
        local lantern = lanternData.object
        local toLantern = lantern.position - player.position
        if (toLantern):length() > activeLanternDistance then goto continue end
        if toLantern:dot(lookDir) < 0 then goto continue end
        
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

        ::continue::
    end
end

local function onCellChange(cell)
    currentCellsGroup = getCellsAround(cell)
    if cell.isExterior then
        windPowerMin = extWindPowerMin
        windPowerMax = extWindPowerMax
    else
        windPowerMin = intWindPowerMin
        windPowerMax = intWindPowerMax
    end
    cleanUpLanterns()
    findLanterns()
end

local function onUpdate(dt)
    
    local cell = player.cell
    if cell ~= currentCell then    
        currentCell = cell    
        onCellChange(cell)
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
