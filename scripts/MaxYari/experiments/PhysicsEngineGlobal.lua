local mp = 'scripts/MaxYari/experiments/'

local core = require('openmw.core')
local world = require('openmw.world')
local util = require('openmw.util')
local gutils = require(mp..'scripts/gutils')
local PhysicsObject = require(mp..'PhysicsObject')

-- local physicsObjectScript = mp.."PhysicsEngineLocal.lua"

local grid = {}
local gridSize = 150
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
            for j = i + 1, #objects do                
                local physObj2 = objects[j]
                if physObj1.isSleeping and physObj2.isSleeping then goto jcontinue end
                if PhysicsObject.isCollidingWith(physObj1, physObj2) then
                    physObj1.object:sendEvent('CollidingWithPhysObj', { other = physObj2 })
                    physObj2.object:sendEvent('CollidingWithPhysObj', { other = physObj1 })
                end
                ::jcontinue::
            end            
        end
    end
end

local frame = 0
local function onUpdate(dt)
    --print("Global Onupdate frame", frame)
    frame = frame + 1

    checkCollisionsInGrid()
    clearGrid()
end


local function handleUpdateVisPos(physObject)
    -- print("Global received teleport request from",d.object,"At frame",frame)
    local object = physObject.object
    --[[ if not object then object = spawnRequestObjects[physObject.id] end
    if not object then error("TeleportRequest: object not found") end ]]
    local position = physObject.position - physObject.rotation:apply(physObject.origin)
    local rotation = physObject.rotation
    --print(object)
    if object and object:isValid() and object.count > 0 then
        object:teleport(object.cell, position, { rotation = rotation })
        if not physObject.ignorePhysObjectCollisions then addToGrid(physObject) end
        --if physObject.ignorePhysObjectCollisions then print("Ignoring collisions for",object.recordId) end
    end
end


return {
    engineHandlers = {
        onUpdate = onUpdate
    },
    eventHandlers = {
        LuaPhysics_UpdateVisPos = handleUpdateVisPos,
       --[[  Physicify = function(e)
            print("Global received phisicify request for object",e.object," at frame",frame)
            if e.object:hasScript(physicsObjectScript) then return end
            e.object:addScript(physicsObjectScript, e.properties)
        end, ]]
    }
}
