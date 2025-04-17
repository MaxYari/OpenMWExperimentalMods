-- OpenMW Lua Physics - Authors: Maksim Eremenko, GPT-4o (Copilot)

local mp = 'scripts/MaxYari/experiments/'

local core = require('openmw.core')
local util = require('openmw.util')
local types = require('openmw.types')
local nearby = require('openmw.nearby')
local vfs = require('openmw.vfs')
local omwself = require('openmw.self')
local interfaces = require('openmw.interfaces')

local gutils = require(mp..'scripts/gutils')


local PhysicsObject = require(mp..'PhysicsObject')



if omwself.recordId ~= "p_restore_health_s" then return end

local eventHandlersAttached = false

local function onCollision(hitResult)
    local physObject = interfaces.LuaPhysics.physicsObject
    if not omwself:isActive() then
        physObject.onCollision:removeEventHandler(onCollision)
        physObject.onIntersection:removeEventHandler(onCollision)
        return
    end

    print(omwself.recordId, "Collided! At", hitResult.hitPos)
    if hitResult.hitObject then print("With", hitResult.hitObject.recordId) end

    if physObject.velocity:length() > 400 then
        print("Requesting fracture!")
        core.sendGlobalEvent("FractureMe", {
            object = omwself,
            hitObject = hitResult.hitObject,
            baseImpulse = physObject.velocity * 1.2
        })
    end
end

local function onUpdate(dt)
    if interfaces.LuaPhysics and not eventHandlersAttached then
        local physObject = interfaces.LuaPhysics.physicsObject
        physObject.onCollision:addEventHandler(onCollision)
        physObject.onIntersection:addEventHandler(onCollision)
        eventHandlersAttached = true
    end
end

return {
    engineHandlers = {        
        onUpdate = onUpdate        
    }
    
}







