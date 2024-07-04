-- Mod files
local gutils = require("utils/gutils")
local moveutils = require("utils/movementutils")
local NavigationService = require("utils/navservice")
local itemutil = require("utils/item_util")

-- OpenMW libs
local omwself = require('openmw.self')
local selfActor = gutils.Actor:new(omwself)
local core = require('openmw.core')
local AI = require('openmw.interfaces').AI
local vfs = require('openmw.vfs')
local util = require('openmw.util')
local types = require('openmw.types')
local nearby = require('openmw.nearby')
local I = require('openmw.interfaces')
local animation = require('openmw.animation')


-- 3rd party libs
-- Setup important global functions for the behaviourtree 2e module to use--
_BehaviourTreeImports = {
   loadCodeInScope = util.loadCode,
   clock = core.getRealTime
}
local BT = require('behaviourtree/behaviour_tree')
local json = require("json")
----------------------------------------------------------------------------

local fCombatDistance = core.getGMST("fCombatDistance")
local fHandToHandReach = core.getGMST("fHandToHandReach")

DebugLevel = 2

-- For testing
gutils.print("Trying to use improved AI on " .. omwself.recordId .. " " .. omwself.id)
if omwself.recordId ~= "heddvild" then return end

local animService = require("utils.animservice")

gutils.print(omwself.recordId .. ": Improved AI is ON")

math.randomseed(omwself.id)

local ATTACK_STATE = {
   NO_STATE = 0,
   WINDUP_START = 1,
   WINDUP_MIN = 2,
   WINDUP_MAX = 3,
   RELEASE_START = 4,
   RELEASE_HIT = 5,
   FOLLOW_START = 6
}

local COMBAT_STATE = {
   STAND_GROUND = 0,
   FIGHT = 1,
   FLEE = 2,
   MERCY = 3
}


local state = {
   -- Persistent state fields
   COMBAT_STATE = COMBAT_STATE,
   attackState = ATTACK_STATE.NO_STATE,
   combatState = COMBAT_STATE.FIGHT,
   attackGroup = nil,
   dt = 0,
   reach = 140,
   locomotion = nil,
   engageRange = 600,
   slowSpeed = 10,

   -- Inclinations and probabilities
   -- Inclinations are used directly within a tree
   -- Probabilities are rolled agains in the main loop
   standGroundProbability = 0,
   fleeProbability = 0,

   goHamInc = 0,
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
   rint = function(m, n)
      return math.random(m, n)
   end,
   isHoldingAttack = function(self)
      return self.attackState == ATTACK_STATE.WINDUP_MIN or self.attackState == ATTACK_STATE.WINDUP_MAX
   end,
   attacksFromSkill = function(self)
      if not self.weaponSkill then return math.random(1, 2) end

      local skill = self.weaponSkill
      if skill >= 75 then
         return math.random(2, 4)
      elseif skill >= 40 then
         return math.random(1, 3)
      else
         return math.random(1, 2)
      end
   end,
   attPauseFromSkill = function(self)
      if not self.weaponSkill then return 0 end

      local skill = self.weaponSkill
      local duration = util.remap(skill, 0, 75, 0.6, 0)
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


local navService = NavigationService({
   cacheDuration = 1,
   targetPosDeadzone = 50,
   pathingDeadzone = 35
})


-- Custom behaviours ------------------
---------------------------------------


function ChaseTarget(config)
   local props = config.properties


   config.start = function(task, state)
      config.findTargetActor(task, state)
      task.desiredSpeed = -1
      if props.speed then task.desiredSpeed = props.speed() end
   end

   config.run = function(task, state)
      config.findTargetActor(task, state)
      if not task.targetActor or types.Actor.isDead(task.targetActor) then
         return task:fail()
      end

      navService:setTargetPos(task.targetActor.position)
      local movement, sideMovement, run, lookDirection = navService:run({
         desiredSpeed = task.desiredSpeed,
         ignoredObstacleObject = task
             .targetActor
      })

      local proximity = 0
      local distance = gutils.getDistanceToBounds(task.targetActor, omwself)
      if props.proximity then proximity = props.proximity() end
      if distance <= proximity or navService:isPathCompleted() then
         return task:success()
      end


      state.movement, state.sideMovement, state.run, state.lookDirection = movement, sideMovement, run, lookDirection
      if config.getLookDirection and config.getLookDirection(task, state) then
         state.lookDirection = config
             .getLookDirection(task, state)
      end

      return task:running()
   end

   return BT.Task:new(config)
end

function MoveInDirection(config)
   -- Directions are relative to the direction from actor to its target, i.e closer to target, further, strafe around to the right and to the left.
   local props = config.properties

   config.name = config.name .. " " .. tostring(props.direction())

   config.start = function(self, state)
      self.lastPos = omwself.position
      self.coveredDistance = 0
      self.startedAt = core.getRealTime()

      self.runSpeed = selfActor.getRunSpeed()
      self.walkSpeed = selfActor.getWalkSpeed()
      self.desiredSpeed = props.speed()
      if self.desiredSpeed == -1 then self.desiredSpeed = self.runSpeed end
      self.desiredDistance = props.distance()
      if props.lookAt then self.lookAt = props.lookAt() end
      self.bounds = selfActor.getPathfindingAgentBounds()
      self.timeLimit = self.desiredDistance / self.desiredSpeed + 1.5

      config.run(self, state)
   end

   config.run = function(self, state)
      if not state.enemyActor then
         return self:fail()
      end

      local now = core.getRealTime()
      local currentPos = omwself.position
      self.coveredDistance = self.coveredDistance + (currentPos - self.lastPos):length()

      -- Vector magic to calculate a run direction
      local dirToEnemy = (state.enemyActor.position - omwself.object.position):normalize()
      local moveDir = moveutils.directionRelativeToVec(dirToEnemy, props.direction())

      local canMove, reason = navService:canMoveInDirection(moveDir)

      local shouldAbort = false

      if not canMove then
         gutils.print("Move finished due to: " .. reason)
         shouldAbort = true
      end

      -- Measure time passed and abort if more than distance/speed + 1.5 have passed
      if now - self.startedAt >= self.timeLimit then
         gutils.print("Move finished due to time limit of " .. self.timeLimit .. " have been reached.")
         shouldAbort = true
      end

      -- Abort if should
      if shouldAbort then
         if self.coveredDistance > self.desiredDistance * 0.33 then
            -- Atleast we moved some distance, consider it a success
            return self:success()
         else
            -- We barely moved, its a fail
            return self:fail()
         end
      end

      -- Done if we covered required distance
      if self.coveredDistance > self.desiredDistance then
         gutils.print("Move success since distance was covered", 2)
         return self:success()
      end

      -- Calculating speed
      local speedMult, shouldRun = moveutils.calcSpeedMult(self.desiredSpeed, self.walkSpeed, self.runSpeed)
      state.run = shouldRun

      -- And movement values!
      local movement, sideMovement = moveutils.calculateMovement(omwself.object,
         moveDir)
      state.movement, state.sideMovement = movement * speedMult, sideMovement * speedMult
      if self.lookAt == "ahead" then
         state.lookDirection = moveDir
      end


      self.lastPos = currentPos

      if self["running"] then return self:running() end
      -- we are also running this run() method on start() to avoid having gaps between movements on repeated tasks
      -- but on start() we won't have running status reporter available, so just ignore if thats the case
   end

   return BT.Task:new(config)
end

BT.register('MoveInDirection', MoveInDirection)


function JumpInDirection(config)
   local props = config.properties

   config.start = function(self, state)
      self.startedAt = core.getRealTime()
      self.warmupTime = 0.5
      self.justStarted = true
      -- Here we only start moving
      config.run(self, state)
   end

   config.run = function(self, state)
      if not state.enemyActor then
         return self:fail()
      end

      local now = core.getRealTime()

      -- Vector magic to calculate a run direction
      local dirToEnemy = (state.enemyActor.position - omwself.object.position):normalize()
      local moveDir = moveutils.directionRelativeToVec(dirToEnemy, props.direction())

      local canMove, reason = navService:canMoveInDirection(moveDir, types.Actor.getRunSpeed(omwself))

      if not canMove then
         gutils.print("Jump aborted due to: " .. reason)
         return self:fail()
      end

      if now - self.startedAt >= self.warmupTime and selfActor.isOnGround() then
         gutils.print("Jump is finished since actor is on ground")
         return self:success()
      end

      local movement, sideMovement = moveutils.calculateMovement(omwself.object,
         moveDir)
      state.movement, state.sideMovement = movement, sideMovement
      if self.justStarted then
         self.justStarted = false
      else
         -- Trigger jump on the 2nd frame
         state.jump = true
      end

      if self["running"] then return self:running() end
   end

   return BT.Task:new(config)
end

BT.register('JumpInDirection', JumpInDirection)

function StartAttack(config)
   config.start = function(self, state)
      -- Pick the best attack type accounting for the weapon skill and some randomness

      -- If weaponRecord is nil - this will assume its hand-to-hand
      local attacks = gutils.getSortedAttackTypes(state.weaponRecord)
      local goodAttacks = gutils.getGoodAttacks(attacks)
      -- print("Good attacks: ", #goodAttacks)
      -- for index, value in ipairs(goodAttacks) do
      --    print("Good attack: ", value.type, " avgDmg: ", value.averageDamage)
      -- end
      local attack

      local skill = state.weaponSkill
      local prob = util.clamp(util.remap(skill, 0, 75, 0, 100), 0, 90)

      if math.random() * 100 < prob then
         -- if random less than weapon skill (rescale to 0-75 skill, and clamp chance to 0-90)
         attack = gutils.pickWeightedRandomAttackType(goodAttacks)
      else
         -- otherwise pure random
         attack = attacks[math.random(1, #attacks)]
      end

      self.ATTACK_TYPE = omwself.ATTACK_TYPE[attack.type]

      state.attack = self.ATTACK_TYPE
   end
   config.run = function(self, state)
      if self.attackRequested then
         if state.attackState == ATTACK_STATE.NO_STATE then
            return self:fail()
         end
      else
         self.attackRequested = true
      end

      if state.attackState == config.successAttackState then
         return self:success()
      end

      if state.attackState > ATTACK_STATE.WINDUP_MAX then
         return self:success()
      end

      state.attack = self.ATTACK_TYPE

      return self:running()
   end

   return BT.Task:new(config)
end

function StartSmallAttack(config)
   config.successAttackState = ATTACK_STATE.WINDUP_MIN
   return StartAttack(config)
end

function StartFullAttack(config)
   config.successAttackState = ATTACK_STATE.WINDUP_MAX
   return StartAttack(config)
end

BT.register('StartSmallAttack', StartSmallAttack)
BT.register('StartFullAttack', StartFullAttack)

function HoldAttack(config)
   local hodl = function(self, state)
      if state.attackState ~= ATTACK_STATE.WINDUP_MAX then
         return self:fail()
      else
         state.attack = 1
      end
   end

   config.start = hodl
   config.run = hodl

   return BT.Task:new(config)
end

BT.register('HoldAttack', HoldAttack)

function AttackHoldTimeout(config)
   local p = config.properties
   local duration
   local heldFrom

   config.isStealthy = true

   config.registered = function(self, state)
      duration = p.duration()
      heldFrom = nil
   end

   config.shouldRun = function(self, state)
      local now = core.getRealTime()
      if state.attackState == ATTACK_STATE.WINDUP_MAX then
         if not heldFrom then
            heldFrom = now
         end
      else
         heldFrom = nil
      end

      if heldFrom and now - heldFrom > duration then
         return true
      end

      return false
   end

   return BT.InterruptDecorator:new(config)
end

BT.register("AttackHoldTimeout", AttackHoldTimeout)

function ReleaseAttack(config)
   config.run = function(self, state)
      state.attack = 0
      if state.attackState == ATTACK_STATE.NO_STATE then
         return self:success()
      end
   end

   return BT.Task:new(config)
end

BT.register('ReleaseAttack', ReleaseAttack)

function ChaseEnemy(config)
   config.findTargetActor = function(task, state)
      task.targetActor = state.enemyActor
   end

   config.getLookDirection = function(task, state)
      if state.enemyActor then
         local distanceVec = state.enemyActor.position - omwself.position
         if distanceVec:length() < state.engageRange then
            return distanceVec:normalize()
         end
      end
   end

   return ChaseTarget(config)
end

BT.register('ChaseEnemy', ChaseEnemy)

function RetreatToFriend(config)
   config.findTargetActor = function(task, state)
      if task.targetActor then return end

      for index, gameObject in ipairs(nearby.actors) do
         local fightVal = types.Actor.stats.ai.fight(gameObject)
         gutils.print("Looking at an actor " .. gameObject.recordId)
         if types.NPC.objectIsInstance(gameObject) then
            gutils.print("Is an npc " .. fightVal.modified)
            if gameObject.recordId ~= "player" and fightVal.modified >= 30 then
               gutils.print("Found a fight-ready NPC, seeking their help! Actor is: " .. gameObject.recordId)
               task.targetActor = gameObject
               break
            end
         end
      end
   end

   return ChaseTarget(config)
end

BT.register("RetreatToFriend", RetreatToFriend)

function RetreatBreaker(config)
   -- Mostly written by ChatGPT 2024
   local p = config.properties
   local registeredTime
   local warmupTime
   local dmgProbability
   local lastHealth
   local warmupComplete

   local function resetVars()
      registeredTime = core.getRealTime()
      warmupTime = p.warmup()
      dmgProbability = p.dmgProbability()
      lastHealth = selfActor.stats.dynamic.health().current
      warmupComplete = false
   end

   config.registered = resetVars

   config.shouldRun = function(task)
      if task.started then return true end
      -- Check if warmup period has passed and mark it as complete
      local now = core.getRealTime()
      if (now - registeredTime) >= warmupTime then
         warmupComplete = true
      end

      if not warmupComplete then
         print("Warmup not complete")
         return false
      else
         print("Warmup complete")
      end

      local currentHealth = selfActor.stats.dynamic.health().current
      local baseHealth = selfActor.stats.dynamic.health().base
      local damage = lastHealth - currentHealth
      if damage < 0 then damage = 0 end

      print("damage check")
      -- Check if enough damage was taken
      if damage > 0 then
         -- Calculate damage threshold percentage
         local damagePercentage = damage / baseHealth * 100

         -- Calculate adjusted probability based on damage percentage and dmgProbability range
         local baseProbability = dmgProbability
         local adjustedProbability = util.clamp(baseProbability * (damagePercentage / 10), 0, baseProbability)

         -- Convert dmgProbability from 0-100 range to 0-1 range and clamp it
         adjustedProbability = adjustedProbability / 100

         print("Probability to break retreat with damage percentage:" .. damagePercentage .. " " .. adjustedProbability)

         -- Check if enemy is close enough
         local distance = gutils.getDistanceToBounds(omwself, state.enemyActor)
         local closeEnough = distance < 300

         lastHealth = currentHealth

         -- Check if interrupt conditions are met
         return closeEnough and math.random() <= adjustedProbability
      end

      return false
   end
   config.start = function(task, state)
      task.started = true
   end
   config.finish = function(task, state)
      task.started = false
      resetVars()
   end

   return BT.InterruptDecorator:new(config)
end

BT.register("RetreatBreaker", RetreatBreaker)

function PlayerInsolence(config)
   local p = config.properties

   config.shouldRun = function(task, state)
      if task.started then return true end

      if not state.staringProgress then state.staringProgress = 0 end

      local distance = gutils.getDistanceToBounds(omwself, state.enemyActor)

      local raycast = nearby.castRay(gutils.getActorLookRayPos(omwself),
         gutils.getActorLookRayPos(state.enemyActor), { ignore = omwself })
      --print("Raycast: " .. tostring(raycast.hitObject), omwself.position, state.enemyActor.position)
      if raycast.hitObject and raycast.hitObject == state.enemyActor then
         state.staringProgress = state.staringProgress + state.dt
      end

      if distance <= p.proximity() or state.staringProgress >= p.presenceTime() then
         return true
      end

      -- Check if triggered by enemy damage
      if p.triggerOnDamage() then
         local currentHealth = types.Actor.stats.dynamic.health(state.enemyActor).current

         if state.enemyLastHealth and currentHealth < state.enemyLastHealth then
            return true
         end

         state.enemyLastHealth = currentHealth
      end

      return false
   end

   config.start = function(task, state)
      task.started = true
   end

   config.finish = function(task, state)
      task.started = false
   end

   return BT.InterruptDecorator:new(config)
end

BT.register("PlayerInsolence", PlayerInsolence)

function EnemyIsRanged(config)
   -- Mostly written by ChatGPT 2024
   local p = config.properties
   local reactionTime

   config.registered = function(task, state)
      reactionTime = p.reactionTime()
   end

   config.shouldRun = function(task, state)
      if task.started then return true end

      if not state.enemyActor then
         return false
      end

      -- Check if enemy actor is ranged
      local enemyActor = gutils.Actor:new(state.enemyActor)
      local weaponObj = enemyActor.getEquipment(types.Actor.EQUIPMENT_SLOT.CarriedRight)
      local weaponRecord
      if weaponObj then
         weaponRecord = types.Weapon.record(weaponObj.recordId)
      end
      local stance = enemyActor.getStance()


      if weaponRecord and (weaponRecord.type == types.Weapon.TYPE.MarksmanBow or
             weaponRecord.type == types.Weapon.TYPE.MarksmanCrossbow or
             weaponRecord.type == types.Weapon.TYPE.MarksmanThrown) then
         task.rangedDetectedTime = task.rangedDetectedTime or core.getRealTime()
      elseif stance == types.Actor.STANCE.Spell then
         task.rangedDetectedTime = task.rangedDetectedTime or core.getRealTime()
      else
         -- Reset ranged detected time if not ranged
         task.rangedDetectedTime = nil
      end

      -- Check if enough reaction time has passed
      if task.rangedDetectedTime then
         local currentTime = core.getRealTime()
         if (currentTime - task.rangedDetectedTime) >= reactionTime then
            return true
         end
      end

      return false
   end

   config.start = function(task, state)
      task.started = true
   end

   config.finish = function(task, state)
      task.started = false
   end

   return BT.InterruptDecorator:new(config)
end

BT.register("EnemyIsRanged", EnemyIsRanged)

function LookAround(config)
   local p = config.properties

   config.start = function(task, state)
      task.lastLookChange = 0
      task.period = p.period()
   end

   config.run = function(task, state)
      local now = core.getRealTime()

      if now - task.lastLookChange > task.period then
         task.lastLookChange = now
         task.period = p.period()
         task.lookDirection = gutils.randomDirection()
      end

      state.lookDirection = task.lookDirection
      task:running()
   end

   return BT.Task:new(config)
end

BT.register("LookAround", LookAround)

function SetCombatState(config)
   local p = config.properties

   config.start = function(task, state)
      local stateString = p.state()
      if not COMBAT_STATE[stateString] then
         error("Wrong combat state provided to combat state set.")
      end
      state.combatState = COMBAT_STATE[stateString]
      return task:success()
   end

   return BT.Task:new(config)
end

BT.register("SetCombatState", SetCombatState)

local animationConfigs = {
   surrender_mercy = {
      groupname = "surrender",
      startkey = "start",
      stopkey = "offer start",
      priority = animation.PRIORITY.Hit,
      blendmask = animation.BLEND_MASK.UpperBody
   },
   surrender_offer = {
      groupname = "surrender",
      startkey = "offer start",
      stopkey = "place items",
      priority = animation.PRIORITY.Hit
   },
   surrender_postoffer = {
      groupname = "surrender",
      startkey = "place items",
      stopkey = "stop",
      priority = animation.PRIORITY.Hit
   }
}

function StartAnimation(config)
   local p = config.properties

   config.start = function(task, state)
      local configId = p.animation()
      local animConfig = assert(animationConfigs[configId], "No animation config " .. tostring(configId) .. " found.")

      animService.Animation:play(animConfig.groupname, animConfig)
      task:success()
   end

   return BT.Task:new(config)
end

BT.register("StartAnimation", StartAnimation)

function OnAnimationKey(config)
   local p = config.properties
   local configId = p.animation()
   local animConfig = assert(animationConfigs[configId], "No animation config " .. tostring(configId) .. " found.")

   local shouldStart = false

   local function onKey(groupname, key)
      if groupname == animConfig.groupname and key == p.key() then
         shouldStart = true
      end
   end

   config.registered = function(task, state)
      shouldStart = false
      animService.addOnKeyHandler(onKey)
   end

   config.shouldRun = function(task, state)
      if shouldStart then return true end
   end

   config.finish = function(task, state)
      shouldStart = false
   end

   config.deregistered = function(task, state)
      animService.removeOnKeyHandler(onKey)
   end

   return BT.InterruptDecorator:new(config)
end

BT.register("OnAnimationKey", OnAnimationKey)

function OnAnimationOver(config)
   local p = config.properties
   local configId = p.animation()
   local animConfig = assert(animationConfigs[configId], "No animation config " .. tostring(configId) .. " found.")

   p.key = function()
      return animConfig.stopkey
   end

   return OnAnimationKey(config)
end

BT.register("OnAnimationOver", OnAnimationOver)

function OnAnimationInterrupt(config)
   local p = config.properties
   local configId = p.animation()
   local animConfig = assert(animationConfigs[configId], "No animation config " .. tostring(configId) .. " found.")

   local lastCompletion = nil
   local shouldStart = false

   config.registered = function()
      shouldStart = false
   end

   config.shouldRun = function()
      if shouldStart then return true end

      local completion = animation.getCompletion(omwself, animConfig.groupname)
      if lastCompletion ~= nil and completion == nil and lastCompletion < 0.9 then
         shouldStart = true
      end

      lastCompletion = completion
   end

   config.finish = function()
      shouldStart = false
   end

   return BT.InterruptDecorator:new(config)
end

BT.register("OnAnimationInterrupt", OnAnimationInterrupt)

function PlayAnimation(config)
   local p = config.properties
   local configId = p.animation()
   local animConfig = assert(animationConfigs[configId], "No animation config " .. tostring(configId) .. " found.")

   local lastCompletion = nil

   config.start = function(task, state)
      task.anim = animService.Animation:play(animConfig.groupname, animConfig)
      task.anim.onKey = function(key)
         if key == animConfig.stopkey then task.shouldSucceed = true end
      end
   end

   config.run = function(task, state)
      if task.shouldSucceed then return task:success() end

      -- Often even arrives too late and in breaks with completion clause
      local completion = animation.getCompletion(omwself, animConfig.groupname)
      if lastCompletion ~= nil and completion == nil then
         return task:fail()
      end
      lastCompletion = completion

      return task:running()
   end

   config.finish = function(task, state)
      animation.cancel(omwself, animConfig.groupname)
   end

   return BT.Task:new(config)
end

BT.register("PlayAnimation", PlayAnimation)

function DumpInventory(config)
   config.start = function(task)
      core.sendGlobalEvent("dumpInventory", { actorObject = omwself, position = omwself.position })
      return task:success()
   end

   return BT.Task:new(config)
end

BT.register("DumpInventory", DumpInventory)

function HasDumpableItems(config)
   config.start = function(task)
      if #selfActor:getDumpableInventoryItems() <= 0 then
         return task:fail()
      end
   end

   return BT.Decorator:new(config)
end

BT.register("HasDumpableItems", HasDumpableItems)

function Pacify(config)
   config.start = function(task)
      AI.removePackages("Combat") -- As of right now this makes actors stuck in an Unknown package
      selfActor.stats.ai.fight().base = 30

      task:success()
   end

   return BT.Task:new(config)
end

BT.register("Pacify", Pacify)

--All available dialog voice record types
-- Alarm
-- Attack
-- Flee
-- Hello
-- Hit
-- Idle
-- Intruder
-- Thief

function Say(config)
   local p = config.properties

   config.start = function(task)
      local npc = types.NPC.record(omwself)
      local gender = "female"
      if npc.isMale then gender = "male" end

      local recordType = p.recordType()
      local records = core.dialogue.voice.records[recordType]

      local fittingInfos = {}

      if records then
         for idx, voiceInfo in pairs(records.infos) do
            -- Need to also filter by enemy race and also accept those that are nil?
            if voiceInfo.filterActorRace == npc.race and voiceInfo.filterActorGender == gender then
               table.insert(fittingInfos, voiceInfo)
            end
         end
      else
         task:fail()
         error("Voice record " .. recordType .. " doesn't exist.")
      end

      if #fittingInfos == 0 then
         task:fail()
         error("Some voice records were found for " .. recordType .. " but none of them fit character race and gender.")
      end

      -- Pick random voice file
      print("Fitting voicelines: ", #fittingInfos)
      local voiceInfo = fittingInfos[math.random(1, #fittingInfos)]

      -- Finally say it!
      core.sound.say(voiceInfo.sound, omwself, voiceInfo.text)
      task:success()
   end

   return BT.Task:new(config)
end

BT.register("Say", Say)


local function randomiseInclinations()
   local standartInclinations = { "rootedAttackInc", "nearStopInc", "nearStrafeInc", "nearBackInc", "midStrafeInc",
      "midChaseInc", "midAttackInc", "midStopInc" }
   local weirdInclinations = { "jumpInc", "zoomiesInc" }

   local spreadBracket = math.random()

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


   local weirdness = math.random()

   if weirdness >= 0.9 then
      state.weirdnessStatus = "oh, it's weird!"
      for _, param in ipairs(weirdInclinations) do
         if math.random() < 0.5 then
            state[param] = util.clamp(state[param] + 75, 0, 100) -- Increase by 75 or stay the same
         end
      end
   else
      state.weirdnessStatus = "completely normal, not weird at all."
   end

   state.combatState = COMBAT_STATE.MERCY

   -- Print the modified state for verification
   gutils.print(gutils.tableToString(state))
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
local bTrees = BT.LoadBehavior3Project(projectJsonTable, state)
bTrees.Combat:setDebugLevel(0)
bTrees.CombatAux:setDebugLevel(0)
bTrees.Locomotion:setDebugLevel(1)
-- Ready to use! -----------------------------------------------------------


-- Doing some inventory stuff --
-- This should be used to give marksmen swords and send them into melee




randomiseInclinations()




-- Main update function (finally) --
------------------------------------
local speedFactor = math.random()
local firstRun = true

local function onUpdate(dt)
   -- Reset everything
   state:clear()
   animService:run()

   if firstRun then
      -- AI.removePackages("Combat") -- As of right now this makes actors stuck in an Unknown package
      -- selfActor.stats.ai.fight().base = 30
      -- firstRun = false
   end

   local aiOverride = false

   -- Ignore native ai behaviour if its a Combat behaviour
   local activeAiPackage = AI.getActivePackage()

   if activeAiPackage and activeAiPackage.type == "Combat" then
      -- Combat is completely handled by behaviour trees
      aiOverride = true
   else
      aiOverride = false
      if not activeAiPackage then
         print("No AI package :()")
      end
   end

   omwself:enableAI(not aiOverride)

   --print("Active package: ", activeAiPackage.type)
   if not activeAiPackage or activeAiPackage.type == "Unknown" then
      --print("Unknown package, enabling ai and returning")
      omwself:enableAI(true)
      return
   end

   -- Provide Behaviour Tree state with the necessary info
   state.dt = dt

   local combatTarget = AI.getActiveTarget("Combat")
   state.enemyActor = combatTarget

   if combatTarget then
      state.range = gutils.getDistanceToBounds(omwself, combatTarget)
   end

   local weaponObj = selfActor.getEquipment(types.Actor.EQUIPMENT_SLOT.CarriedRight)
   if weaponObj then
      state.weaponRecord = types.Weapon.record(weaponObj.recordId)
      state.weaponSkill = itemutil.getSkillStatForEquipment(omwself, weaponObj).modified
      state.reach = state.weaponRecord.reach * fCombatDistance * 0.95
   else
      state.weaponRecord = nil
      state.weaponSkill = types.NPC.stats.skills.handtohand(omwself).modified
      state.reach = fHandToHandReach * fCombatDistance * 0.95
      -- We are using hand-to-hand
   end

   local walkSpeed = selfActor.getWalkSpeed()
   state.slowSpeed = gutils.lerp(walkSpeed * 0.5, walkSpeed, speedFactor)
   state.menaceSpeed = state.slowSpeed * 0.66

   --state.zoomiesInc = 75
   --state.jumpInc = 75
   --state.goHamInc = 100
   -----------------------------------------------------------


   -- Verify that attack animation matching the current attackGroup is still playing - if its not - probably it was interrupted - cleaning attack state.
   if state.attackGroup and not animService.isPlaying(state.attackGroup) then
      state.attackGroup = nil
      state.attackState = ATTACK_STATE.NO_STATE
   end



   -- Run behaviour trees!
   bTrees["Combat"]:run()
   bTrees["CombatAux"]:run()
   bTrees["Locomotion"]:run()

   if aiOverride then
      -- Apply the results of Behaviour Tree run to the actor
      omwself.controls.run = state.run
      omwself.controls.movement = state.movement
      omwself.controls.sideMovement = state.sideMovement
      omwself.controls.use = state.attack
      omwself.controls.jump = state.jump

      -- If no lookDirection provided - default behaviour is to stare at the enemy
      local lookDirection
      if state.attackState == ATTACK_STATE.NO_STATE then
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
end


-- Animation handlers --------
------------------------------
-- In the text key handler: Theres no way to know for which bonegroup the text key was triggered?
I.AnimationController.addTextKeyHandler(nil, function(groupname, key)
   --print("Animation text key! " .. groupname .. " : " .. key)
   --print("Position of the key: " .. tostring(animation.getTextKeyTime(omwself.object, groupname .. ": " .. key)))

   --if groupname starts with hit - mark it somehow, or maybe continuously check if groupname is playing
   -- guess save the hit animation, then in onupdate check if its still playing, when hit is still playing - ignore speed stuff

   if string.find(key, "chop") or string.find(key, "thrust") or string.find(key, "slash") then
      state.attackState = ATTACK_STATE.WINDUP_START
      state.attackGroup = groupname
   end

   if string.find(key, "min attack") then
      state.attackState = ATTACK_STATE.WINDUP_MIN
   end

   if string.find(key, "max attack") then
      -- Attack is being held here, but this event will also trigger at the beginning of release
      state.attackState = ATTACK_STATE.WINDUP_MAX
      --print("Attack hold key time: " .. tostring(animation.getTextKeyTime(omwself.object, key)))
   end

   if string.find(key, "min hit") then
      --Changing state to release on min hit is good enough
      state.attackState = ATTACK_STATE.RELEASE_START
   elseif string.find(key, "hit") then
      state.attackState = ATTACK_STATE.RELEASE_HIT
   end

   if string.find(key, "follow start") then
      state.attackState = ATTACK_STATE.FOLLOW_START
   end

   if string.find(key, "follow stop") then
      state.attackState = ATTACK_STATE.NO_STATE
      state.attackGroup = nil
   end
end)

-- Engine handlers -----------
------------------------------
return {
   engineHandlers = {
      onUpdate = onUpdate,
   },
}
