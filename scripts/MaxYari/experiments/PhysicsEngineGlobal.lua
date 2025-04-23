local mp = 'scripts/MaxYari/experiments/'

local world = require('openmw.world')

local PhysicsObject = require(mp..'PhysicsObject')
local PhysSoundSystem = require(mp..'scripts/physics_sound_system')
local PhysMatSystem = require(mp..'scripts/physics_material_system')
local PhysAiSystem = require(mp..'scripts/physics_ai_system')
local D = require(mp..'scripts/physics_defs')


-- local physicsObjectScript = mp.."PhysicsEngineLocal.lua"
-- if true then return end

-- Defines -----------------
local frame = 0
PhysSoundSystem.masterVolume = 2



-- Grid collision system for dynamic objects ----------------------------------------------
-------------------------------------------------------------------------------------------
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
                    local culprit = physObj1.culprit or physObj2.culprit
                    physObj1.object:sendEvent(D.e.CollidingWithPhysObj, { other = physObj2, culprit = culprit })
                    physObj2.object:sendEvent(D.e.CollidingWithPhysObj, { other = physObj1, culprit = culprit })
                end
                ::jcontinue::
            end            
        end
    end
end
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------



-- Moving objects and checking grid-optimised collisions with other physics objects -------------------
---------------------------------------------------------------------------------------------------------
local function handleUpdateVisPos(physObject)
    -- print("Global received teleport request from",d.object,"At frame",frame)
    local object = physObject.object
    
    local position = physObject.position - physObject.rotation:apply(physObject.origin)
    local rotation = physObject.rotation
    
    if object and object:isValid() and object.count > 0 and object.cell ~= nil then
        object:teleport(object.cell, position, { rotation = rotation })
        if not physObject.ignorePhysObjectCollisions then addToGrid(physObject) end        
    end
end







-- onUpdate ----- 
-----------------
local function onUpdate(dt)
    --print("Global Onupdate frame", frame)
    
    frame = frame + 1

    if not PhysMatSystem.initialized then
        PhysMatSystem.init()
    end

    checkCollisionsInGrid()
    clearGrid()

    PhysAiSystem.update()
end



return {
    engineHandlers = {
        onUpdate = onUpdate,        
    },
    eventHandlers = {
        [D.e.UpdateVisPos] = handleUpdateVisPos,        
        [D.e.SpawnCollilsionEffects] = function (data)
            PhysMatSystem.spawnCollilsionEffects(data)
        end,
        [D.e.SpawnMaterialEffect] = function (data)
            PhysMatSystem.spawnMaterialEffect(data.material, data.position)
        end,
        [D.e.PlayCollisionSounds] = function(data)
            PhysSoundSystem.playCollisionSounds(data)
        end,
        [D.e.PlayCrashSound] = function(data)
            PhysSoundSystem.playCrashSound(data)            
        end,
        [D.e.PlayWaterSplashSound] = function(data)
            PhysSoundSystem.playWaterSplashSound(data)            
        end,
        [D.e.WhatIsMyPhysicsData] = function(data)
            local mat = PhysMatSystem.getMaterialFromObject(data.object)
            data.object:sendEvent(D.e.SetMaterial, { material = mat})
            data.object:sendEvent(D.e.SetPhysicsProperties, { player = world.players[1]})
        end,
        [D.e.ObjectFenagled] = PhysAiSystem.onObjectFenagled,
        [D.e.DetectCulpritResult] = PhysAiSystem.onDetectCulpritResult
    },
    interfaceName = "LuaPhysics",
    interface = {
        version = 1.0,
        playCrashSound = PhysSoundSystem.playCrashSound,
        getMaterialFromObject = PhysMatSystem.getMaterialFromObject,
    },
}
