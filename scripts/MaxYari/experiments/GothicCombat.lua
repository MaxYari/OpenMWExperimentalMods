local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then
   local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end
end; local math = _tl_compat and _tl_compat.math or math
local input = require('openmw.input')
local self = require('openmw.self')
local core = require('openmw.core')
local types = require('openmw.types')
local camera = require('openmw.camera')
local util = require('openmw.util')
local nearby = require('openmw.nearby')
local animation = require('openmw.animation')
local I = require('openmw.interfaces')


local grazedHitDamageMult = 0.2;

local attackState = nil;
local attackGroupname = nil;
local lastUseState = 0;

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


-- Animation handlers --------
------------------------------
-- Notes: Theres no way do check what animation group is currently playing on a specific bonegroup?
-- In the text key handler: Theres no way to know for which bonegroup the text key was triggered?
I.AnimationController.addPlayBlendedAnimationHandler(function(groupname, options)
   --I.AnimationController.addTextKeyHandler(nil, function(groupname, key)
   --print("Animation text key! " .. groupname .. " : " .. key)
   print("New animation started! " .. groupname .. " : " .. options.startkey .. " --> " .. options.stopkey)
   -- Note: attack animation can be interrupted, so this states most likely should reset after few seconds just in case, to ponder: what if character holds the attack long enough for this to reset?
   -- Probably need to check animation timings to figure for sure if we are in the attack group or not, can get the group during windup and then repeatedly check if its still playing, reset if not
   if string.find(options.startkey, "chop ") then
      -- Cancel vanilla chops, we are taking care of this
      print("Overriding")
      options.startkey = string.gsub(options.startkey, "chop", "chop1")
      options.stopkey = string.gsub(options.stopkey, "chop", "chop1")
      --[[ print("canceling")
      animation.cancel(self, groupname) ]]
   end

   --[[ if string.find(options.startkey, "chop start") then
      local startkey = string.gsub(options.startkey, "chop", "chop1")
      local stopkey = string.gsub(options.stopkey, "chop", "chop1")

      attackState = "windup"
      attackGroupname = groupname
      --slash max attack --> slash hit
      I.AnimationController.playBlendedAnimation(groupname,
         {
            startkey = startkey,
            stopkey = stopkey,
            priority = animation.PRIORITY.Weapon
         })
   end ]]


   --[[ if string.find(options.startkey, "chop max attack") then
      print("Overriding swing anim")
      --animation.cancel(self, groupname)
      I.AnimationController.playBlendedAnimation('handtohand',
         {
            startkey = "thrust max attack",
            stopkey = "thrust hit",
            priority = animation.PRIORITY.Weapon
         })
   end

   --chop small follow start --> chop small follow stop
   if string.find(options.startkey, "chop small follow start") then
      print("Overriding follow anim")
      animation.cancel(self, "handtohand")
      I.AnimationController.playBlendedAnimation('handtohand',
         {
            startkey = "thrust small follow start",
            stopkey = "thrust small follow stop",
            priority = animation.PRIORITY.Weapon
         })
   end ]]
end)


I.AnimationController.addTextKeyHandler(nil, function(groupname, key)
   --print("Animation text key! " .. groupname .. " : " .. key)
   --print("New animation started! " .. groupname .. " : " .. options.startkey .. " --> " .. options.stopkey)
   -- Note: attack animation can be interrupted, so this states most likely should reset after few seconds just in case, to ponder: what if character holds the attack long enough for this to reset?
   -- Probably need to check animation timings to figure for sure if we are in the attack group or not, can get the group during windup and then repeatedly check if its still playing, reset if not
   -- chop small follow start --> chop small follow stop
   --[[ if string.find(key, "chop1 hit") then
      attackState = "follow"
      I.AnimationController.playBlendedAnimation(attackGroupname,
         {
            startkey = "chop1 small follow start",
            stopkey = "chop1 small follow stop",
            priority = animation.PRIORITY.Weapon
         })
   end ]]

   --[[ if string.find(key, "chop ") then
      -- Cancel vanilla chops, we are taking care of this
      print("canceling")
      animation.cancel(self, groupname)
   end ]]
end)


return {
   engineHandlers = {
      onUpdate = function(dt)
         if lastUseState ~= self.controls.use and self.controls.use == 0 then
            --[[ if attackState == "windup" then
               attackState = "swing"
               animation.cancel(self, attackGroupname)
               I.AnimationController.playBlendedAnimation(attackGroupname,
                  {
                     startkey = "chop1 max attack",
                     stopkey = "chop1 hit",
                     priority = animation.PRIORITY.Weapon
                  })
            end ]]
         end
         lastUseState = self.controls.use
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
