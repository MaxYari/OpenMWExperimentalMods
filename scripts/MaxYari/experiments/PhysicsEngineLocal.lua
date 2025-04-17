-- OpenMW Lua Physics - Authors: Maksim Eremenko, GPT-4o (Copilot)

local mp = 'scripts/MaxYari/experiments/'

local core = require('openmw.core')
local util = require('openmw.util')
local types = require('openmw.types')
local nearby = require('openmw.nearby')
local omwself = require('openmw.self')
local vfs = require('openmw.vfs')
local I = require('openmw.interfaces')

local gutils = require(mp..'scripts/gutils')
local EventsManager = require(mp..'scripts/events_manager')
local PhysicsObject = require(mp..'PhysicsObject')
local MatFromObj = require(mp..'scripts/mat_from_object')

local Gravity = util.vector3(0, 0, -9.8*72)
local SleepSpeed = 5
local SleepTime = 1
local RotationalDamping = 0.5 -- Damping factor for angular velocity
local ImpactTorqueMult = 0.5 -- Multiplier for angular velocity impact
local MaxAngularVelocity = 5000 -- Optional: Maximum angular velocity limit

-- if omwself.recordId ~= "p_restore_health_s" then return end
-- if omwself.recordId ~= "food_kwama_egg_02" then return end
-- TO DO: save serialised state of the physics object in onsave





local function objectToMaterial(object)
    if not object then return nil end
    --local type = objectTypeToMaterialMap[object.type]
    local type = MatFromObj.getMaterialByObject(object)    
    if type then type = string.lower(type) end
    return type
end



-- Main stuff ----------------------------------------------
------------------------------------------------------------
local frame = 0
local cell = omwself.cell
local physicsObject = PhysicsObject:new(omwself, { mass = 1, drag = 0.1, bounce = 0.5, isSleeping = true })

local soundPause = 0.2;
local lastSoundTime = 0.0;
local minSoundSpeed = 50;

local function tryPlayCollisionSounds(hitResult)
    local now = core.getRealTime()
    local velocity = physicsObject.velocity
    local volume = 0
    if velocity:length() >= minSoundSpeed then
        volume = util.remap(velocity:length(), minSoundSpeed, 600, 0.33, 1)
        -- print("Volume:", volume)
    end
    
    local pitch = 0.8 + math.random() * 0.2
    local params = { volume = volume, pitch = pitch, loop = false }

    if volume > 0 and now - lastSoundTime > soundPause then
        -- Determine materials
        local selfMaterial = objectToMaterial(omwself)
        local otherMaterial = objectToMaterial(hitResult.hitObject)
        -- print(hitResult.hitObject, otherMaterial)
        if not hitResult.hitObject then otherMaterial = "dirt" end
       
        -- Play sound for hitResult.hitObject material
        if otherMaterial then
            core.sendGlobalEvent("PlayPhysicsMaterialSound", {
                source = omwself,
                material = otherMaterial,                
                params = params
            })
        end

        -- Play sound for omwself material
        if selfMaterial then
            core.sendGlobalEvent("PlayPhysicsMaterialSound", {
                source = omwself,
                material = selfMaterial,                
                params = params
            })
        end

        -- Spawn visual effect
        core.sendGlobalEvent("SpawnImpactEffect", {
            material = otherMaterial,
            hitPos = hitResult.hitPos
        })

        lastSoundTime = now
    end
end

physicsObject.onCollision:addEventHandler(function(hitResult)    
    --print("Collision detected!",physicsObject.velocity:length(), physicsObject.angularVelocity:length())
    tryPlayCollisionSounds(hitResult)
end)

local function onInit(props)
    if props then
        print("Received on init props",gutils.tableToString(props))
    end
end

local function onUpdate(dt)
    if not omwself:isActive() then return end
    if cell ~= omwself.cell then
        cell = omwself.cell
        if omwself.cell == nil and cell ~= nil then physicsObject:reInit() end
    end
    if omwself.cell == nil then         
        return
    end    
    --print("Physics Object Update frame: ", frame)
    
    physicsObject:update(dt)
    physicsObject:trySleep(dt)

    frame = frame + 1
end

onUpdate(0)

return {
    engineHandlers = {
        onInit = onInit,
        onUpdate = onUpdate   
    },
    eventHandlers = {
        MoveTo = function(e)
            local currentVelocity = physicsObject.velocity;
            local pushVector = e.position - physicsObject.position - currentVelocity/4;
    
            if pushVector:length() > e.maxImpulse then
                pushVector = pushVector:normalize() * e.maxImpulse
            end

            physicsObject:applyImpulse(pushVector)
        end,
        ApplyImpulse = function(e)
            physicsObject:applyImpulse(e.impulse)
        end,
        SetPhysicsProperties = function(props)
            --print("Received physics properties",gutils.tableToString(props))
            gutils.shallowMergeTables(physicsObject, props)
        end,
        SetPositionUnadjusted = function(e)
            physicsObject:setPositionUnadjusted(e.position)
        end,
        CollidingWithPhysObj = function(e)
            --print("Received phys object collide event",e.other.object.recordId)
            physicsObject:handlePhysObjectCollision(e.other)
        end,
    },
    interfaceName = "LuaPhysics",
    interface = {version=1.0, physicsObject=physicsObject}
    
}







