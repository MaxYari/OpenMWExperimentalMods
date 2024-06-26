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




DebugLevel = 2

-- For testing
gutils.print("Trying to use improved AI on " .. omwself.object.recordId)
if omwself.object.recordId ~= "heddvild" then return end

gutils.print("Improved AI is ON")

local attackStates = {
   NO_STATE = 0,
   WINDUP_START = 1,
   WINDUP_MIN = 2,
   WINDUP_MAX = 3,
   RELEASE_START = 4,
   RELEASE_HIT = 5,
   FOLLOW_START = 6
}

local state = {
   -- Doesn't reset every frame
   attackState = attackStates.NO_STATE,
   attackGroup = nil,
   dt = 0,
   reach = 140,
   locomotion = nil,
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
      return self.attackState == attackStates.WINDUP_MIN or self.attackState == attackStates.WINDUP_MAX
   end,

   clear = function(self)
      -- Resets every frame
      self.run = true
      self.jump = false
      self.attack = 0
      self.attackDirection = nil
      self.movement = 0
      self.sideMovement = 0
      self.range = 1e42
      self.lookDirection = nil
   end
}

local fCombatDistance = core.getGMST("fCombatDistance")


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
      local movement, sideMovement, run = navService:run({
         desiredSpeed = task.desiredSpeed,
         ignoredObstacleObject = task
             .targetActor
      })

      local proximity = 0
      if props.proximity then proximity = props.proximity() end
      if (task.targetActor.position - omwself.position):length() <= proximity or navService:isPathCompleted() then
         return task:success()
      end

      -- Add velocity based failer

      state.movement, state.sideMovement, state.run = movement, sideMovement, run

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

      self.velocitySampler = gutils.MeanSampler:new(0.75)

      self.runSpeed = types.Actor.getRunSpeed(omwself)
      self.walkSpeed = types.Actor.getWalkSpeed(omwself)
      self.bounds = types.Actor.getPathfindingAgentBounds(omwself)

      self.desiredSpeed = props.speed()
      if not self.desiredSpeed or self.desiredSpeed == -1 then
         self.desiredSpeed = self.runSpeed
      elseif self.desiredSpeed > self.runSpeed then
         self.desiredSpeed = self.runSpeed
      end

      gutils.print("Move direction: " .. props.direction(), 2)

      config.run(self, state) --Repeater breaks if this reports success or fail
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

      -- -- Probably should ditch that as well
      -- -- Track mean value of velocity (time window 0.3sec), if it drops too low - we are probably stuck running inplace
      -- if self.lastPos and selfActor.canMove() then
      --    self.velocitySampler:sample((self.lastPos - currentPos):length() / state.dt)
      --    if self.velocitySampler.warmedUp and self.velocitySampler.mean <= 20 then
      --       gutils.print("Move finished due to low velocity " .. self.velocitySampler.mean, 2)
      --       shouldAbort = true
      --    end
      -- end

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
      state.attack = omwself.ATTACK_TYPE.Chop
   end
   config.run = function(self, state)
      if self.attackRequested then
         if state.attackState == attackStates.NO_STATE then
            return self:fail()
         end
      else
         self.attackRequested = true
         -- state.attackDirection = util.vector2(1, 0)
      end

      if state.attackState == config.successAttackState then
         return self:success()
      end

      if state.attackState > attackStates.WINDUP_MAX then
         return self:success()
      end

      state.attack = omwself.ATTACK_TYPE.Chop

      return self:running()
   end

   return BT.Task:new(config)
end

function StartSmallAttack(config)
   config.successAttackState = attackStates.WINDUP_MIN
   return StartAttack(config)
end

function StartFullAttack(config)
   config.successAttackState = attackStates.WINDUP_MAX
   return StartAttack(config)
end

BT.register('StartSmallAttack', StartSmallAttack)
BT.register('StartFullAttack', StartFullAttack)

function HoldAttack(config)
   local hodl = function(self, state)
      if state.attackState ~= attackStates.WINDUP_MAX then
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
      if not self.started and state.attackState == attackStates.WINDUP_MAX then
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
      if state.attackState == attackStates.NO_STATE then
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
            if gameObject.recordId ~= "player" and fightVal.modified >= 60 then
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
   state.dt = dt

   -- Ignore native ai behaviour if its a Combat behaviour
   local activeAiPackage = AI.getActivePackage()
   if activeAiPackage and activeAiPackage.type == "Combat" then
      -- Combat is completely handled by behaviour trees
      omwself:enableAI(false)
   else
      omwself:enableAI(true)
      if not activeAiPackage then
         print("No AI package :()")
      end
      return
   end

   local combatTarget = AI.getActiveTarget("Combat")
   state.enemyActor = combatTarget

   -- Provide Behaviour Tree state with the necessary info
   if combatTarget then
      state.range = gutils.getDistanceToBounds(omwself, combatTarget)
   end
   local weaponObj = selfActor.getEquipment(types.Actor.EQUIPMENT_SLOT.CarriedRight)
   if weaponObj then
      local weaponRecord = types.Weapon.record(weaponObj.recordId)
      state.reach = weaponRecord.reach * fCombatDistance
   end

   -- Verify that attack animation matching the current attackGroup is still playing - if its not - probably it was interrupted - cleaning attack state.
   if state.attackGroup then
      local animTime = anim.getCurrentTime(omwself, state.attackGroup)
      if not animTime then
         state.attackGroup = nil
         state.attackState = attackStates.NO_STATE
      end
   end

   -- Run behaviour trees!
   bTrees["Combat"]:run()
   bTrees["CombatAux"]:run()
   bTrees["Locomotion"]:run()


   -- Apply the results of Behaviour Tree run to the actor
   omwself.controls.run = state.run
   if state.attackDirection then
      gutils.print(state.attackDirection, "attack direction requested", state.attack, 2)
      -- Attack task can request specific movement direction to execute specific attack
      omwself.controls.sideMovement = state.attackDirection.x
      omwself.controls.movement = state.attackDirection.y
   else
      omwself.controls.movement = state.movement
      omwself.controls.sideMovement = state.sideMovement
   end


   omwself.controls.use = state.attack
   omwself.controls.jump = state.jump

   if not state.lookDirection and state.enemyActor then
      state.lookDirection = state.enemyActor.position - omwself.position
   end
   if state.lookDirection then
      omwself.controls.yawChange = gutils.lerpClamped(0,
         -moveutils.lookRotation(omwself, omwself.position + state.lookDirection), dt * 3)
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
      state.attackState = attackStates.WINDUP_START
      state.attackGroup = groupname
   end

   if string.find(key, "min attack") then
      state.attackState = attackStates.WINDUP_MIN
   end

   if string.find(key, "max attack") then
      -- Attack is being held here, but this event will also trigger at the beginning of release
      state.attackState = attackStates.WINDUP_MAX
      --print("Attack hold key time: " .. tostring(anim.getTextKeyTime(omwself.object, key)))
   end

   if string.find(key, "min hit") then
      --Changing state to release on min hit is good enough
      state.attackState = attackStates.RELEASE_START
   elseif string.find(key, "hit") then
      state.attackState = attackStates.RELEASE_HIT
   end

   if string.find(key, "follow start") then
      state.attackState = attackStates.FOLLOW_START
   end

   if string.find(key, "follow stop") then
      state.attackState = attackStates.NO_STATE
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
