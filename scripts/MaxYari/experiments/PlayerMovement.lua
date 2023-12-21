
local input = require('openmw.input')

local self = require('openmw.self')
local util = require('openmw.util')
local core = require('openmw.core')
local types = require('openmw.types')
local camera = require('openmw.camera')

local resetingInertia = 0;
local airDashStrenght = 500;
local airDashVelocity = util.vector3(0, 0, 0);
local airDashDuration = 0.33;
local airDashStartTime = 0.0;



local function TestActorMovement(dt)
   local now = core.getRealTime()

   local params = {}
   params.maxWalkableSlope = 90;
   params.stepSizeDown = 200;
   params.stepSizeUp = 200;
   self:setActorCollisionParams(params)











   if resetingInertia == 1 then
      print("Reset inertia")
      self:setActorLocalInertia(util.vector3(0, 0, 0))
      resetingInertia = 0
   end
end

local function AirJump()
   if not types.Actor.isOnGround(self.object) then
      print('Air jumping')



      resetingInertia = 1


      local direction = camera.viewportToWorldVector(util.vector2(0.5, 0.5)):normalize()
      airDashVelocity = direction * airDashStrenght;
      airDashStartTime = core.getRealTime()
   end
end

return {
   engineHandlers = {
      onPhysicsUpdate = function(dt)
         TestActorMovement(dt)
      end,
      onInputAction = function(action)
         if action == input.ACTION.Jump then
            AirJump()
         end
      end,
   },
}
