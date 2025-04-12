local mp = 'scripts/MaxYari/experiments/'

local core = require('openmw.core')
local util = require('openmw.util')
local types = require('openmw.types')
local nearby = require('openmw.nearby')
local ui = require('openmw.ui')
local camera = require('openmw.camera')
local omwself = require('openmw.self')
local input = require('openmw.input')

local gutils = require(mp..'scripts/gutils')
local PhysicsObject = require(mp..'PhysicsObject')
local PhysicsUtils = require(mp..'PhysicsUtilities')
local EventsManager = require(mp..'scripts/events_manager')

local physicsTypes = {types.Armor, types.Potion, types.Book, types.Item, types.Lockpick, types.Miscellaneous, types.Weapon, types.Apparatus, types.Clothing, types.Ingredient}
local physicsObjects = {}

local gridSize = 150 -- Size of each grid cell
local grid = {} -- Table to store objects in grid cells

--[[ local interface = {
    onCollision = EventsManager:new(),
    onIntersection = EventsManager:new()
} ]]

--[[ local function getGridCell(position)
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
end ]]

--[[ local function Physicify(obj, props)
    -- "obj" can be either a gameobject or a recordId (string)
    if not obj then error("No gameobject or recordId was provided to Physicify") end
    local object = nil
    local recordId = nil
    local id
    
    if type(obj) == "string" then recordId = obj else object = obj end
    if object then id = obj.id else id = gutils.genSequentialId() end
    
    if physicsObjects[id] then return physicsObjects[id] end
    
    if recordId then
        if not props.position then
            error("Not all required properties (2nd function argument) were provided for spawning the physics object. Required properties are: position")
        end
        props.awaitingSpawn = true
        core.sendGlobalEvent("SpawnObject", {
            source = omwself,
            requestId = id,
            recordId = recordId,
            position = props.position,
            cell = props.cell
        })
    end
    
    props.id = id
    local physObject = PhysicsObject:new(object, props)
    physObject.onCollision:addEventHandler(function(...)
        interface.onCollision:emit(physObject, ...)
    end)
    physObject.onIntersection:addEventHandler(function(...)
        interface.onIntersection:emit(physObject, ...)
    end)

    physicsObjects[id] = physObject
    return physObject
end
interface.Physicify = Physicify ]]

--[[ local function getPhysicsObject(obj)
    return physicsObjects[obj.id]
end
interface.getPhysicsObject = getPhysicsObject ]]

local lastNearbyItemsAmount = 0
local function autoPhisicifyNearby()
    if lastNearbyItemsAmount == #nearby.items then return end
    for _, obj in ipairs(nearby.items) do
        if gutils.foundInList(physicsTypes, obj.type) and obj:isValid() then
            core.sendGlobalEvent("Physicify", {
                object = obj,
                properties = { mass = 1, drag = 0.1, bounce = 0.5, realignWhenRested = true }
            })
            --Physicify(obj, { mass = 1, drag = 0.1, bounce = 0.5, realignWhenRested = true })
        end
    end
    lastNearbyItemsAmount = #nearby.items
end


local function onUpdate(dt)
    
    
    
    -- Find and setup hardcoded physics objects
    autoPhisicifyNearby()

    

    --[[ -- Clear the grid at the start of each update
    clearGrid()

    -- Update all physics objects and populate the grid
    for id, physObj in pairs(physicsObjects) do
        if physObj.object and physObj.object:isValid() then
            --print("Updating",physObj.object,id)
            physObj:update(dt)
            if not physObj.ignorePhysObjectCollisions then addToGrid(physObj) end
        elseif not physObj.awaitingSpawn then
            print("Removing invalid object:", id)
            physicsObjects[id] = nil -- Remove invalid objects
        end
    end   

    -- Check collisions within the grid
    checkCollisionsInGrid()

    -- Check if object should go to sleep
    for id, physObj in pairs(physicsObjects) do
        physObj:trySleep(dt)
    end ]]

    -- Utilities update loop
    PhysicsUtils.HoldGrabbedObject(dt, input.isShiftPressed())
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
            -- if key.symbol == 'v' then
            --     local obj = PhysicsUtils.GetLookAtObject(300)
            --     if obj then Physicify(obj.recordId, { position = obj.position}) end
            -- end
         end,
         onKeyRelease = function(key)
            if key.symbol == 'x' then
                PhysicsUtils.DropObject()
            end
         end,
    },
   --[[  eventHandlers = {
        ObjectSpawned = function(e)
            --print("ObjectSpawned frame", frame)
            print("ObjectSpawned event received for object: " .. e.object.recordId .. "Object" .. e.object.id)
            if not physicsObjects[e.requestId] then error("ObjectSpawned: object with specified requestId doesnt exist "..e.requestId) end
            local physObject = physicsObjects[e.requestId]
            physObject.object = e.object
            physObject.id = e.object.id
            physObject.awaitingSpawn = nil
            physicsObjects[e.object.id] = physObject
            physicsObjects[e.requestId] = nil -- Remove the requestId from the table after spawning
            core.sendGlobalEvent("ObjectSpawnedAck", { requestId = e.requestId })
        end,
    },
    interfaceName = "DumbPhysics",
    interface = interface, ]]
    
}
