local mp = 'scripts/MaxYari/experiments/'

local core = require('openmw.core')
local world = require('openmw.world')
local util = require('openmw.util')
local gutils = require(mp..'scripts/gutils')

local physicsObjectScript = mp.."PhysicsObjectLocal.lua"

local grid = {}
local function getGridCell(position)
    return math.floor(position.x / gridSize), math.floor(position.y / gridSize), math.floor(position.z / gridSize)
end

local function addToGrid(physObject)
    local cellX, cellY, cellZ = getGridCell(physObject.position)
    local cellKey = string.format("%d,%d,%d", cellX, cellY, cellZ)
    if not grid[cellKey] then
        grid[cellKey] = {}
    end
    table.insert(grid[cellKey], physObject)
end

local function clearGrid()
    grid = {}
end

local function checkCollisionsInGrid()
    for cellKey, objects in pairs(grid) do
        for i = 1, #objects do
            local physObj1 = objects[i]
            if physObj1.isSleeping then goto icontinue end
            for j = i + 1, #objects do
                local physObj2 = objects[j]
                if physObj1:isCollidingWith(physObj2) then
                    physObj1:handlePhysObjectCollision(physObj2)
                end
            end
            ::icontinue::
        end
    end
end

local frame = 0
local function onUpdate(dt)
    --print("Global Onupdate frame", frame)
    frame = frame + 1
end

local spawnRequestObjects = {}

local function handleTeleportRequest(d)
    -- print("Global received teleport request from",d.object,"At frame",frame)
    local object = d.object
    --[[ if not object then object = spawnRequestObjects[d.id] end
    if not object then error("TeleportRequest: object not found") end ]]
    local position = d.position - d.rotation:apply(d.origin)
    local rotation = d.rotation
    --print(object)
    if object and object:isValid() and object.count > 0 then
        object:teleport(object.cell, position, { rotation = rotation })
    end
end




return {
    engineHandlers = {
        onUpdate = onUpdate
    },
    eventHandlers = {
        TeleportRequest = handleTeleportRequest,
        Physicify = function(e)
            print("Global received phisicify request for object",e.object," at frame",frame)
            if e.object:hasScript(physicsObjectScript) then e.object:removeScript(physicsObjectScript) end
            e.object:addScript(physicsObjectScript, e.properties)
        end,
        --[[ SpawnObject = function(e)
            local object = gutils.spawnObject(e.recordId, e.position, e.cell, e.onGround)
            spawnRequestObjects[e.requestId] = object
            e.source:sendEvent('ObjectSpawned', { object = object, requestId = e.requestId })
        end,
        ObjectSpawnedAck = function(e)
            print("Received object spawned ack for requestId: " .. e.requestId .. "Removing from request table.")
            spawnRequestObjects[e.requestId] = nil
        end ]]
    }
}
