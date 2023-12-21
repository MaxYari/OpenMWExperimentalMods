
local input = require('openmw.input')

local self = require('openmw.self')
local util = require('openmw.util')
local core = require('openmw.core')
local types = require('openmw.types')
local camera = require('openmw.camera')

local resetingInertia = 0;
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

   if resetingInertia == 1 then
      self:setActorFlying(true)
      resetingInertia = 2
   elseif resetingInertia == 2 then
      self:setActorFlying(false)
      resetingInertia = 0
   end
end

local function AirJump()
   if not types.Actor.isOnGround(self.object) then
      print('Air jumping')



      resetingInertia = 1


      local direction = camera.viewportToWorldVector(util.vector2(0.5, 0.5)):normalize()
      airJumpVelocity = direction * airJumpStrength;
   end
end

return {
   engineHandlers = {
      onPhysicsUpdate = function(dt)
         print("Physics update")
         TestActorMovement(dt)
      end,
      onInputAction = function(action)
         if action == input.ACTION.Jump then
            AirJump()
         end
      end,
   },
}
