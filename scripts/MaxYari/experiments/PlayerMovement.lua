
local input = require('openmw.input')

local self = require('openmw.self')
local util = require('openmw.util')
local core = require('openmw.core')
local types = require('openmw.types')
local camera = require('openmw.camera')

local resetingInertia = false;
local airJumpStrength = 500;
local airJumpVelocity = util.vector3(0, 0, 0);


local function TestActorMovement(dt)
   local now = core.getRealTime()

   local params = {}
   params.maxWalkableSlope = 90;
   params.stepSizeDown = 200;
   params.stepSizeUp = 200;
   self:setActorCollisionParams(params)





   if airJumpVelocity:length() > 0 and not types.Actor.isOnGround(self.object) then
      self:setActorWorldVelocity(airJumpVelocity)
   else
      airJumpVelocity = util.vector3(0, 0, 0)
   end

   if resetingInertia then
      self:setActorFlying(false)
   end
end

local function AirJump()
   if not types.Actor.isOnGround(self.object) then
      print('Air jumping')



      resetingInertia = true
      self:setActorFlying(true)


      local direction = camera.viewportToWorldVector(util.vector2(0.5, 0.5)):normalize()
      airJumpVelocity = direction * airJumpStrength;
   end
end

return {
   engineHandlers = {
      onUpdate = function(dt)
         TestActorMovement(dt)
      end,
      onInputAction = function(action)
         if action == input.ACTION.Jump then
            AirJump()
         end
      end,
   },
}
