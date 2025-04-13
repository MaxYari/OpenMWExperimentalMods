-- OpenMW Lua Physics - Authors: Maksim Eremenko, GPT-4o (Copilot)

local mp = 'scripts/MaxYari/experiments/'

local core = require('openmw.core')
local util = require('openmw.util')
local types = require('openmw.types')
local nearby = require('openmw.nearby')
local omwself = require('openmw.self')
local gutils = require(mp..'scripts/gutils')
local EventsManager = require(mp..'scripts/events_manager')
local PhysicsObject = require(mp..'PhysicsObject')

local Gravity = util.vector3(0, 0, -9.8*72)
local SleepSpeed = 5
local SleepTime = 1
local RotationalDamping = 0.5 -- Damping factor for angular velocity
local ImpactTorqueMult = 0.5 -- Multiplier for angular velocity impact
local MaxAngularVelocity = 5000 -- Optional: Maximum angular velocity limit

-- if omwself.recordId ~= "p_restore_health_s" then return end


print("Script global scope")

local frame = 0
local physicsObject = PhysicsObject:new(omwself, { mass = 1, drag = 0.1, bounce = 0.5, isSleeping = true }) 
local interface = {version=1.0, physicsObject=physicsObject}

local function onInit(props)
    if props then
        print("Received on init props",gutils.tableToString(props))
    end
end

local function onUpdate(dt)
    if not physicsObject then
        print("No physics object for ",omwself.recordId,"WTH")
        return 
    end
    --print("Physics Object Update frame: ", frame)
    physicsObject:update(dt)
    physicsObject:trySleep(dt)

    frame = frame + 1
end

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
    interface = interface,
    
}







