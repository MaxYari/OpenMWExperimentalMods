local ui = require('openmw.ui')
local input = require('openmw.input')
local nearby = require('openmw.nearby')
local camera = require('openmw.camera')
local self = require('openmw.self')
local util = require('openmw.util')
local core = require('openmw.core')
local types = require('openmw.types')

local grabDistance = 200;
local maxDragImpulse = 300;
local throwImpulse = 10.0;

local activeObject : core.GameObject;
local holdDistance : number;
local holdOffset : util.Vector3;

local function GrabObject()
    local position = camera.getPosition()
    local direction = camera.viewportToWorldVector(util.vector2(0.5, 0.5)):normalize()
    local pickupDistance = grabDistance
    local castResult = nearby.castRenderingRay(position, position + direction * pickupDistance)
    local object = castResult.hitObject
    
    if not object then return end    
    
    activeObject = object
    holdDistance = (castResult.hitPos - position):length()
    holdOffset = castResult.hitPos - activeObject.rigidBodyPosition
    --print("Hold distance")
    --print(holdDistance)
    --print("Hold offset")
    --print(holdOffset)

    ui.showMessage("Grabbing " .. activeObject.recordId)

    --activeObject.applyImpulse(activeObject, direction*25, holdOffset)
    --print("Rigidbody position " .. tostring(activeObject.rigidBodyPosition));
    --print("Rigidbody rotation " .. tostring(activeObject.rigidBodyRotation));

    activeObject:sendEvent('GrabbedBy', {actor=self.object});
    
end

local function DropObject()
    activeObject = nil
end

local function HoldingActiveObject(dt: number)
    if not activeObject then return end

    local position = camera.getPosition()
    local direction = camera.viewportToWorldVector(util.vector2(0.5, 0.5)):normalize()
    local objectHoldPos = position + direction*holdDistance;

    
    local currentVelocity = activeObject:getRigidBodyVelocity(util.vector3(0,0,0));
    local pushVector = objectHoldPos - activeObject.rigidBodyPosition - currentVelocity/4;
    
    if pushVector:length() > maxDragImpulse then
        pushVector = pushVector:normalize() * maxDragImpulse
    end
    
    -- Note: offset will not work with this setup, we need to calculate push vector as a difference between current hold offset position (transformed) and screen center
    -- Also: impulse offset uses local object space! But its not rotated? Just based on center of mass. So i need to save that offset together with initial rotation and then
    -- each frame unrotate the offset and rotate it to the new rotation?
    -- No i believe its applied to a non-rotated version, so it is on object local space. So i need to save it and to apply it properly also transform it by the object transform? Need to test this
    -- No i thinks its actually NOT rotated, seems like all apply things are happening in a world space.
    activeObject:applyImpulse(pushVector, util.vector3(0,0,0))

    if input.isMouseButtonPressed(1) then
        -- Calculating throw strength
        local strength = types.Actor.stats.attributes.strength(self.object);
        throwImpulse = util.clamp(util.remap(strength.modified, 40, 100, 500, 1500),750,1500);
        print("Calculated throwImpulse " .. throwImpulse);

        -- Launching!
        activeObject:applyImpulse(direction*throwImpulse, util.vector3(0,0,0))
        DropObject()
    end
end



return {
    engineHandlers = {
        onUpdate = function(dt: number)
            HoldingActiveObject(dt)
        end,
        onKeyPress = function(key: input.KeyboardEvent)
            if key.symbol == 'x' then
                GrabObject()
            end
        end,
        onKeyRelease = function(key: input.KeyboardEvent)
            if key.symbol == 'x' then
                DropObject()
            end
        end
    }
}