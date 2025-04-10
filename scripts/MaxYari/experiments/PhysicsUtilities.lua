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
local it = require('openmw.interfaces')

local module = {}

local grabDistance = 200;
local maxDragImpulse = 300;
local throwImpulse = 500.0;

local activeObject;
local holdDistance;
local holdOffset;

local function GrabObject()
    local position = camera.getPosition()
    local direction = camera.viewportToWorldVector(util.vector2(0.5, 0.5)):normalize()
    local pickupDistance = grabDistance
    local castResult = nearby.castRenderingRay(position, position + direction * pickupDistance)
    local object = castResult.hitObject
 
    if not object then return end
    local physObject = it.DumbPhysics.getPhysicsObject(object)
    if not physObject then return end
 
    activeObject = physObject
    holdDistance = (castResult.hitPos - position):length()
    holdOffset = castResult.hitPos - activeObject.position
 
    ui.showMessage("Grabbing " .. activeObject.object.recordId)
 
    activeObject.object:sendEvent('GrabbedBy', { actor = omwself.object });
end
module.GrabObject = GrabObject

local function DropObject()
    activeObject = nil
end
module.DropObject = DropObject

local function PushObjects()
    local position = camera.getPosition()
    local direction = camera.viewportToWorldVector(util.vector2(0.5, 0.5)):normalize()
    local cylinderRadius = 100 -- Radius of the cylinder
    local cylinderLength = 500 -- Length of the cylinder
    local impulseStrength = 500

    -- Iterate through all nearby items
    for _, object in ipairs(nearby.items) do
        local physObject = it.DumbPhysics.getPhysicsObject(object)
        if physObject and object:isValid() then
            -- Calculate the vector from the camera position to the object
            local toObject = object.position - position

            -- Project the vector onto the camera direction
            local projectionLength = toObject:dot(direction)
            if projectionLength > 0 and projectionLength <= cylinderLength then
                -- Calculate the perpendicular distance from the object to the cylinder axis
                local perpendicularDistance = (toObject - direction * projectionLength):length()
                if perpendicularDistance <= cylinderRadius then
                    -- Apply impulse to the object
                    local randomDirection = gutils.randomDirection()
                    local impulse = direction * impulseStrength + randomDirection * impulseStrength * 0.25
                    physObject:applyImpulse(impulse)
                end
            end
        end
    end
    ui.showMessage("N'wah!")
end
module.PushObjects = PushObjects

local function ExplodeObjects()
    local position = camera.getPosition()
    local direction = camera.viewportToWorldVector(util.vector2(0.5, 0.5)):normalize()
    local rayLength = 500 -- Length of the ray
    local explosionRadius = 200 -- Radius of the explosion
    local explosionForce = 1000 -- Strength of the explosion

    -- Perform a raycast to find the explosion center
    local rayEnd = position + direction * rayLength
    local castResult = nearby.castRenderingRay(position, rayEnd)

    -- Determine the explosion center
    local explosionCenter = castResult.hit and castResult.hitPos or rayEnd

    -- Iterate through all nearby items
    for _, object in ipairs(nearby.items) do
        local physObject = it.DumbPhysics.getPhysicsObject(object)
        if physObject and object:isValid() then
            -- Calculate the distance from the object to the explosion center
            local toObject = object.position - explosionCenter
            local distance = toObject:length()

            if distance <= explosionRadius then
                -- Calculate the explosion impulse
                local directionAway = toObject:normalize()
                local impulse = directionAway * (explosionForce * (1 - distance / explosionRadius))
                physObject:applyImpulse(impulse)
            end
        end
    end

    ui.showMessage("Explode!")
end
module.ExplodeObjects = ExplodeObjects

local function DupeObject()
    local position = camera.getPosition()
    local direction = camera.viewportToWorldVector(util.vector2(0.5, 0.5)):normalize()
    local pickupDistance = grabDistance
    local castResult = nearby.castRenderingRay(position, position + direction * pickupDistance)
    local object = castResult.hitObject
 
    if not object then return end
 
    ui.showMessage("Duping " .. object.recordId)

    local randomPosRange = 50
    local randomPosDelta = util.vector3(math.random(-randomPosRange, randomPosRange), math.random(-randomPosRange, randomPosRange), 0)
 
    core.sendGlobalEvent("SpawnObject", {
        recordId = object.recordId,
        position = object.position + randomPosDelta,
        cell = object.cell.name
    })
end
module.DupeObject = DupeObject

local function HoldGrabbedObject(dt)
    if not activeObject then return end

    local position = camera.getPosition()
    local direction = camera.viewportToWorldVector(util.vector2(0.5, 0.5)):normalize()
    local objectHoldPos = position + direction*holdDistance;

    
    local currentVelocity = activeObject.velocity;
    local pushVector = objectHoldPos - activeObject.position - currentVelocity/4;
    
    if pushVector:length() > maxDragImpulse then
        pushVector = pushVector:normalize() * maxDragImpulse
    end
    
    -- Note: offset will not work with this setup, we need to calculate push vector as a difference between current hold offset position (transformed) and screen center
    -- Also: impulse offset uses local object space! But its not rotated? Just based on center of mass. So i need to save that offset together with initial rotation and then
    -- each frame unrotate the offset and rotate it to the new rotation?
    -- No i believe its applied to a non-rotated version, so it is on object local space. So i need to save it and to apply it properly also transform it by the object transform? Need to test this
    -- No i thinks its actually NOT rotated, seems like all apply things are happening in a world space.
    activeObject:applyImpulse(pushVector)

    if input.isMouseButtonPressed(1) then
        -- Calculating throw strength
        local strength = types.Actor.stats.attributes.strength(omwself);
        throwImpulse = util.clamp(util.remap(strength.modified, 40, 100, 500, 1500),750,1500);
        print("Calculated throwImpulse " .. throwImpulse);

        -- Launching!
        activeObject:applyImpulse(direction*throwImpulse)
        DropObject()
    end
end
module.HoldGrabbedObject = HoldGrabbedObject

return module



