local omwself = require('openmw.self')
local core = require('openmw.core')
local types = require('openmw.types')
local AI = require('openmw.interfaces').AI
local vfs = require('openmw.vfs')
local view = require('openmw_aux.util').deepToString
local util = require('openmw.util')
local I = require('openmw.interfaces')
local anim = require('openmw.animation')
local nearby = require('openmw.nearby')



local BT = require('behaviourtree/behaviour_tree')
local json = require("json")


-- For testing
print("Trying to use improved AI on  " .. omwself.object.recordId)
if omwself.object.recordId ~= "heddvild" then return end

print("Improved AI is ON")

BT.setDebugLevel(1)


-- Behaviour state of this actor --
-----------------------------------

local state = {
   -- Doesn't reset every frame
   run = true,
   attackState = "none",
   attackGroup = nil,
   clear = function(self)
      -- Resets every frame
      self.jump = false
      self.attack = 0
      self.movement = 0
      self.sideMovement = 0
      self.targetDistance = 1e42
      self.range = 1e42
      self.targetMovement = 0
      self.targetSideMovement = 0
   end
}




-- Utility functions ------------------
---------------------------------------


local function findField(dictionary, value)
   for field, val in pairs(dictionary) do
      if val == value then
         return field
      end
   end
   return nil
end

local function cache(fn, delay)
   delay = delay or 0.25 -- default delay is 0.25 seconds
   local lastExecution = 0
   local c1, c2 = nil, nil

   return function(...)
      local currentTime = core.getRealTime()
      if currentTime - lastExecution < delay then
         return c1, c2, "cached"
      end

      lastExecution = currentTime
      c1, c2 = fn(...)
      return c1, c2, "new"
   end
end

local function lookDirection(actor)
   return actor.rotation:apply(util.vector3(0, 1, 0))
end

local function flatAngleBetween(a, b)
   return math.atan2(a.x * b.y - a.y * b.x, a.x * b.x + a.y * b.y)
end

local function calculateMovement(actor, targetPos, speed)
   local lookDir = lookDirection(actor)
   local moveDir = targetPos - actor.position
   local angle = flatAngleBetween(lookDir, moveDir)

   local forwardVec = util.vector2(1, 0)
   local movementVec = forwardVec:rotate(-angle):normalize() * speed;

   return movementVec.x, movementVec.y
end

-- Function to check if path point was reached





-- navigation service
local function NavigationService(config)
   if not config then config = {} end

   local NavData = {
      path = nil,
      pathStatus = nil,
      targetPos = nil,
      pathPointIndex = 1,
      nextPathPoint = nil
   }

   function NavData:getPathStatusVerbose()
      if self.pathStatus == nil then return nil end
      return findField(nearby.FIND_PATH_STATUS, self.pathStatus)
   end

   function NavData:isPathCompleted()
      return self.path and self.pathPointIndex > #self.path
   end

   function NavData:calculatePathLength()
      if not self.path then return 0 end

      local pathLength = 0
      for i = 1, #self.path - 1 do
         -- Calculate the distance between consecutive points
         local segmentLength = (self.path[i + 1] - self.path[i]):length()
         pathLength = pathLength + segmentLength
      end
      return pathLength
   end

   local function findPath()
      NavData.pathStatus, NavData.path = nearby.findPath(omwself.object.position, NavData.targetPos, {
         agentBounds = types.Actor.getPathfindingAgentBounds(omwself),
      })
      NavData.pathPointIndex = 1
      return NavData.pathStatus, NavData.path
   end

   local findPathCached = cache(findPath, config.cacheDuration)

   function NavData:setTargetPos(pos)
      if not self.targetPos or (self.targetPos - pos):length() > config.targetPosDeadzone then
         self.targetPos = pos
         findPath()
      end
   end

   local function positionReached(pos1, pos2)
      return (pos1 - pos2):length() <= config.pathingDeadzone
   end

   function NavData:run()
      -- Fetching a new path if necessary
      if NavData.targetPos then
         local pathStatus, path, cacheStatus = findPathCached()
      end

      -- Updating path progress
      if NavData.path and NavData.pathPointIndex <= #NavData.path then
         -- Check if the actor reached the current target point
         while NavData.pathPointIndex <= #NavData.path do
            if positionReached(omwself.object.position, NavData.path[NavData.pathPointIndex]) then
               NavData.pathPointIndex = NavData.pathPointIndex + 1
            else
               break;
            end
         end
         if NavData.pathPointIndex <= #NavData.path then
            NavData.nextPathPoint = NavData.path[NavData.pathPointIndex]
         else
            NavData.nextPathPoint = nil
            -- Reached path end
         end
      end
   end

   return NavData
end

local navService = NavigationService({
   cacheDuration = 0.5,
   targetPosDeadzone = 70,
   pathingDeadzone = 35
})



-- Custom behaviours ------------------
---------------------------------------


function MoveToTarget(config)
   local props = config.properties

   config.run = function(task, state)
      if not state.targetActor then
         return task:fail()
      end

      navService:setTargetPos(state.targetActor.position)

      if (state.targetActor.position - omwself.object.position):length() <= props.proximity then
         return task:success()
      end

      if navService.nextPathPoint then
         state.movement, state.sideMovement = calculateMovement(omwself.object,
            navService.nextPathPoint, 1)
      end

      return task:running()
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
   end

   config.run = function(self, state)
      if not state.targetActor then
         return self:fail()
      end
      --local lookDir = lookDirection(omwself.object)
      local lookDir = (state.targetActor.position - omwself.object.position):normalize() -- due to the slow pathing refresh this doesnt result in strafing around, but rather in noticeable step to the side. Would be better with shorter strafes, or with different math (finding line to connect to another point around the circle) or with manual moving around.
      local lookDir2D = util.vector2(lookDir.x, lookDir.y)
      local directionMult = 0
      if props.direction == "left" then directionMult = 1 end
      if props.direction == "right" then directionMult = -1 end
      if props.direction == "back" then directionMult = 2 end
      local strafeDir2D = lookDir2D:rotate(directionMult * math.pi / 2):normalize()
      local strafeVec2D = strafeDir2D * props.distance * 2
      local strafeToPos = omwself.object.position + util.vector3(strafeVec2D.x, strafeVec2D.y, 0)

      navService:setTargetPos(strafeToPos)

      if navService:getPathStatusVerbose() ~= "Success" then
         print("STRAFE PATHING ERROR: " .. navService:getPathStatusVerbose())
         return self:fail()
      end

      --print("path length: ", navService:calculatePathLength(), " strafe vec: ", tostring(strafeVec2D))

      if self.firstRun == true then
         if navService:calculatePathLength() < props.distance * 0.9 then
            return self:fail()
         end
         if #navService.path > 2 then
            return self:fail()
         end
      end

      if #navService.path > 2 then
         return self:success()
      end

      -- Might get stuck running against an actor! Should probably detect that based on a movement threshold and abort
      -- even better - calculate time based on speed?
      if navService:isPathCompleted() then
         return self:success()
      end


      if (self.startPos - omwself.object.position):length() > props.distance then
         return self:success()
      end

      if navService.nextPathPoint then
         state.movement, state.sideMovement = calculateMovement(omwself.object,
            navService.nextPathPoint, 0.5)
      end

      self.firstRun = false
      return self:running()
   end

   return BT.Task:new(config)
end

BT.register('MoveInDirection', MoveInDirection)

function Fallback(config)
   config.properties = { movement = -1 }
   return MoveAction(config)
end

BT.register('Fallback', Fallback)




function SwitchRun(config)
   local props = config.properties

   config.run = function(task, state)
      state.run = props.state
      task:success()
      --task:fail()
      --task:running()
   end

   return BT.Task:new(config)
end

BT.register('SwitchRun', SwitchRun)

function Jump(config)
   config.run = function(task, state)
      state.jump = true
      task:success()
      --task:fail()
      --task:running()
   end

   config.finish = function(task, state)
      print("Jump task finished (in game it only started)")
   end

   return BT.Task:new(config)
end

BT.register('Jump', Jump)

function HoldAttack(config)
   config.run = function(task, state)
      state.attack = 1
      task:running()
      --task:fail()
      --task:running()
   end

   config.finish = function(task, state)
      print("HoldAttack finished")
   end

   return BT.Task:new(config)
end

BT.register('HoldAttack', HoldAttack)

function ReleaseAttack(config)
   config.run = function(task, state)
      state.attack = 0
      task:success()
      --task:fail()
      --task:running()
   end

   config.finish = function(task, state)
      print("ReleaseAttack finished")
   end

   return BT.Task:new(config)
end

BT.register('ReleaseAttack', ReleaseAttack)



-- Parsing JSON behaviourtree -----
----------------------------------
local function readJSON(path) --For some reason this parser makes json lists into dictionaries with number fields. Its a strange behaviour that might not match how a regular json parser behaves.
   local myTable = {}
   local file = vfs.open(path)

   if file then
      -- read all contents of file into a string
      local contents = file:read("*a")
      myTable = json.decode(contents)
      file:close()
      return myTable
   end
end

local projectJsonTable = readJSON("scripts\\MaxYari\\experiments\\NewTestProject.json")
local bTrees = BT.LoadFromJsonTable(projectJsonTable)

-- Provide a state oject for tree to use
bTrees["Combat"]:setStateObject(state)
bTrees["Locomotion"]:setStateObject(state)


-- Main update function (finally) --
------------------------------------
local function onUpdate(dt)
   -- Reset everything
   state:clear()

   -- Fill the state
   -- Distance to target

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

   if targetActor then
      state.targetActor = targetActor
      state.range = (targetActor.position - omwself.object.position):length();
   end


   -- Is attack animation group still playing, should make the whole attack animation detection fairly robust
   -- can use for that animation.getActiveGroup(actor, bonegroup) - it will return anim playing on a specific group of bones
   -- if not checkanim then
   --    print("Attack group " .. state.attackGroup .. " is not playing anymore, resetting.")
   --    state.attackState = "none"
   --    state.attackGroup = nil
   -- end

   -- This thing crashes!
   --anim.getActiveGroup(omwself.object, 4)

   -- anim group time
   --print("anim group time: " .. tostring(anim.getCurrentTime(omwself.object, "weapontwohand")))
   --print("attack state: " .. tostring(state.attackState))
   -- if time is not progressing - attack is probably being held
   -- if the group is not playing - probably was interrupted. I believe those attack groups gladly contain ONLY attacks, all other animations, like idle and stagger for the same weapon belong to a group with a different name


   -- Run the combat behaviour tree!
   bTrees["Combat"]:run()
   navService:run()

   -- as soon as atleast some control is used - npc stops dead in its tracks
   omwself.controls.run = false
   --if state.movement ~= nil then omwself.controls.movement = state.movement end
   omwself.controls.movement = state.movement
   omwself.controls.sideMovement = state.sideMovement
   -- attack will never happen if this is set to 1 on the very first update, probably a bug
   omwself.controls.use = 0
   if (core.getRealTime() % 2) > 1 then omwself.controls.use = 1 end
   --omwself.controls.jump = state.jump
   omwself.controls.yawChange = 0
end


-- Animation handlers --------
------------------------------
-- Notes: Theres no way do check what animation group is currently playing on a specific bonegroup?
-- In the text key handler: Theres no way to know for which bonegroup the text key was triggered?
I.AnimationController.addTextKeyHandler(nil, function(groupname, key)
   --print("Animation text key! " .. groupname .. " : " .. key)
   --print("Position of the key: " .. tostring(anim.getTextKeyTime(omwself.object, key)))

   -- Note: attack animation can be interrupted, so this states most likely should reset after few seconds just in case, to ponder: what if character holds the attack long enough for this to reset?
   -- Probably need to check animation timings to figure for sure if we are in the attack group or not, can get the group during windup and then repeatedly check if its still playing, reset if not
   if string.find(key, "chop") or string.find(key, "thrust") or string.find(key, "slash") then
      state.attackState = "windup_start"
      state.attackGroup = groupname
   end

   if string.find(key, "min attack") then
      state.attackState = "windup_min"
   end

   if string.find(key, "max attack") then
      -- Attack is being held here, but this event will also trigger at the beginning of release
      state.attackState = "windup_max"
      --print("Attack hold key time: " .. tostring(anim.getTextKeyTime(omwself.object, key)))
   end

   if string.find(key, "min hit") then
      --Changing state on min hit is good enough
      state.attackState = "release_start"
   elseif string.find(key, "hit") then
      state.attackState = "release_hit"
   end



   if string.find(key, "follow start") then
      state.attackState = "follow_start"
      --I.AnimationController.playBlendedAnimation('idle', { priority = anim.PRIORITY.Weapon })
   end

   if string.find(key, "follow stop") then
      state.attackState = nil
   end
end)

-- Engine handlers -----------
------------------------------
return {
   engineHandlers = {
      onUpdate = onUpdate,
   },
}
