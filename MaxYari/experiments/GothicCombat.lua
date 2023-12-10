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
   print("I struck a " .. target.recordId .. " it was a " .. tostring(dmgData.isSuccessful))
   print("Damage ", dmgData.damage)
   print("Hit positions ", dmgData.hitPosition)
   print("Hit id ", hitConfig.id)


   if not dmgData.isSuccessful then
      local newDmgData = {}
      newDmgData.damage = math.max(dmgData.damage * grazedHitDamageMult, 1);
      newDmgData.affectsHealth = dmgData.affectsHealth;
      newDmgData.affectsFatigue = dmgData.affectsFatigue;
      newDmgData.hitPosition = dmgData.hitPosition;
      newDmgData.isSuccessful = true;

      local newHitConfig = {}
      newHitConfig.playVFX = false;
      newHitConfig.playSFX = false;
      newHitConfig.avoidHitReaction = true;
      newHitConfig.avoidKnockdown = true;
      newHitConfig.id = "GCombat_grazed_hit"

      types.Actor.hit(target, weapon, attacker, newDmgData, newHitConfig)

      local position = camera.getPosition()
      local direction = camera.viewportToWorldVector(util.vector2(0.5, 0.5)):normalize()
      local castResult = nearby.castRay(position, position + direction * 200)
      local object = castResult.hitObject
      if object then
         print("raycast hit " .. object.recordId)
      end

      if object and object == target then
         print("raycast hit target")
         newDmgData.hitPosition = castResult.hitPos
      end

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

         print("onActorHit attacker " .. attacker.recordId)
         print("weapon " .. weapon.recordId)
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
