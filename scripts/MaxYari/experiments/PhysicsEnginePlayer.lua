local mp = 'scripts/MaxYari/experiments/'

local core = require('openmw.core')
local util = require('openmw.util')
local types = require('openmw.types')
local nearby = require('openmw.nearby')
local ui = require('openmw.ui')
local camera = require('openmw.camera')
local omwself = require('openmw.self')
local gutils = require(mp..'scripts/gutils')
local PhysicsObject = require(mp..'PhysicsObject')
local PhysicsUtils = require(mp..'PhysicsUtilities')

local physicsTypes = {types.Armor, types.Potion, types.Book, types.Item, types.Lockpick, types.Miscellaneous, types.Weapon, types.Apparatus, types.Clothing, types.Ingredient}
local physicsObjects = {}

local gridSize = 150 -- Size of each grid cell
local grid = {} -- Table to store objects in grid cells

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

local function Physicify(obj, props)
    if physicsObjects[obj.id] then return nil end
    local physObject = PhysicsObject:new(obj, props)
    physicsObjects[obj.id] = physObject
    return physObject
end

local function getPhysicsObject(obj)
    return physicsObjects[obj.id]
end

local lastNearbyItemsAmount = 0
local function autoPhisicifyNearby()
    if lastNearbyItemsAmount == #nearby.items then return end
    for _, obj in ipairs(nearby.items) do
        if gutils.foundInList(physicsTypes, obj.type) and obj:isValid() then
            Physicify(obj, { mass = 1, drag = 0.1, bounce = 0.75 })
        end
    end
    lastNearbyItemsAmount = #nearby.items
end

local function onUpdate(dt)
    -- Find and setup hardcoded physics objects
    autoPhisicifyNearby()

    -- Clear the grid at the start of each update
    clearGrid()

    -- Update all physics objects and populate the grid
    for id, physObj in pairs(physicsObjects) do
        if physObj.object and physObj.object:isValid() then
            --print("Updating",physObj.object,id)
            physObj:update(dt)
            addToGrid(physObj)
        else
            print("Removing invalid object:", id)
            physicsObjects[id] = nil -- Remove invalid objects
        end
    end   

    -- Check collisions within the grid
    checkCollisionsInGrid()

    -- Check if object should go to sleep
    for id, physObj in pairs(physicsObjects) do
        physObj:trySleep(dt)
    end

    -- Utilities update loop
    PhysicsUtils.HoldGrabbedObject(dt)
end



return {
    engineHandlers = {
        onUpdate = onUpdate,
        onKeyPress = function(key)
            if key.symbol == 'y' then
                PhysicsUtils.ExplodeObjects()
            end
            if key.symbol == 'x' then
                PhysicsUtils.GrabObject()
            end
            if key.symbol == 'c' then
                PhysicsUtils.PushObjects()
            end
         end,
         onKeyRelease = function(key)
            if key.symbol == 'x' then
                PhysicsUtils.DropObject()
            end
         end,
    },
    interfaceName = "DumbPhysics",
    interface = {
        Physicify = Physicify,
        getPhysicsObject = getPhysicsObject,
    },
    
}
