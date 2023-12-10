local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local math = _tl_compat and _tl_compat.math or math; local core = require('openmw.core')
local util = require('openmw.util')
local self = require('openmw.self')
local types = require('openmw.types')



print("Collider script attached to an object " .. self.object.recordId);

local minHitVelocity = 400;
local minSoundVelocity = 50;

local impactDamage = 1.0;

local soundPause = 0.2;
local lastSoundTime = 0.0;

local ownerObject;
local lastHitActor;




return {
   engineHandlers = {
      onCollision = function(obj, pos, norm, velocity)



         local now = core.getRealTime()
         local volume = util.remap(velocity:length(), minSoundVelocity, 1000, 0.42, 1)
         if velocity:length() < minSoundVelocity then
            volume = 0
         end
         local pitch = 0.5 + math.random() * 1
         local params = { volume = volume, pitch = pitch, loop = false }
         if volume > 0 and now - lastSoundTime > soundPause then
            core.sound.playSoundFile3d("scripts\\MaxYari\\experiments\\collision1.wav", self.object, params)
            lastSoundTime = now
         end


         if not types.Actor.objectIsInstance(obj) then return end
         print("Collided with an actor " .. obj.recordId .. " Velocity " .. tostring(velocity:length()));

         if obj == lastHitActor then return end
         if velocity:length() < minHitVelocity then return end

         print("Hitting")
         types.Actor.hit(obj, impactDamage, true, nil, ownerObject, pos, true)
         lastHitActor = obj




      end,
   },
   eventHandlers = {
      GrabbedBy = function(data)
         print("Grabbed by " .. data.actor.recordId);
         ownerObject = data.actor;
         lastHitActor = nil;


         local strength = types.Actor.stats.attributes.strength(ownerObject);
         impactDamage = util.clamp(util.remap(strength.modified, 40, 100, 10, 80), 10, 80);
         print("Calculated impactDamage " .. impactDamage);
      end,
   },
}
