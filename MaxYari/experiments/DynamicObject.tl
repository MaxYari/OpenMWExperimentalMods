local core = require('openmw.core')
local util = require('openmw.util')
local self = require('openmw.self')
local types = require('openmw.types')



print("Collider script attached to an object " .. self.object.recordId);

local minHitVelocity = 400;
local minSoundVelocity = 50;

local impactDamage = 1.0;

local soundPause = 0.2;
local lastSoundTime = 0.0;

local ownerObject : core.GameObject;
local lastHitActor : core.GameObject;
local type EventData = record
    actor: core.GameObject
end

return {
    engineHandlers = {
        onCollision = function(obj: core.GameObject, pos: util.Vector3, norm: util.Vector3, velocity: util.Vector3)
            -- print("Collided with " .. obj.recordId .. " Velocity " .. tostring(velocity:length()));

            -- Collision sound
            local now = core.getRealTime()
            local volume = util.remap(velocity:length(), minSoundVelocity, 1000, 0.42, 1)
            if velocity:length() < minSoundVelocity then 
                volume = 0
            end
            local pitch = 0.5 + math.random()*1
            local params: {any:any}  = { volume = volume, pitch = pitch, loop = false }
            if volume > 0 and now - lastSoundTime > soundPause then
                core.sound.playSoundFile3d("scripts\\MaxYari\\experiments\\collision1.wav", self.object, params)
                lastSoundTime = now
            end
            
            -- Damaging an actor if this actor wasnt yet hit by this item
            if not types.Actor.objectIsInstance(obj) then return end
            print("Collided with an actor " .. obj.recordId .. " Velocity " .. tostring(velocity:length()));

            if obj == lastHitActor then return end
            if velocity:length() < minHitVelocity then return end

            print("Hitting")
            types.Actor.hit(obj,impactDamage,true,nil,ownerObject,pos,true)
            lastHitActor = obj

            -- actor is who threw it
            --obj:sendEvent('DamageFromThrown', {actor=nil, obj=self.object, damage=100});
            
        end
    },
    eventHandlers = { 
        GrabbedBy = function(data: EventData)
            print("Grabbed by " .. data.actor.recordId);
            ownerObject = data.actor;
            lastHitActor = nil;

            -- Calculating impact damage
            local strength = types.Actor.stats.attributes.strength(ownerObject);
            impactDamage = util.clamp(util.remap(strength.modified, 40, 100, 10, 80),10,80);
            print("Calculated impactDamage " .. impactDamage);
        end
    },
}