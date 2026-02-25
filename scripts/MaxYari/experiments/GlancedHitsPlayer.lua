local mp = "scripts/MaxYari/experiments/"

local camera = require("openmw.camera")
local I = require("openmw.interfaces")
local nearby = require("openmw.nearby")
local omwself = require("openmw.self")
local util = require("openmw.util")
local async = require("openmw.async")
local core = require("openmw.core")
local animation = require("openmw.animation")

local gutils = require(mp .. 'scripts/gutils')


local CenterVector = util.vector2(0.5, 0.5)

local hitTime = 0
local hitStopTime = 0.15

local lastAttackGroupname = nil
local attackAnimTime = nil
local attackAnimOpts = options
I.AnimationController.addPlayBlendedAnimationHandler(function(groupname, options)
    if not options.startKey then return end
    if gutils.isAttackType(options.startKey) then
        print("Playing attack animation", groupname, options.startKey)
        lastAttackGroupname = groupname
        attackAnimTime = animation.getCompletion(omwself, groupname)
        attackAnimOpts = options
    end
end)

local function onGetHitPoint(e)
    print("Gimme hit point", e.sender.recordId)

    hitTime = core.getRealTime()

    -- Get camera direction and position
    local lookDir = camera.viewportToWorldVector(CenterVector)
    local camPos = camera.getPosition()
    local activationDist = camera.getThirdPersonDistance() + 120

    local rayStart = camPos
    lookDir = lookDir:normalize()
    local rayEnd = camPos + lookDir * activationDist 
    
    -- Cast regular ray first to check for collision with sender
    local regularRayResult = nearby.castRay(rayStart, rayEnd,
        { ignore = omwself, collisionType = nearby.COLLISION_TYPE.Actor })

    local rayResult = {}
    local isOnSurface = false
    if regularRayResult.hitObject == e.sender then
        rayResult = regularRayResult
        isOnSurface = false
    end

    -- Cast rendering ray from determined origin to target position
    local renderingRayCallback = async:callback(function(renderingResult)
        print("Rendering res",renderingResult.hitObject, renderingResult.hitPos, renderingResult.hitNormal)        
        if renderingResult.hitObject == e.sender then        
            rayResult = renderingResult
            isOnSurface = true 
        end 
       
        e.sender:sendEvent("GlancedHits_MyHitPoint", {
            sender = omwself, 
            hitObject = rayResult.hitObject, 
            hitPos = rayResult.hitPos, 
            hitNormal = rayResult.hitNormal,
            isOnSurface = isOnSurface,
            attackSuccessful = e.attackSuccessful
        })
    end)
    
    nearby.asyncCastRenderingRay(renderingRayCallback, rayStart, rayEnd,
        { ignore = omwself, collisionType = nearby.COLLISION_TYPE.Actor })
end

local function onUpdate(dt) 
    if dt <= 0 then return end
    local now = core.getRealTime()
    local timeSinceHit = now - hitTime
    --[[ if timeSinceHit <= hitStopTime then
        animation.skipAnimationThisFrame(omwself)
    end ]]

    if lastAttackGroupname and animation.isPlaying(omwself, lastAttackGroupname) and timeSinceHit <= hitStopTime then
        animation.cancel(omwself, lastAttackGroupname)
        attackAnimOpts.startPoint = attackAnimTime
        I.AnimationController.playBlendedAnimation(lastAttackGroupname, attackAnimOpts)
    end
end

return {    
    engineHandlers = {
       onUpdate = onUpdate
    },
    eventHandlers = {
        GlancedHits_GetHitPoint = onGetHitPoint
    }
}