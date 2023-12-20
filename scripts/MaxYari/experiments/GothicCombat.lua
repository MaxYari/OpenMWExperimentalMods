local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local math = _tl_compat and _tl_compat.math or math
local input = require('openmw.input')
local self = require('openmw.self')
local core = require('openmw.core')
local types = require('openmw.types')
local camera = require('openmw.camera')
local util = require('openmw.util')
local nearby = require('openmw.nearby')

local grazedHitDamageMult = 0.2;

local function onIHit(
   target,
   weapon,
   attacker,
   dmgData,
   hitConfig)






   if not dmgData.isSuccessful then
      local newDmgData = {}

      newDmgData.damage = math.max(dmgData.damage * grazedHitDamageMult, 1);
      newDmgData.affectsHealth = dmgData.affectsHealth;
      newDmgData.affectsFatigue = dmgData.affectsFatigue;
      newDmgData.hitPosition = dmgData.hitPosition;

      newDmgData.isSuccessful = true;

      local newHitConfig = {}
      newHitConfig.playVFX = true;
      newHitConfig.playSFX = true;

      newHitConfig.avoidHitReaction = math.random() > 0.33;

      newHitConfig.avoidKnockdown = true;
      newHitConfig.id = "GCombat_grazed_hit"


      local position = camera.getPosition()
      local direction = camera.viewportToWorldVector(util.vector2(0.5, 0.5)):normalize()
      local castResult = nearby.castRay(position, position + direction * 200)
      local object = castResult.hitObject
      if object and object == target then

         newDmgData.hitPosition = castResult.hitPos
      end


      types.Actor.hit(target, weapon, attacker, newDmgData, newHitConfig)


      core.sendGlobalEvent('GCombat_grazed_hit', { damageData = newDmgData, target = target })

   end
end

return {
   engineHandlers = {
      onUpdate = function(dt)

      end,
      onActorHit = function(
         target,
         weapon,
         attacker,
         dmgData,
         hitConfig)



         if attacker == self.object then
            onIHit(target, weapon, attacker, dmgData, hitConfig)
         end
      end,
      onInputAction = function(action)
         if action == input.ACTION.Jump then

         end
      end,
   },
}
