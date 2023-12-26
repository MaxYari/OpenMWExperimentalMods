
local input = require('openmw.input')
local self = require('openmw.self')
local core = require('openmw.core')
local types = require('openmw.types')
local camera = require('openmw.camera')
local util = require('openmw.util')
local nearby = require('openmw.nearby')

local grazedHitDamageMult = 0.2;

local function onIHit(
    target: core.GameObject,
    weapon: core.GameObject,
    attacker: core.GameObject,
    dmgData: DamageData,
    hitConfig: HitConfig)
    --print("I struck a "..target.recordId.." it was a "..tostring(dmgData.isSuccessful))
    --print("Damage ",dmgData.damage)
    --print("Hit positions ",dmgData.hitPosition)
    --print("Hit id ",hitConfig.id)
    
    
    if not dmgData.isSuccessful then
        local newDmgData: DamageData = {}
        -- Grazed hit deal only a fraction of damage
        newDmgData.damage = math.max(dmgData.damage * grazedHitDamageMult, 1);
        newDmgData.affectsHealth = dmgData.affectsHealth;
        newDmgData.affectsFatigue = dmgData.affectsFatigue;
        newDmgData.hitPosition = dmgData.hitPosition;
        -- Never miss!
        newDmgData.isSuccessful = true;

        local newHitConfig: HitConfig = {}
        newHitConfig.playVFX = true;
        newHitConfig.playSFX = true;
        -- Reduce the hit reaction chance
        newHitConfig.avoidHitReaction = math.random() > 0.33;
        -- No knockdown on grazed hits
        newHitConfig.avoidKnockdown = true;
        newHitConfig.id = "GCombat_grazed_hit"

        -- Attempt to find a more precise blood splatter location
        local position = camera.getPosition()
        local direction = camera.viewportToWorldVector(util.vector2(0.5, 0.5)):normalize()        
        local castResult = nearby.castRay(position, position + direction * 200)
        local object = castResult.hitObject
        if object and object == target then
            --print("raycast hit target")
            newDmgData.hitPosition = castResult.hitPos
        end  

        -- Do the grazed hit!
        types.Actor.hit(target, weapon, attacker, newDmgData, newHitConfig)
        
        -- Send to global script to play VFX
        core.sendGlobalEvent('GCombat_grazed_hit', {damageData=newDmgData,target=target})

    end
end

return {
    engineHandlers = {
        onUpdate = function(dt: number)
            
        end,
        onActorHit = function(
            target: core.GameObject,
            weapon: core.GameObject,
            attacker: core.GameObject,
            dmgData: DamageData,
            hitConfig: HitConfig)
            
            --print("onActorHit attacker " .. attacker.recordId)
            --print("weapon " .. weapon.recordId)            
            if attacker == self.object then
                onIHit(target, weapon, attacker, dmgData, hitConfig)
            end
        end,
        onInputAction = function(action: number)
            if action == input.ACTION.Jump then
                
            end
        end
    }
}