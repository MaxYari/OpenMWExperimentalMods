-- Mod files
local gutils = require("scripts/gutils")
local moveutils = require("scripts/movementutils")
local itemutil = require("scripts/item_util")
local enums = require("scripts/enums")
local behaviorNodes = require("scripts/behavior_nodes")
local animManager = require("scripts/anim_manager")
local voiceManager = require("scripts/voice_manager")

-- OpenMW libs
local omwself = require('openmw.self')
local selfActor = gutils.Actor:new(omwself)
local core = require('openmw.core')
local AI = require('openmw.interfaces').AI
local vfs = require('openmw.vfs')
local util = require('openmw.util')
local types = require('openmw.types')
local nearby = require("openmw.nearby")
local I = require('openmw.interfaces')

-- 3rd party libs
-- Setup important global functions for the behaviourtree 2e module to use--
local BT = require('scripts.MaxYari.behaviourtreelua2e.lib.behaviour_tree')
local json = require("json")
local luaRandom = require("libs/randomlua")
----------------------------------------------------------------------------


DebugLevel = 2

local fCombatDistance = core.getGMST("fCombatDistance")
local fHandToHandReach = core.getGMST("fHandToHandReach")

if core.API_REVISION < 64 then error("Can not start Mercy: CAO, newer version of lua API is required. Please update OpenMW.") end


-- And the story begins!
-- if omwself.recordId ~= "tanisie verethi" then return end
gutils.print(omwself.recordId .. ": Mercy: CAO Improved AI is ON")


-- State object is an object to which behavior tree has access
local state = {
   -- Persistent state fields
   COMBAT_STATE = enums.COMBAT_STATE,
   attackState = enums.ATTACK_STATE.NO_STATE,
   combatState = enums.COMBAT_STATE.NO_STATE,
   attackGroup = nil,
   staggerGroup = nil,
   dt = 0,
   reach = 140,
   locomotion = nil,
   engageRange = 600,
   slowSpeed = 10,

   -- Inclinations are used directly within a tree
   goHamHeat = 0,
   rootedAttackInc = 50,
   nearStopInc = 50,
   nearStrafeInc = 50,
   nearBackInc = 50,
   midStrafeInc = 50,
   midChaseInc = 50,
   midAttackInc = 50,
   midStopInc = 50,
   jumpInc = 0,
   zoomiesInc = 0,

   clear = function(self)
      -- Fields below will be reset every frame
      self.stance = types.Actor.STANCE.Weapon
      self.run = true
      self.jump = false
      self.attack = 0
      self.movement = 0
      self.sideMovement = 0
      self.range = 1e42
      self.lookDirection = nil
   end,

   -- Functions to be used in the editor
   r = function(min, max)
      if min == nil then
         return math.random()
      else
         return min + math.random() * (max - min)
      end
   end,
   rSlowSpeed = function(self)
      return gutils.lerp(self.slowSpeed, self.slowSpeed * 2, math.random())
   end,
   rint = function(m, n)
      return math.random(m, n)
   end,
   isHoldingAttack = function(self)
      return self.attackState == enums.ATTACK_STATE.WINDUP_MIN or self.attackState == enums.ATTACK_STATE.WINDUP_MAX
   end,
   attacksFromSkill = function(self)
      if not self.weaponSkill then return math.random(1, 2) end
      local skill = self.weaponSkill
      local n = 1
      if skill >= 75 then
         n = math.random(2, 4)
      elseif skill >= 50 then
         n = math.random(1, 3)
      else
         n = math.random(1, 2)
      end
      if self.inHamMode then n = n * 2 + 1 end
      return n
   end,
   attPauseFromSkill = function(self)
      if not self.weaponSkill then return 0 end

      local skill = self.weaponSkill
      local duration = util.clamp(util.remap(skill, 0, 75, 0.6, 0), 0, 0.6)
      if duration < 0 then duration = 0 end

      return duration
   end,
   CSIs = function(self, stateString)
      if not self.COMBAT_STATE[stateString] then
         error("Wrong combat state provided to combat state check.")
      end
      return self.combatState == self.COMBAT_STATE[stateString]
   end
}







local function randomiseInclinations()
   local standartInclinations = { "rootedAttackInc", "nearStopInc", "nearStrafeInc", "nearBackInc", "midStrafeInc",
      "midChaseInc", "midAttackInc", "midStopInc" }
   local weirdInclinations = { "jumpInc", "zoomiesInc" }

   state.slowSpeedFactor = luaRandom:random(0, 1)

   local spreadBracket = luaRandom:random()

   for _, param in ipairs(standartInclinations) do
      local possibleChange = { -1, 1 }
      local increment = 30
      state.randomisationStatus = "significant"
      if spreadBracket < 0.5 then
         state.randomisationStatus = "minor"
         increment = 15
         table.insert(possibleChange, 0)
      end
      local change = possibleChange[math.random(1, #possibleChange)]
      state[param] = util.clamp(state[param] + increment * change, 0, 100)
   end


   local weirdness = luaRandom:random()

   if weirdness >= 0.9 then
      state.weirdnessStatus = "oh, it's weird!"
      for _, param in ipairs(weirdInclinations) do
         if luaRandom:random() < 0.5 then
            state[param] = util.clamp(state[param] + 75, 0, 100) -- Increase by 75 or stay the same
         end
      end
   else
      state.weirdnessStatus = "completely normal, not weird at all."
   end

   local anger = luaRandom:random()
   if anger < CanGoHamProb then
      state.canGoHam = true
   end

   -- Print the modified state for verification
   -- gutils.print(gutils.tableToString(state))
end


-- Functions to determine if its time to flee/ask for mercy
-- Function to interpolate probability based on level difference
local function levelBasedScaredProb()
   -- Author: Mostly ChatGPT 2024
   -- Directly assign numerical values for configuration
   local minLevelDif = -10
   local maxLevelDif = 10
   local minProb = 0.05
   local maxProb = 0.25

   -- Get levels
   local characterLevel = types.Actor.stats.level(omwself).current
   local enemyLevel = types.Actor.stats.level(state.enemyActor).current

   -- Calculate level difference
   local levelDifference = characterLevel - enemyLevel

   -- Clamp levelDifference within the min and max level range
   local clampedLevelDifference = util.clamp(levelDifference, minLevelDif, maxLevelDif)

   -- Normalize level difference within the range
   local normalizedLevelDifference = (clampedLevelDifference - minLevelDif) / (maxLevelDif - minLevelDif)

   -- Interpolate the probability
   local probability = gutils.lerp(minProb, maxProb, normalizedLevelDifference)

   return probability
end

-- Function to calculate if the character is scared
local function isSelfScared(damageValue)
   -- Author: Mostly ChatGPT 2024

   -- Get current health
   local baseHealth = selfActor.stats.dynamic:health().base
   local currentHealth = selfActor.stats.dynamic:health().current


   -- Proceed only if there was actual damage
   if damageValue > 0 then
      local healthFraction = currentHealth / baseHealth
      --print("DAMAGE VALUE", damageValue)
      --print("Health fraction", healthFraction)
      -- Check if health is below 33%
      if healthFraction < 0.33 then
         -- Determine base probability based on level difference
         local baseProbability = levelBasedScaredProb()

         -- Calculate the damage-based factor
         local damageFactor = damageValue / baseHealth

         -- Adjust the probability based on the damage factor
         local adjustedProbability = baseProbability * math.min(damageFactor / 0.05, 1)
         local adjustedProbability = adjustedProbability * ScaredProbModifier

         -- Roll a random number to determine if the character is scared
         local roll = math.random()

         -- If the roll is less than the adjusted probability, character is scared
         -- print("CHANCE TO GET SCARED:", adjustedProbability)
         if roll < adjustedProbability then
            return true
         end
      end
   end

   -- If no damage was taken, health is above 33%, or roll is higher than probability, character is not scared
   return false
end




-- STARTING EVERYTHING -------------------

-- Parsing JSON behaviourtree -----
----------------------------------
-- Read the behaviour tree JSON file exported from the editor---------------
local file = vfs.open("scripts/MaxYari/experiments/OpenMW AI.b3")
if not file then error("Failed opening behaviour tree file.") end
-- Decode it
local projectJsonTable = json.decode(file:read("*a"))
-- And close it
file:close()
----------------------------------------------------------------------------

-- Initialise behaviour trees ----------------------------------------------
gutils.print("Loading Behavior3 project")
local bTrees = BT.LoadBehavior3Project(projectJsonTable, state)
bTrees.Combat:setDebugLevel(0)
bTrees.CombatAux:setDebugLevel(0)
bTrees.Locomotion:setDebugLevel(0)
-- Ready to use! -----------------------------------------------------------




-- Defining variables used by the main update functions
StandGroundProbModifier = 1
ScaredProbModifier = 1
CanGoHamProb = 0.5
BaseFriendFightVal = 80
AvengeShoutProb = 0.5
-- TO DO: Comment this out for production
StandGroundProbModifier = 1e42
ScaredProbModifier = 1e42
CanGoHamProb = 1
BaseFriendFightVal = 30
AvengeShoutProb = 1


local lastWeaponRecord = { id = "_" }
local lastAiPackage = { type = nil }
local lastAiOverrideState = false
local lastHealth = selfActor.stats.dynamic:health().current
local lastDeadState = nil
local lastGoHamCheck = 0
local fleedOnce = false
local askedForMercyOnce = false
local stoodGroundOnce = false

-- Rndomising key npc factors
luaRandom:randomseed(gutils.stringToHash(omwself.recordId))
randomiseInclinations()




-- Main update function (finally) --
------------------------------------
local function onUpdate(dt)
   -- Always track HP, for damage events
   local currentHealth = selfActor.stats.dynamic:health().current
   local damageValue = lastHealth - currentHealth
   state.damageValue = damageValue
   lastHealth = currentHealth

   -- Time
   local now = core.getRealTime()

   -- Sending on Damaged events
   if damageValue > 0 then
      gutils.forEachNearbyActor(2000, function(actor)
         if types.Player.objectIsInstance(actor) or actor == omwself.object then return end
         actor:sendEvent('FriendDamaged', { source = omwself.object })
      end)
   end

   -- Sending on Death events
   local deathState = selfActor:isDead()
   if lastDeadState ~= nil and lastDeadState ~= deathState then
      if deathState then
         gutils.forEachNearbyActor(1000, function(actor)
            if types.Player.objectIsInstance(actor) or actor == omwself.object then return end
            actor:sendEvent('FriendDead', { source = omwself.object })
         end)
      end
   end
   lastDeadState = deathState

   -- Only modify AI if it's in combat and is melee and not a caster and not dead!
   local AiOverrideState = true
   local activeAiPackage = AI.getActivePackage()
   local enemyActor = AI.getActiveTarget("Combat")
   if not activeAiPackage or activeAiPackage.type ~= "Combat" or gutils.imASpellCaster() or selfActor:isVampire() or selfActor:isRanged() or selfActor:isDead() then
      AiOverrideState = false
   end

   -- Storing combat targets in history
   gutils.addTargetsToHistory(I.AI.getTargets("Combat"))

   -- If we started overriding AI - determine which combat state to begin in
   if lastAiPackage.type ~= activeAiPackage.type and activeAiPackage.type == "Combat" then
      -- Initialising combat state
      local isGuard = gutils.imAGuard()
      local fightBias = selfActor.stats.ai:fight().modified
      local dispBias = gutils.getFightDispositionBias(omwself, enemyActor)
      local fightValue = fightBias + dispBias
      local standGroundProb = util.clamp(util.remap(fightValue, 85, 100, 0.9, 0), 0, 0.9)
      standGroundProb = standGroundProb * StandGroundProbModifier
      -- gutils.print("STAND GROUND PROBABILITY", standGroundProb, " Fight val: ", fightBias, dispBias, 1)
      if luaRandom:random() <= standGroundProb and not stoodGroundOnce and not isGuard and damageValue <= 0 then
         state.combatState = enums.COMBAT_STATE.STAND_GROUND
         stoodGroundOnce = true
      else
         state.combatState = enums.COMBAT_STATE.FIGHT
      end
   end

   if AiOverrideState and AiOverrideState ~= lastAiOverrideState then
      core.sound.stopSay(omwself);
      -- If ai override happened in middle of combat - ensure that we won't go into STAND_GROUND state
      if lastAiPackage.type == "Combat" then
         state.combatState = enums.COMBAT_STATE.FIGHT
      end
   end

   lastAiPackage = activeAiPackage
   lastAiOverrideState = AiOverrideState

   -- Disabling AI so everything can be controlled by the ~Mercy~
   omwself:enableAI(not AiOverrideState)
   -- If we are NOT overriding AI - leave
   if not AiOverrideState then return end
   

   -- Provide Behaviour Tree state with the necessary info --------------
   ----------------------------------------------------------------------
   state:clear()

   state.dt = dt
   state.enemyActor = enemyActor

   if state.enemyActor then
      state.range = gutils.getDistanceToBounds(omwself, state.enemyActor)
   else
      state.range = 1e42
   end

   -- Get weapon stats
   local weaponObj = selfActor:getEquipment(types.Actor.EQUIPMENT_SLOT.CarriedRight)
   local weaponRecord = { id = nil }
   if weaponObj then weaponRecord = types.Weapon.record(weaponObj.recordId) end

   if weaponRecord.id ~= lastWeaponRecord.id then
      if weaponRecord.id then
         state.weaponAttacks = gutils.getSortedAttackTypes(weaponRecord)
         state.weaponSkill = itemutil.getSkillStatForEquipment(omwself, weaponObj).modified
         state.reach = weaponRecord.reach * fCombatDistance * 0.95
      else
         -- We are using hand-to-hand
         state.weaponAttacks = gutils.getSortedAttackTypes(nil)
         state.weaponSkill = types.NPC.stats.skills.handtohand(omwself).modified
         state.reach = fHandToHandReach * fCombatDistance * 0.95
      end
      lastWeaponRecord = weaponRecord
   end

   -- Determine movement speed
   --local walkSpeed = selfActor:getWalkSpeed()
   --state.slowSpeed = gutils.lerp(walkSpeed * 0.5, walkSpeed, speedFactor)
   --state.menaceSpeed = state.slowSpeed * 0.66
   state.slowSpeed = 85 + 25 * state.slowSpeedFactor
   state.menaceSpeed = state.slowSpeed

   -- Track and cleanup the current attack state. If attack group is not playing - it was interrupted.
   if state.attackGroup and not animManager.isPlaying(state.attackGroup) then
      state.attackGroup = nil
      state.attackState = enums.ATTACK_STATE.NO_STATE
   end

   -- And the same for stagger state
   if state.staggerGroup and not animManager.isPlaying(state.staggerGroup) then
      state.staggerGroup = nil
   end

   -- Check for fleeing/mercy
   local scared = isSelfScared(damageValue) -- Since this tracks lastHP - better check it every frame
   if (state.combatState == enums.COMBAT_STATE.FIGHT or state.combatState == enums.COMBAT_STATE.STAND_GROUND) and scared then
      local potentialStates = {}
      if not fleedOnce then table.insert(potentialStates, enums.COMBAT_STATE.FLEE) end
      if not askedForMercyOnce then table.insert(potentialStates, enums.COMBAT_STATE.MERCY) end
      if #potentialStates > 0 then
         local newState = potentialStates[math.random(1, #potentialStates)]
         state.combatState = newState
         if state.combatState == enums.COMBAT_STATE.FLEE then fleedOnce = true end
         if state.combatState == enums.COMBAT_STATE.MERCY then askedForMercyOnce = true end
      end
   end

   -- Check for going ham
   if state.combatState == enums.COMBAT_STATE.FIGHT and state.canGoHam and not state.goingHam then
      -- Whenever we are damaged, but not more frequent than once 0.25 sec
      if damageValue > 0 and now - lastGoHamCheck >= 0.25 then
         -- And if we are damaged more frequently than once a second
         if now - lastGoHamCheck < 1 then
            state.goHamHeat = state.goHamHeat + 0.2
            state.goingHam = math.random() < state.goHamHeat
         end
         lastGoHamCheck = now
      end
   end

   -- Reduce goHamHeat overtime
   state.goHamHeat = state.goHamHeat - 0.1 * dt
   if state.goHamHeat < 0 then
      state.goHamHeat = 0
      state.goingHam = false
   end

   -- Running behaviour trees! -----------------------------
   ---------------------------------------------------------
   bTrees["Combat"]:run()
   bTrees["CombatAux"]:run()
   bTrees["Locomotion"]:run()


   -- Apply state properties modified by behavior trees to actor controls ----
   if state.stance ~= selfActor:getStance() then
      selfActor:setStance(state.stance)
   end
   omwself.controls.run = state.run
   omwself.controls.movement = state.movement
   omwself.controls.sideMovement = state.sideMovement
   omwself.controls.use = state.attack
   omwself.controls.jump = state.jump

   -- If no lookDirection provided - default behaviour is to stare at the enemy
   -- If an attack is in progress - force look at the enemyActor
   local lookDirection
   if state.attackState == enums.ATTACK_STATE.NO_STATE then
      lookDirection = state.lookDirection
   end
   if not lookDirection and state.enemyActor then
      lookDirection = state.enemyActor.position - omwself.position
   end
   if lookDirection then
      omwself.controls.yawChange = gutils.lerpClamped(0,
         -moveutils.lookRotation(omwself, omwself.position + lookDirection), dt * 3)
   end
end

-- TO DO: Test this again, last time I was fighting vanilla ai actor - friends were ignoring that.
local function onFriendDamaged(e)
   --gutils.print("Oh no, ", e.source.recordId, " got damaged!")
   if state.combatState == enums.COMBAT_STATE.STAND_GROUND then
      state.combatState = enums.COMBAT_STATE.FIGHT
   end
end

-- TO DO: What if a guard kills a monster? Probably need to store last few seconds of targets and check if this was ever targeted
local avengeSaid = false
local function onFriendDead(e)
   --gutils.print("Oh no, ", e.source.recordId, " is dead!")
   if state.combatState == enums.COMBAT_STATE.FIGHT and gutils.isMyFriend(e.source) and math.random() < AvengeShoutProb and not avengeSaid then
      print("Saying")
      voiceManager.say(omwself, nil, "FriendDead")
      avengeSaid = true
   end
end


-- Animation handlers --------
------------------------------
I.AnimationController.addPlayBlendedAnimationHandler(function(groupname, options)
   --print("New animation started! " .. groupname .. " : " .. options.startkey .. " --> " .. options.stopkey)
   if gutils.stringStartsWith(groupname, "hit") then
      state.staggerGroup = groupname
   end
end)

-- In the text key handler: Theres no way to know for which bonegroup the text key was triggered?
I.AnimationController.addTextKeyHandler(nil, function(groupname, key)
   --print("Animation text key! " .. groupname .. " : " .. key)
   --print("Position of the key: " .. tostring(animation.getTextKeyTime(omwself.object, groupname .. ": " .. key)))

   if string.find(key, "chop") or string.find(key, "thrust") or string.find(key, "slash") then
      state.attackState = enums.ATTACK_STATE.WINDUP_START
      state.attackGroup = groupname
   end

   if string.find(key, "min attack") then
      state.attackState = enums.ATTACK_STATE.WINDUP_MIN
   end

   if string.find(key, "max attack") then
      -- Attack is being held here, but this event will also trigger at the beginning of release
      state.attackState = enums.ATTACK_STATE.WINDUP_MAX
   end

   if string.find(key, "min hit") then
      --Changing state to release on min hit is good enough
      state.attackState = enums.ATTACK_STATE.RELEASE_START
   elseif string.find(key, "hit") then
      state.attackState = enums.ATTACK_STATE.RELEASE_HIT
   end

   if string.find(key, "follow start") then
      state.attackState = enums.ATTACK_STATE.FOLLOW_START
   end

   if string.find(key, "follow stop") then
      state.attackState = enums.ATTACK_STATE.NO_STATE
      state.attackGroup = nil
   end
end)

-- Engine handlers -----------
------------------------------
return {
   engineHandlers = {
      onUpdate = onUpdate,
   },
   eventHandlers = { FriendDamaged = onFriendDamaged, FriendDead = onFriendDead },
}
