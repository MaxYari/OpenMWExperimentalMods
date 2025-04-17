local mp = 'scripts/MaxYari/experiments/'

local core = require('openmw.core')
local world = require('openmw.world')
local util = require('openmw.util')
local gutils = require(mp..'scripts/gutils')
local PhysicsObject = require(mp..'PhysicsObject')
local vfs = require('openmw.vfs')

-- local physicsObjectScript = mp.."PhysicsEngineLocal.lua"

local physicsSfxMasterVolume = 2

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


-- Extract clean name from the file path
local function getCleanName(filePath)
    local filename = filePath:match("([^/\\]+)$") -- Extract the filename from the path    
    local cleanName = filename:gsub("%.wav$", "") -- Remove the .nif extension
    cleanName = cleanName:gsub("__.+$", "")
    return cleanName
end


local MaterialSounds = {}
local function buildSoundsMap()
    for filePath in vfs.pathsWithPrefix("sounds/physics") do
        if filePath:find("%.wav$") then
            local materialType = getCleanName(filePath)
            print("Material type from sound file:", materialType)
            
            if not MaterialSounds[materialType] then
                MaterialSounds[materialType] = {}
            end

            table.insert(MaterialSounds[materialType], filePath)
        end
    end
    print("Sounds map built")
end
-- Initialize debris map at startup
buildSoundsMap()

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
    if object and object:isValid() and object.count > 0 and object.cell ~= nil then
        object:teleport(object.cell, position, { rotation = rotation })
        if not physObject.ignorePhysObjectCollisions then addToGrid(physObject) end
        --if physObject.ignorePhysObjectCollisions then print("Ignoring collisions for",object.recordId) end
    end
end

local function playMaterialSound(data)
    print(data.material)
    if not MaterialSounds[data.material] then return end
    local soundFile = MaterialSounds[data.material][math.random(#MaterialSounds[data.material])]
    print("Playing sound", data.params.volume*physicsSfxMasterVolume, soundFile)
    core.sound.playSoundFile3d(soundFile, data.source, data.params)
end

return {
    engineHandlers = {
        onUpdate = onUpdate
    },
    eventHandlers = {
        LuaPhysics_UpdateVisPos = handleUpdateVisPos,
        SpawnImpactEffect = function (opts)
            world.players[1]:sendEvent("impactSpawnEffect", opts)
        end,
       --[[  Physicify = function(e)
            print("Global received phisicify request for object",e.object," at frame",frame)
            if e.object:hasScript(physicsObjectScript) then return end
            e.object:addScript(physicsObjectScript, e.properties)
        end, ]]
        PlayPhysicsMaterialSound = function(data)
            playMaterialSound(data)
        end
    },
    interfaceName = "LuaPhysics",
    interface = {
        version = 1.0,
        playMaterialSound = playMaterialSound,
    },
}
