local camera = require("openmw.camera")
local nearby = require("openmw.nearby")
local omwself = require("openmw.self")
local util = require("openmw.util")
local async = require("openmw.async")


local function onUpdate(dt) end

local CenterVector = util.vector2(0.5, 0.5)

local function onGetHitPoint(e)
    print("Gimme hit point", e.sender.recordId)

    -- Get camera direction and position
    local lookDir = camera.viewportToWorldVector(CenterVector)
    local camPos = camera.getPosition()
    local activationDist = camera.getThirdPersonDistance() + 120

    -- Cast regular ray first to check for collision with sender
    local regularRayResult = nearby.castRay(camPos, camPos + lookDir * activationDist,
        { ignore = omwself, collisionType = nearby.COLLISION_TYPE.Actor })

    -- Determine origin for second ray: collision point if sender was hit, otherwise camera position
    local secondRayOrigin = camPos
    if regularRayResult.hitObject and regularRayResult.hitObject.id == e.sender.id then
        secondRayOrigin = regularRayResult.hitPos
        print("Regular ray hit object",regularRayResult.hitObject.recordId)
        e.sender:sendEvent("GlancedHits_MyHitPoint", {sender = omwself, hitObject = regularRayResult.hitObject, hitPos = regularRayResult.hitPos})
    end

    -- Get target position (center of sender's bounding box)
    local boundingBox = e.sender:getBoundingBox()
    local targetPos = boundingBox.center

    -- Cast rendering ray from determined origin to target position
    local renderingRayCallback = async:callback(function(renderingResult)
        print("Rendering res",renderingResult.hitObject, renderingResult.hitPos)
        if renderingResult.hitObject then
            local toPos = renderingResult.hitPos - secondRayOrigin
            local dir = toPos:normalize()
            local hitPos = secondRayOrigin + dir * (toPos:length() - 30)
            e.sender:sendEvent("GlancedHits_MyHitPoint", {sender = omwself, hitObject = renderingResult.hitObject, hitPos = hitPos})
        end
    end)

    print("Emitting rendering ray from",secondRayOrigin,"to",targetPos)
    nearby.asyncCastRenderingRay(renderingRayCallback, secondRayOrigin, targetPos,
        { ignore = omwself, collisionType = nearby.COLLISION_TYPE.Actor })
end

return {    
    engineHandlers = {
       onUpdate = onUpdate
    },
    eventHandlers = {
        GlancedHits_GetHitPoint = onGetHitPoint
    }
}