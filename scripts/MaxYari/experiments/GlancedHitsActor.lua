local mp = "scripts/MaxYari/experiments/"

local types = require("openmw.types")
local nearby = require("openmw.nearby")
local self = require("openmw.self")
local I = require('openmw.interfaces')
local animation = require('openmw.animation')
local util = require("openmw.util")
local core = require("openmw.core")
local storage = require("openmw.storage")

local gutils = require(mp .. '/scripts/gutils')

local selfActor = gutils.Actor:new(self)
local isPlayer = self.type == types.Player
local interfaceName = "GlancedHits"
local interface = {
    version=0.9
}

local settings = storage.globalSection('SettingsOMWCombat')
local spawnBloodEffectsOnPlayer = settings:get('spawnBloodEffectsOnPlayer')
local mStrengthInfluencesHandToHand = settings:get("mStrengthInfluencesHandToHand") -- This one is also wrong, its nil now
local sWerewolfClawMult = 1 -- Should be retreived from global variables inside global script
local fMinHandToHandMult = core.getGMST("fMinHandToHandMult")
local fMaxHandToHandMult = core.getGMST("fMaxHandToHandMult")
local fHandtoHandHealthPer = core.getGMST("fHandtoHandHealthPer")
local glanceDamageMult = 0.33

local function spawnBloodEffect(position, minihit)
    print("Is minihit",minihit)
    if isPlayer and not settings:get('spawnBloodEffectsOnPlayer') then
        return
    end

    local scale = 1.0
    if minihit then scale = 0.5 end

    local modelInd = math.random(0,2)

    -- 2 is a big ugly blood explosion, 0 and 1 are ok
    local bloodEffectModel = string.format('Blood_Model_%d', modelInd) -- randIntUniformClosed(0, 2)
    -- math.random(0, 2)


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
            scale = scale
        },
    })
end

local YUnitVector = util.vector3(0,1,0)
local ZUnitVector = util.vector3(0,0,1)
local function randomOffsetInPlane(rayDir, radius)
    -- build orthonormal basis
    local arbitrary = math.abs(rayDir.z) < 0.99
        and YUnitVector
        or ZUnitVector

    local right = rayDir:cross(arbitrary):normalize()
    local up = rayDir:cross(right):normalize()

    -- random point in circle
    local angle = math.random() * math.pi * 2
    local r = math.sqrt(math.random()) * radius

    return right * (math.cos(angle) * r)
         + up    * (math.sin(angle) * r)
end



--[[ SkillProgression.addSkillUsedHandler(handler(skillId, opts))


    skillGain - The numeric amount of skill to be gained.
    useType - #SkillUseType, A number from 0 to 3 (inclusive) representing the way the skill was used, with each use type having a different skill progression rate. Available use types and its effect is skill specific. See #SkillUseType

And may contain the following optional parameter:

    scale - A numeric value used to scale the skill gain. Ignored if the skillGain parameter is set.
 ]]
-- What aboot enchantments?

local lastHitTime = {}
local spamThreshold = 0.8

local function calcWeaponDamage(attackInfo, weapon)
    local weaponRecord = types.Weapon.record(weapon)

    -- Determine damage based on the attack type from a.type
    local minDamage, maxDamage = 0, 0
    if weaponRecord then
        if attackInfo.type == self.ATTACK_TYPE.Chop then
            minDamage, maxDamage = weaponRecord.chopMinDamage or 0, weaponRecord.chopMaxDamage or 0
        elseif attackInfo.type == self.ATTACK_TYPE.Slash then
            minDamage, maxDamage = weaponRecord.slashMinDamage or 0, weaponRecord.slashMaxDamage or 0
        elseif attackInfo.type == self.ATTACK_TYPE.Thrust then
            minDamage, maxDamage = weaponRecord.thrustMinDamage or 0, weaponRecord.thrustMaxDamage or 0
        else
            -- Default to slash damage if type not specified
            minDamage, maxDamage = weaponRecord.slashMinDamage or 0, weaponRecord.slashMaxDamage or 0
        end
    end

    -- Interpolate damage based on attack strength between min and max
    local dmg = minDamage + (maxDamage - minDamage) * (attackInfo.strength or 0.5)

    -- Apply weapon condition modifier
    local currentCondition = types.Item.itemData(weapon).condition
    local maxCondition = weaponRecord.health
    print("Current and max conditions",currentCondition,maxCondition)
    local conditionRatio = (currentCondition and currentCondition > 0) and (currentCondition / maxCondition) or 1.0
    dmg = dmg * conditionRatio

    return dmg
end

local function calcH2HDamage(attackInfo)    
    -- Get hand to hand skill value
    local handToHandSkill = types.NPC.stats.skills.handtohand(attackInfo.attacker).modified
    -- Calculate base damage: skill * (min + (max - min) * attackStrength)
    local minstrike = fMinHandToHandMult
    local maxstrike = fMaxHandToHandMult
    local attackStrength = attackInfo.strength or 0.5
    local dmg = handToHandSkill * (minstrike + (maxstrike - minstrike) * attackStrength)    
    
    -- Check if attacker is werewolf
    local isWerewolf = attackInfo.attacker.type.isWerewolf and attackInfo.attacker.type.isWerewolf(attackInfo.attacker)

    local isHealthDamage = isWerewolf or not selfActor:canMove();
    
    -- Get strength attribute for potential strength factor calculation
    local strength = types.Actor.stats.attributes.strength(attackInfo.attacker).modified
    
    -- Apply strength factor based on game settings (unarmedFactorsStrengthComboBox)
    -- 0 = Do not factor strength into hand-to-hand combat
    -- 1 = Factor into werewolf hand-to-hand combat
    -- 2 = Ignore werewolves (factor into non-werewolf combat)
    -- For now, we'll simulate option 2 (most common behavior)
    local factorStrength = mStrengthInfluencesHandToHand 
    -- print("Str influence", mStrengthInfluencesHandToHand)
    
    if factorStrength == 1 or (factorStrength == 2 and not isWerewolf) then
        dmg = dmg * (strength / 40.0)    
    end    
    
    -- Apply werewolf claw multiplier if werewolf
    if isWerewolf then               
        dmg = dmg * sWerewolfClawMult
    end   
    
    -- Apply health per multiplier if applicable
    if isHealthDamage then
        dmg = dmg * fHandtoHandHealthPer
    end
    
    -- Ensure minimum damage of 1
    dmg = math.max(dmg, 1)
    
    return dmg, isHealthDamage
end

local function calcCreatureDamage(attackInfo)
    -- Creature attack without weapon - use creature attack data
    local attackerCreatureRecord = types.Creature.record(attackInfo.attacker)
    local attackData = attackerCreatureRecord.attack
    local minDamage = attackData[1] or 0
    local maxDamage = attackData[2] or 0
    local dmg = minDamage + (maxDamage - minDamage) * attackInfo.strength
    return dmg
end

I.Combat.addOnHitHandler(function(a)
    if not a.attacker then return end

    local stance = gutils.getDetailedStance(a.attacker)
    local isRangedAttacker = (stance == gutils.Actor.DET_STANCE.Marksman)
    local now = core.getRealTime()

    a.glancedHit = not a.successful
    
    if a.attacker.type == types.Player and not isRangedAttacker then
        -- Use a more precise blood spawning system for a player
        a.hitPos = nil
        a.attacker:sendEvent("GlancedHits_GetHitPoint",{sender=self, attackSuccessful=a.successful})
    end

    if not a.successful then
        -- Calculating strength if necessary
        if a.strength == nil then
            -- Hello dear reader! (Mis)fortune be so - the OpenMW Lua API does not provide attack strength in case of a missed attack, originally
            -- strength depends on where within the windup animation attack button was released, this can be measured in lua, but communicating this
            -- to an attack victim and accounting for all potential pitfalls is problematic. Any sick solution I can come up with presents itself as a 
            -- bloated overengineered mess, so instead here I will opt-in for a daring elegance of smoke and mirrors. Behold:
            a.strength = math.random(0.25, 0.75)
            -- Additionally, for ranged attackers - assume that attacks are always close to full strength
            if isRangedAttacker then
                a.strength = math.random(0.75, 1.0)
            end
            -- Furthermore, maybe to a slight detrement to above elegance - below silly heuristic will "detect" an attack spam and redure strength
            if lastHitTime[a.attacker.id] and now - lastHitTime[a.attacker.id] <= spamThreshold then
                a.strength = math.random(0, 0.25)
            end
            -- And most likely none will be wiser, so shhhh.
        end     

        -- Calculating damage
        local dmg = 0
        local damageStat = "health"
        if types.NPC.objectIsInstance(a.attacker) then            
            local weapon = types.Actor.getEquipment(a.attacker, types.Actor.EQUIPMENT_SLOT.CarriedRight)

            if weapon and types.Weapon.objectIsInstance(weapon) then
                dmg = calcWeaponDamage(a, weapon)
            else
                -- H2H damage calc is too annoying
                -- dmg, isHealthDamage = calcH2HDamage(a)
                -- if not isHealthDamage then damageStat = "fatigure" end
            end
        elseif types.Creature.objectIsInstance(a.attacker) then
            dmg = calcCreatureDamage(a)
        end

        -- Applying damage with a reduced factor
        if dmg > 0 then
            -- Apply a reduction factor for glanced hits (e.g., 25% of normal damage)
            
            dmg = dmg * glanceDamageMult
            --print("Glanced damage", glancedDamage)

            -- Set the damage for the health stat
            a.damage.health = nil
            a.damage.fatigue = nil
            a.damage[damageStat] = dmg

            -- Mark the attack as successful to apply the reduced damage
            a.successful = true
        end
    end    

    -- Save things
    a.time = now
    lastHitTime[a.attacker.id] = now
    interface.lastHitInfo = a
end)

local function onMyHitPoint(e)
    print("Got hit point!",e.hitPos)
    local spawnPos
    if e.hitObject then
        if e.isOnSurface then
            spawnPos = e.hitPos + e.hitNormal * 10
        else
            spawnPos = e.hitPos
        end
        spawnPos = spawnPos + randomOffsetInPlane(e.hitNormal, 10)
        spawnBloodEffect(e.hitPos, not e.attackSuccessful)
    end
    -- TO DO: Maybe introduce a fallback for when no hit position was found
end




local lastStaggerAnimGroup = nil


I.AnimationController.addTextKeyHandler(nil, function(groupname, key)
    -- Only handle groupnames like "hit1", "hit2", etc.    
    --print(key)
    if type(groupname) == "string" and groupname:match("^hit%d+$") then
        -- vanilla stagger anims are hit1/2/3/4/5
        -- Victim is being staggered
        lastStaggerAnimGroup = groupname        
    end    
end)

local function onUpdate(dt)
    if dt <= 0 then return end

    if lastStaggerAnimGroup and (interface.lastHitInfo and interface.lastHitInfo.glancedHit) then
        animation.cancel(self, lastStaggerAnimGroup)
        lastStaggerAnimGroup = nil
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