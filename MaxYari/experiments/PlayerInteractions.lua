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

   activeObject = object
   holdDistance = (castResult.hitPos - position):length()
   holdOffset = castResult.hitPos - activeObject.rigidBodyPosition





   ui.showMessage("Grabbing " .. activeObject.recordId)





   activeObject:sendEvent('GrabbedBy', { actor = self.object });

end

local function DropObject()
   activeObject = nil
end

local function HoldingActiveObject(dt)
   if not activeObject then return end

   local position = camera.getPosition()
   local direction = camera.viewportToWorldVector(util.vector2(0.5, 0.5)):normalize()
   local objectHoldPos = position + direction * holdDistance;


   local currentVelocity = activeObject:getRigidBodyVelocity(util.vector3(0, 0, 0));
   local pushVector = objectHoldPos - activeObject.rigidBodyPosition - currentVelocity / 4;

   if pushVector:length() > maxDragImpulse then
      pushVector = pushVector:normalize() * maxDragImpulse
   end






   activeObject:applyImpulse(pushVector, util.vector3(0, 0, 0))

   if input.isMouseButtonPressed(1) then

      local strength = types.Actor.stats.attributes.strength(self.object);
      throwImpulse = util.clamp(util.remap(strength.modified, 40, 100, 750, 1500), 750, 1500);
      print("Calculated throwImpulse " .. throwImpulse);


      activeObject:applyImpulse(direction * throwImpulse, util.vector3(0, 0, 0))
      DropObject()
   end
end



return {
   engineHandlers = {
      onUpdate = function(dt)
         HoldingActiveObject(dt)
      end,
      onKeyPress = function(key)
         if key.symbol == 'x' then
            GrabObject()
         end
      end,
      onKeyRelease = function(key)
         if key.symbol == 'x' then
            DropObject()
         end
      end,
   },
}
