-- Mod files
local gutils = require("utils/gutils")
local moveutils = require("utils/movementutils")
local NavigationService = require("utils/navservice")

-- OpenMW libs
local omwself = require('openmw.self')
local selfActor = gutils.Actor:new(omwself)
local core = require('openmw.core')
local AI = require('openmw.interfaces').AI
local vfs = require('openmw.vfs')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local anim = require('openmw.animation')
local types = require('openmw.types')
local nearby = require('openmw.nearby')

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

DebugLevel = 2

-- For testing
gutils.print("Trying to use improved AI on " .. omwself.object.recordId)
if omwself.object.recordId ~= "heddvild" then return end

gutils.print(omwself.object.recordId .. ": Improved AI is ON")

local ATTACK_STATE = {
   NO_STATE = 0,
   WINDUP_START = 1,
   WINDUP_MIN = 2,
   WINDUP_MAX = 3,
   RELEASE_START = 4,
   RELEASE_HIT = 5,
   FOLLOW_START = 6
}

local state = {
   -- Persistent state fields
   attackState = ATTACK_STATE.NO_STATE,
   attackGroup = nil,
   dt = 0,
   reach = 140,
   locomotion = nil,
   engageRange = 600,

   -- Inclinations
   standGroundInc = 0,
   fleeInc = 0,
   goHamInc = 0,
   chargeInc = 50,
   rootedAttackInc = 50,
   moveStopInc = 100,
   moveCircleInc = 100,
   moveBackInc = 100,

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
      if not self.weaponRecord then return math.random(1, 2) end
      --types.SkillStats.bluntweapon(omwself)
      --self.weaponRecord.type
      local skill = gutils.getWeaponSkill(self.weaponRecord)
      if skill >= 75 then
         return math.random(2, 4)
      elseif skill >= 40 then
         return math.random(1, 3)
      else
         return math.random(1, 2)
      end
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

   config.start = function(self, state)
      self.lastPos = omwself.position
      self.coveredDistance = 0

      self.runSpeed = types.Actor.getRunSpeed(omwself)
      self.walkSpeed = types.Actor.getWalkSpeed(omwself)
      self.desiredSpeed = props.speed()
      self.bounds = types.Actor.getPathfindingAgentBounds(omwself)

      gutils.print("Move direction: " .. props.direction(), 2)

      config.run(self, state)
   end

   config.run = function(self, state)
      if not state.enemyActor then
         return self:fail()
      end

      local currentPos = omwself.position
      self.coveredDistance = self.coveredDistance + (currentPos - self.lastPos):length()

      -- Vector magic to calculate a run direction
      local lookDir = (state.enemyActor.position - omwself.object.position):normalize()
      local lookDir2D = util.vector2(lookDir.x, lookDir.y)
      local directionMult
      if props.direction() == "forward" then
         directionMult = 0
      elseif props.direction() == "left" then
         directionMult = 1
      elseif props.direction() == "right" then
         directionMult = -1
      elseif props.direction() == "back" then
         directionMult = 2
      else
         error("Wrong direction property passed into MoveInDirection. Direction: " .. tostring(props.direction()))
      end

      local moveDir2D = lookDir2D:rotate(directionMult * math.pi / 2)
      local moveDir3D = util.vector3(moveDir2D.x, moveDir2D.y, 0):normalize()

      local canMove, reason = navService:canMoveInDirection(moveDir3D)

      local shouldAbort = false

      if not canMove then
         gutils.print("Move finished due to: " .. reason)
         shouldAbort = true
      end

      -- Abort if should
      if shouldAbort then
         if self.coveredDistance > props.distance() * 0.33 then
            -- Atleast we moved some distance, consider it a success
            return self:success()
         else
            -- We barely moved, its a fail
            return self:fail()
         end
      end

      -- Done if we covered required distance
      if self.coveredDistance > props.distance() then
         gutils.print("Move success since distance was covered", 2)
         return self:success()
      end

      -- Calculating speed
      local speedMult, shouldRun = moveutils.calcSpeedMult(self.desiredSpeed, self.walkSpeed, self.runSpeed)
      state.run = shouldRun

      -- And movement values!
      local movement, sideMovement = moveutils.calculateMovement(omwself.object,
         moveDir3D)
      state.movement, state.sideMovement = movement * speedMult, sideMovement * speedMult

      self.lastPos = currentPos

      if self["running"] then return self:running() end
      -- we are also running this run() method on start() to avoid having gaps between movements on repeated tasks
      -- but on start() we won't have running status reporter available, so just ignore if thats the case
   end

   return BT.Task:new(config)
end

BT.register('MoveInDirection', MoveInDirection)


function Jump(config)
   config.run = function(task, state)
      state.jump = true
      task:success()
      --task:fail()
      --task:running()
   end
   return BT.Task:new(config)
end

BT.register('Jump', Jump)

function StartAttack(config)
   config.start = function(self, state)
      -- Pick the best attack type accounting for the weapon skill and some randomness
      if state.weaponRecord then
         local attacks = gutils.getSortedAttackTypes(state.weaponRecord)
         local goodAttacks = gutils.getGoodAttacks(attacks)
         local attack

         local skill = gutils.getWeaponSkill(state.weaponRecord)
         local prob = util.clamp(util.remap(skill, 0, 75, 0, 100), 0, 90)

         if math.random() * 100 < prob then
            -- if random less than weapon skill (rescale to 0-75 skill, and clamp chance to 0-90)
            attack = gutils.pickWeightedRandomAttackType(goodAttacks)
         else
            -- otherwise pure random
            attack = attacks[math.random(0, #attacks)]
         end

         self.ATTACK_TYPE = omwself.ATTACK_TYPE[attack.type]
      else
         self.ATTACK_TYPE = omwself.ATTACK_TYPE.Thrust
      end

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

   config.isStealthy = true

   config.registered = function(self, state)
      self.duration = p.duration()
      self.heldFrom = nil
   end

   config.shouldInterrupt = function(self, state)
      local now = core.getRealTime()
      if not self.started and state.attackState == ATTACK_STATE.WINDUP_MAX then
         if not self.heldFrom then
            self.heldFrom = now
         end
         if now - self.heldFrom > self.duration then
            return true
         end
      else
         self.heldFrom = nil
      end
   end

   config.start = function(self, state)
      self.started = true
   end

   config.finish = function(self, state)
      self.started = false
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
bTrees.Locomotion:setDebugLevel(0)
-- Ready to use! -----------------------------------------------------------


-- Doing some inventory stuff --
-- This should be used to give marksmen swords and send them into melee
local inventory = selfActor.inventory()
print("Inventory resolved:", inventory:isResolved())
local weapons = inventory:getAll(types.Weapon)
print("Following weapons found in the inventory")
for i, weaponObj in pairs(weapons) do
   local isEquipped = selfActor.hasEquipped(weaponObj)
   local weaponRecord = types.Weapon.record(weaponObj.recordId)
   print("i: " ..
      i ..
      " recordId: " ..
      weaponObj.recordId ..
      " name: " ..
      weaponRecord.name ..
      " type: " .. weaponRecord.type .. " reach: " .. weaponRecord.reach .. " equipped: " .. tostring(isEquipped))
end


-- Main update function (finally) --
------------------------------------

local function onUpdate(dt)
   -- Reset everything
   state:clear()

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
      return
   end

   omwself:enableAI(not aiOverride)

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
      state.reach = state.weaponRecord.reach * fCombatDistance
   end

   -- Verify that attack animation matching the current attackGroup is still playing - if its not - probably it was interrupted - cleaning attack state.
   if state.attackGroup then
      local animTime = anim.getCurrentTime(omwself, state.attackGroup)
      if not animTime then
         state.attackGroup = nil
         state.attackState = ATTACK_STATE.NO_STATE
      end
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

      -- If no lookDirection provided - default behaviour
      local lookDirection = state.lookDirection
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
   --print("Position of the key: " .. tostring(anim.getTextKeyTime(omwself.object, groupname .. ": " .. key)))

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
      --print("Attack hold key time: " .. tostring(anim.getTextKeyTime(omwself.object, key)))
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
