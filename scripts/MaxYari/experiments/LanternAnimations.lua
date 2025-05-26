local core = require('openmw.core')
local world = require('openmw.world')
local util = require('openmw.util')
local gutils = require('scripts/MaxYari/experiments/scripts/gutils')

local PLAYER_EVENT_RAYCAST_REQUEST = "LanternRaycastRequest"
local PLAYER_EVENT_RAYCAST_RESULT = "LanternRaycastResult"


local currentCell = nil
local currentCellsGroup = nil
local player = world.players[1]

local activeLanternDistance = 100*69
-- Animation framerate limiting parameters
local minAnimFPS = 120      -- Closest possible: 60 FPS
local maxAnimFPS = 25      -- Furthest possible: 10 FPS
local minAnimDist = 10*69      -- Distance at which minAnimFPS applies
local maxAnimDist = activeLanternDistance   -- Distance at which maxAnimFPS applies

local lanterns = {} -- Now a table indexed by object.id
-- Deferred lantern search state
local pendingLanternObjects = nil -- list of lists (cell objects)
local pendingLanternCellIdx = 1
local pendingLanternObjIdx = 1
local PENDING_LANTERN_BATCH = 100
local PENDING_LANTERN_RAYCASTS = 3

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
    { name = "active_sign_c_guild", offset = util.vector3(0, 0, 0), localSwingDirection = util.vector3(1, 0, 0), avoidYawRotation = true, weight = 1.5, onlyHangs = true },
    { name = "furn_sign_inn", offset = util.vector3(0, 0, 0), localSwingDirection = util.vector3(1, 0, 0), avoidYawRotation = true, weight = 1.5, onlyHangs = true },
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
                if dx == 0 and dy == 0 then goto continue end
                local cellX = centerX + dx
                local cellY = centerY + dy
                local cell = world.getExteriorCell(cellX, cellY)
                table.insert(ret, cell)
                ::continue::
            end
        end
    end

    return ret
end



local function findLanternsDeferredStep()
    if not pendingLanternObjects then return end
    local processed = 0
    local raycastsThisFrame = 0
    while processed < PENDING_LANTERN_BATCH and pendingLanternObjects and raycastsThisFrame < PENDING_LANTERN_RAYCASTS do
        local cellList = pendingLanternObjects[pendingLanternCellIdx]
        if not cellList then
            pendingLanternObjects = nil
            break
        end
        while pendingLanternObjIdx <= #cellList and processed < PENDING_LANTERN_BATCH and raycastsThisFrame < PENDING_LANTERN_RAYCASTS do
            local obj = cellList[pendingLanternObjIdx]
            local foundConfig = nil
            for _, config in ipairs(lanternConfigs) do
                local model = obj.type.record(obj).model
                if obj.recordId:find(config.name) or (model and model:find(config.name)) then
                    foundConfig = config
                    break
                end
            end
            if foundConfig then
                local finishedInitialise = false
                if foundConfig.onlyHangs then
                    finishedInitialise = true
                end
                local timerOffset = math.random() / 4
                lanterns[obj.id] = {
                    object = obj,
                    swingPhaseOffset = math.random() * 2 * math.pi,
                    yawPhaseOffset = math.random() * 2 * math.pi,
                    originOffset = foundConfig.offset,
                    localSwingDirection = foundConfig.localSwingDirection,
                    avoidYawRotation = foundConfig.avoidYawRotation,
                    weight = foundConfig.weight or 1,
                    windData = initializeLanternWindData(obj),
                    animTimer = timerOffset,
                    finishedInitialise = finishedInitialise,
                    configName = foundConfig.name,
                    onlyHangs = foundConfig.onlyHangs,
                }
                -- If not finishedInitialise, send for raycast (up to PENDING_LANTERN_RAYCASTS per frame)
                if not finishedInitialise  then
                    -- print("Sending lantern raycast request event for:", obj)
                    player:sendEvent(PLAYER_EVENT_RAYCAST_REQUEST, { lantern = obj })
                    raycastsThisFrame = raycastsThisFrame + 1
                end
            end
            processed = processed + 1
            pendingLanternObjIdx = pendingLanternObjIdx + 1            
        end        
        if pendingLanternObjIdx > #cellList then
            pendingLanternCellIdx = pendingLanternCellIdx + 1
            pendingLanternObjIdx = 1
        end
    end
    -- print("Processed lanterns:", processed, "Raycasts this frame:", raycastsThisFrame)
end

local function prepareLanternSearch()
    pendingLanternObjects = {}
    pendingLanternCellIdx = 1
    pendingLanternObjIdx = 1
    for _, cell in ipairs(currentCellsGroup or {}) do
        table.insert(pendingLanternObjects, cell:getAll())
    end
end

local function cleanUpLanterns()
    if not currentCellsGroup then return end
    for id, lanternData in pairs(lanterns) do
        if not lanternData.object:isValid() or not gutils.arrayContains(currentCellsGroup, lanternData.object.cell) then
            -- print("Removed a lantern", lanternData.object)
            lanterns[id] = nil
        end
    end
end

local function getAnimIntervalForDistance(dist)
    if dist <= minAnimDist then return 1 / minAnimFPS end
    if dist >= maxAnimDist then return 1 / maxAnimFPS end
    local t = (dist - minAnimDist) / (maxAnimDist - minAnimDist)
    local fps = minAnimFPS + (maxAnimFPS - minAnimFPS) * t
    return 1 / fps
end

local function onRaycastResult(data)
    -- results: array of { objectId = lantern.object.id, shouldInit = true/false }

    --print("Raycast result for lantern", data.lantern.id, "shouldInit:", data.shouldInit)
    
    local lantern = lanterns[data.lantern.id]
    if lantern then
        if data.shouldInit then
            lantern.finishedInitialise = true
        else
            -- print("Not initialising lantern", data.lantern.id, "due to raycast hit")
            lanterns[data.lantern.id] = nil
        end
    end
    
end

local function animateLanterns(dt)
    local lookDir = gutils.lookDirection(player)
    for id, lanternData in pairs(lanterns) do
        if not lanternData.finishedInitialise then goto continue end
        local lantern = lanternData.object
        local toLantern = lantern.position - player.position
        local dist = toLantern:length()
        if dist > activeLanternDistance then goto continue end
        if toLantern:dot(lookDir) < 0 then goto continue end

        local interval = getAnimIntervalForDistance(dist)
        lanternData.animTimer = (lanternData.animTimer or 0) - dt
        if lanternData.animTimer > 0 then goto continue end
        lanternData.animTimer = interval

        if lantern.count < 1 or lantern.cell == nil then
            lanterns[id] = nil
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
    prepareLanternSearch()
end

local function onUpdate(dt)
    local cell = player.cell
    if cell ~= currentCell then    
        currentCell = cell    
        onCellChange(cell)
    end

    findLanternsDeferredStep()
    animateLanterns(dt)
end

return {
    engineHandlers = {
        onUpdate = onUpdate
    },
    eventHandlers = {
        CellChange = onCellChange,
        [PLAYER_EVENT_RAYCAST_RESULT] = onRaycastResult,
    }
}
