-- OpenMW libs
local omwself = require('openmw.self')
local core = require('openmw.core')
local AI = require('openmw.interfaces').AI
local vfs = require('openmw.vfs')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local anim = require('openmw.animation')
local types = require('openmw.types')
local nearby = require('openmw.nearby')
-- 3rd pary libs
-- Setup important global functions for the behaviourtree 2e module to use--
_BehaviourTreeImports = {
   loadCodeInScope = util.loadCode,
   clock = core.getRealTime
}
----------------------------------------------------------------------------
local BT = require('behaviourtree/behaviour_tree')
local json = require("json")
-- Project files
local gutils = require("utils/gutils")
local moveutils = require("utils/movementutils")
local NavigationService = require("utils/navservice")

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
      self.movement = 0
      self.sideMovement = 0
      self.range = 1e42
   end
}




local navService = NavigationService({
   cacheDuration = 0.5,
   targetPosDeadzone = 70,
   pathingDeadzone = 35
})


-- Custom behaviours ------------------
---------------------------------------


function MoveToTarget(config)
   local props = config.properties

   config.start = function(self, state)
      self.runSpeed = types.Actor.getRunSpeed(omwself)
      self.walkSpeed = types.Actor.getWalkSpeed(omwself)

      self.desiredSpeed = props.speed()
      if not self.desiredSpeed or self.desiredSpeed == -1 then
         self.desiredSpeed = self.runSpeed
      elseif self.desiredSpeed > self.runSpeed then
         self.desiredSpeed = self.runSpeed
      end
   end

   config.run = function(self, state)
      if not state.targetActor then
         return self:fail()
      end

      navService:setTargetPos(state.targetActor.position)

      if (state.targetActor.position - omwself.position):length() <= props.proximity() then
         return self:success()
      end

      -- Calculating speed
      local speedMult, shouldRun = moveutils.calcSpeedMult(self.desiredSpeed, self.walkSpeed, self.runSpeed)
      state.run = shouldRun

      if navService.nextPathPoint then
         state.movement, state.sideMovement = moveutils.calculateMovement(omwself.object,
            navService.nextPathPoint, speedMult)
      end

      return self:running()
   end

   return BT.Task:new(config)
end

BT.register('MoveToTarget', MoveToTarget)



function MoveInDirection(config)
   -- Directions are relative to the direction from actor to its target, i.e closer to target, further, strafe around to the right and to the left.
   local props = config.properties

   config.start = function(self, state)
      self.startPos = omwself.object.position
      self.firstRun = true
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
      if not state.targetActor then
         return self:fail()
      end

      local currentPos = omwself.position

      -- Vector magic to calculate a run direction
      local lookDir = (state.targetActor.position - omwself.object.position):normalize() -- due to the slow pathing refresh this doesnt result in strafing around, but rather in noticeable step to the side. Would be better with shorter strafes, or with different math (finding line to connect to another point around the circle) or with manual moving around.
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
      local moveDir2D = lookDir2D:rotate(directionMult * math.pi / 2):normalize()
      local moveVec2D = moveDir2D *
          10 -- Look ~15 cm ahead, will break at very high speeds, but that will not happen, right?
      local movePos = omwself.object.position + util.vector3(moveVec2D.x, moveVec2D.y, 0)

      -- Check nearest navmesh pos
      local navMeshPosition = nearby.findNearestNavMeshPosition(movePos)
      local posDifference
      local shouldAbort = false
      if not navMeshPosition then
         gutils.print("Move failed due to no nearesth navmesh point", 2)
         return self:fail()
      else
         posDifference = (movePos - navMeshPosition):length()
         if posDifference > gutils.minHorizontalHalfSize(self.bounds) * 0.9 then
            gutils.print("Move finished due to big difference between a desired and navmesh position", 2)
            shouldAbort = true
         end
      end

      -- Track mean value of velocity (time window 0.3sec), if it drops too low - we are probably stuck running inplace
      if self.lastPos then
         self.velocitySampler:sample((self.lastPos - currentPos):length() / state.dt)
         if self.velocitySampler.warmedUp and self.velocitySampler.mean <= 20 then
            gutils.print("Move finished due to low velocity " .. self.velocitySampler.mean, 2)
            shouldAbort = true
         end
      end

      -- TO DO: Do small raycast here in movement direction, if we hit something - abort

      -- Abort if should
      if shouldAbort then
         if (self.startPos - currentPos):length() > props.distance() * 0.33 then
            -- Atleast we moved some distance, consider it a success
            return self:success()
         else
            -- We barely moved, its a fail
            return self:fail()
         end
      end


      -- Done if we covered required distance
      if (self.startPos - currentPos):length() > props.distance() then
         gutils.print("Move success since distance was covered", 2)
         return self:success()
      end

      -- Calculating speed
      local speedMult, shouldRun = moveutils.calcSpeedMult(self.desiredSpeed, self.walkSpeed, self.runSpeed)
      state.run = shouldRun

      -- And movement values!
      state.movement, state.sideMovement = moveutils.calculateMovement(omwself.object,
         movePos, speedMult)

      self.lastPos = currentPos
      self.firstRun = false
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
   config.run = function(self, state)
      if self.attackRequested then
         if not state.attackState then
            return self:fail()
         end
      else
         self.attackRequested = true
      end

      if state.attackState == config.successAttackState then
         return self:success()
      end

      if state.attackState > attackStates.WINDUP_MAX then
         return self:success()
      end

      state.attack = 1

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
bTrees.Combat:setDebugLevel(1)
bTrees.CombatAux:setDebugLevel(0)
bTrees.Locomotion:setDebugLevel(0)
-- Ready to use! -----------------------------------------------------------


-- Doing some inventory stuff --
local inventory = types.Actor.inventory(omwself)
print("Inventory resolved:", inventory:isResolved())
local weapons = inventory:getAll(types.Weapon)
print("Following weapons found in the inventory")
for i, weaponObj in pairs(weapons) do
   local isEquipped = types.Actor.hasEquipped(omwself, weaponObj)
   local weaponRecord = types.Weapon.record(weaponObj.recordId)
   print("i: " ..
      i ..
      " recordId: " ..
      weaponObj.recordId ..
      " name: " ..
      weaponRecord.name ..
      " type: " .. weaponRecord.type .. " reach: " .. weaponRecord.reach .. " equipped: " .. tostring(isEquipped))

   if isEquipped then
      state.reach = weaponRecord.reach * 140
   end
end


-- Main update function (finally) --
------------------------------------

local function onUpdate(dt)
   -- Reset everything
   state:clear()
   state.dt = dt

   -- Ignore native ai behaviour if its a Combat behaviour
   local activeAiPackage = AI.getActivePackage()
   if activeAiPackage then
      if activeAiPackage.type == "Combat" then
         omwself:enableAI(false)
      end
   else
      omwself:enableAI(true)
      print("No AI package :()")
   end

   local targetActor = AI.getActiveTarget("Combat")
   state.targetActor = targetActor

   -- Provide Behaviour Tree state with the necessary info
   if targetActor then
      state.range = (targetActor.position - omwself.object.position):length();
   end

   -- Verify that attack animation matching the current attackGroup is still playing - if its not - probably it was interrupted - cleaning attack state.
   if state.attackGroup then
      local animTime = anim.getCurrentTime(omwself.object, state.attackGroup)
      if not animTime then
         state.attackGroup = nil
         state.attackState = attackStates.NO_STATE
      end
   end

   -- Run the combat behaviour tree!
   bTrees["Combat"]:run()
   bTrees["CombatAux"]:run()
   bTrees["Locomotion"]:run()
   -- Does nav service need to constantly run? Probably not.
   navService:run()

   -- Apply the results of Behaviour Tree run to the actor
   omwself.controls.run = state.run
   omwself.controls.movement = state.movement
   omwself.controls.sideMovement = state.sideMovement

   omwself.controls.use = state.attack
   omwself.controls.jump = state.jump
   omwself.controls.yawChange = gutils.lerpClamped(0, -moveutils.lookRotation(omwself, targetActor.position), dt * 3)
end


-- Animation handlers --------
------------------------------
-- In the text key handler: Theres no way to know for which bonegroup the text key was triggered?
I.AnimationController.addTextKeyHandler(nil, function(groupname, key)
   --print("Animation text key! " .. groupname .. " : " .. key)
   --print("Position of the key: " .. tostring(anim.getTextKeyTime(omwself.object, groupname .. ": " .. key)))

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
