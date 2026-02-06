local mp = "scripts/MaxYari/experiments/"

local types = require("openmw.types")
local nearby = require("openmw.nearby")
local self = require("openmw.self")
local I = require('openmw.interfaces')
local animation = require('openmw.animation')
local util = require("openmw.util")
local core = require("openmw.core")
local gutils = require(mp .. '/scripts/gutils')


local interfaceName = "GlancedHits"
local interface = {
    version=0.9
}

local function spawnBloodEffect(position)
    if isPlayer and not settings:get('spawnBloodEffectsOnPlayer') then
        return
    end

    local bloodEffectModel = string.format('Blood_Model_%d', math.random(0, 2)) -- randIntUniformClosed(0, 2)

    -- TODO: implement a Misc::correctMeshPath equivalent instead?
    -- All it ever does it append 'meshes\\' though
    bloodEffectModel = 'meshes/'..core.getGMST(bloodEffectModel)

    local record = self.object.type.record(self.object)
    local bloodTexture = string.format('Blood_Texture_%d', record.bloodType)
    bloodTexture = core.getGMST(bloodTexture)
    if not bloodTexture or bloodTexture == '' then
        bloodTexture = core.getGMST('Blood_Texture_0')
    end
    core.sendGlobalEvent('SpawnVfx', {
        model = bloodEffectModel,
        position = position,
        options = {
            mwMagicVfx = false,
            particleTextureOverride = bloodTexture,
            useAmbientLight = false,
        },
    })
end


-- TO DO, ask player for hit position

-- TO DO, add the whole request strike power system, probably attack anim checker can be lifter from reanim

--[[ SkillProgression.addSkillUsedHandler(handler(skillId, opts))


    skillGain - The numeric amount of skill to be gained.
    useType - #SkillUseType, A number from 0 to 3 (inclusive) representing the way the skill was used, with each use type having a different skill progression rate. Available use types and its effect is skill specific. See #SkillUseType

And may contain the following optional parameter:

    scale - A numeric value used to scale the skill gain. Ignored if the skillGain parameter is set.
 ]]
-- What aboot enchantments?

local lastHitTime = {}
local spamThreshold = 0.8

I.Combat.addOnHitHandler(function(a)
    if not a.attacker then return end
    
    local now = core.getRealTime()
    --print("Hit event")
    --print("Hit pos",a.hitPos)    
    --I.Combat.spawnBloodEffect(a.hitPos + util.vector3(math.random(-10,10),math.random(-10,10),math.random(-10,10)))    

    -- If attack is not successful, we need to get strength from our stored data
    if not a.successful then
        -- Check if we have strength info from this attacker
        
        local attackerId = a.attacker.id
        if a.strength == nil then
            -- Hello dear reader! (Mis)fortune be so - the OpenMW Lua API does not provide attack strength in case of a missed attack, originally
            -- strength depends on where within the windup animation attack button was released, this can be measured in lua, but communicating this
            -- to an attack victim and accounting for all potential pitfalls is problematic. Any sick solution I can come up with presents itself as a 
            -- bloated overengineered mess, so instead here I will opt-in for a daring elegance of smoke and mirrors. Behold:
            a.strength = math.random(0.25, 0.75)
            -- Furthermore, maybe to a slight detrement to above elegance - below silly heuristic will "detect" an attack spam and redure strength
            if lastHitTime[a.attacker.id] and now - lastHitTime[a.attacker.id] <= spamThreshold then
                a.strength = math.random(0, 0.25)
            end
            -- And most likely none will be wiser, so shhhh.
        end        
    end

    if not a.successful then
        a.hitPos = nil
        a.glancedHit = true
        a.attacker:sendEvent("GlancedHits_GetHitPoint",{sender=self})
        local baseDamage = 0
        -- TO DO: FIx h2h stuff
        -- Only process if the attacker is either an NPC or Creature
        if types.NPC.objectIsInstance(a.attacker) then
            -- Get the attacking weapon
            local weapon = types.Actor.getEquipment(a.attacker, types.Actor.EQUIPMENT_SLOT.CarriedRight)

            if weapon and types.Weapon.objectIsInstance(weapon) then
                --print("attacking with", weapon, "str", a.strength)
                -- Weapon-based attack
                local weaponRecord = types.Weapon.record(weapon)

                -- Determine damage based on the attack type from a.type
                local minDamage, maxDamage = 0, 0
                if weaponRecord then
                    if a.type == self.ATTACK_TYPE.Chop then
                        minDamage, maxDamage = weaponRecord.chopMinDamage or 0, weaponRecord.chopMaxDamage or 0
                    elseif a.type == self.ATTACK_TYPE.Slash then
                        minDamage, maxDamage = weaponRecord.slashMinDamage or 0, weaponRecord.slashMaxDamage or 0
                    elseif a.type == self.ATTACK_TYPE.Thrust then
                        minDamage, maxDamage = weaponRecord.thrustMinDamage or 0, weaponRecord.thrustMaxDamage or 0
                    else
                        -- Default to slash damage if type not specified
                        minDamage, maxDamage = weaponRecord.slashMinDamage or 0, weaponRecord.slashMaxDamage or 0
                    end
                end

                -- Interpolate damage based on attack strength between min and max
                baseDamage = minDamage + (maxDamage - minDamage) * (a.strength or 0.5)
                --print("calculated base dmg", baseDamage)
            else
                -- Unarmed attack - use hand-to-hand skill for damage calculation
                -- This should be a fatigue damage, theres a separate health damage, need to figure it later
                local handToHandSkill = types.Actor.skills.handtohand(a.attacker)
                if handToHandSkill then
                    -- Calculate damage based on hand-to-hand skill and attack strength
                    -- Using Morrowind's formula: damage = skill * (min_mult + swing * (max_mult - min_mult))
                    local minMultiplier = 0.1  -- fMinHandToHandMult
                    local maxMultiplier = 0.5  -- fMaxHandToHandMult
                    local swingPower = a.strength or 0.5  -- Attack strength acts as swing power

                    baseDamage = handToHandSkill.modified * (minMultiplier + swingPower * (maxMultiplier - minMultiplier))
                    baseDamage = math.max(baseDamage, 1)  -- Minimum 1 damage
                else
                    -- Fallback if hand-to-hand skill is not available
                    baseDamage = 1 * (a.strength or 0.5)
                end
            end

        elseif types.Creature.objectIsInstance(a.attacker) then
            -- Creature attack without weapon - use creature attack data
            local attackerCreatureRecord = types.Creature.record(a.attacker)
            local attackData = attackerCreatureRecord.attack
            local minDamage = attackData[1] or 0
            local maxDamage = attackData[2] or 0
            baseDamage = minDamage + (maxDamage - minDamage) * (a.strength or 0.5)
        end

        if baseDamage > 0 then
            -- Apply a reduction factor for glanced hits (e.g., 25% of normal damage)
            local glanceReduction = 0.25
            local glancedDamage = baseDamage * glanceReduction
            --print("Glanced damage", glancedDamage)

            -- Set the damage for the health stat
            a.damage = { health = glancedDamage }

            -- Mark the attack as successful to apply the reduced damage
            a.successful = true
        end
    end    

    -- Save things
    lastHitTime[a.attacker.id] = now
    
    a.time = now
    interface.lastHitInfo = a
end)




local lastStaggerAnimGroup = nil

-- Textkey handler to detect attack type keys with "min attack" suffix
I.AnimationController.addTextKeyHandler(nil, function(groupname, key)
    -- Only handle groupnames like "hit1", "hit2", etc.
    --[[ if s3lf.object.type == types.Creature then
        print(groupname, key)
    end ]]
    --print(key)
    if type(groupname) == "string" and groupname:match("^hit%d+$") then
        -- vanilla hits are hit1/2/3/4/5
        -- Victim is being hit
        lastStaggerAnimGroup = groupname        
    end
    
end)








local function onUpdate(dt)
    if dt <= 0 then return end

    if lastStaggerAnimGroup and (interface.lastHitInfo and not interface.lastHitInfo.successful) then
        animation.cancel(self, lastStaggerAnimGroup)
        lastStaggerAnimGroup = nil
    end
end

local function onMyHitPoint(e)
    print("Got hit point!",e.hitPos)
    if e.hitPos then
        I.Combat.spawnBloodEffect(e.hitPos)
    end
end

return {
    interfaceName = interfaceName,
    interface = interface,    
    engineHandlers = {
       onUpdate = onUpdate
    },
    eventHandlers = {
        GlancedHits_MyHitPoint = onMyHitPoint
    }
}