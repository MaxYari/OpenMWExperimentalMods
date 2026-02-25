local I = require("openmw.interfaces")
local types = require("openmw.types")
local omwself = require("openmw.self")


local physObject = I.LuaPhysics.physicsObject

local lastHeldActor = nil
local canDamage = false
local bounce = 0

physObject.onCollision:addEventHandler(function(hitResult)
    print(omwself,"Collided with",hitResult.hitObject)
    if canDamage and hitResult.hitObject and types.Actor.objectIsInstance(hitResult.hitObject) and physObject.culprit and physObject.culprit == lastHeldActor then
        -- We are on!
        print("AND ITS GONNA HURT")
        local attackInfo = {
            attacker = physObject.culptir,
            damage = {health = 10},
            hitPos = hitResult.hitPos,
            strength = 1,
            successful = true
        }
        hitResult.hitObject:sendEvent("MightyThrow_GetHit", attackInfo)
        canDamage = false
    end

    bounce = bounce + 1
    if bounce >= 2 then
        canDamage = false
    end
end)

return {
    eventHandlers = {
        LuaPhysics_HeldBy = function(e)
            if e.actor then
                lastHeldActor = e.actor                
            end
        end,
        LuaPhysics_ApplyImpulse = function(e)
            print("Impulse applied")
            canDamage = true
            bounce = 0
        end
    }    
}