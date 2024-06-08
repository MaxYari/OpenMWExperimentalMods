local self = require('openmw.self')
local core = require('openmw.core')
local types = require('openmw.types')
local AI = require('openmw.interfaces').AI
local vfs = require('openmw.vfs')
local view = require('openmw_aux.util').deepToString
local util = require('openmw.util')
local I = require('openmw.interfaces')
local anim = require('openmw.animation')

local BehaviourTree = require('behaviourtree/behaviour_tree')
local json = require("json")


-- For testing
print("Trying to use improved AI on  " .. self.object.recordId)
if self.object.recordId ~= "hlaalu guard_outside" then return end
print("Improved AI is ON")


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
      self.targetMovement = 0
      self.targetSideMovement = 0
   end
}


-- Registering behaviours -------------
---------------------------------------

-- Containes all the behaviours, used during JSON behaviourtree parsing

-- Adding built-in tree types into registry
nodeClassRegistry['Sequence'] = BehaviourTree.Sequence
nodeClassRegistry['Priority'] = BehaviourTree.Priority
nodeClassRegistry['Repeater'] = BehaviourTree.RepeaterDecorator                       --Add
nodeClassRegistry['RepeatUntilFailure'] = BehaviourTree.RepeatUntilFailureDecorator   --Add
nodeClassRegistry['repeat_until_success'] = BehaviourTree.RepeatUntilSuccessDecorator --Add
nodeClassRegistry['inverter'] = BehaviourTree.InvertDecorator

nodeClassRegistry['AlwaysSucceed'] = BehaviourTree.AlwaysSucceedDecorator
nodeClassRegistry['always_fail'] = BehaviourTree.AlwaysFailDecorator
nodeClassRegistry['Cooldown'] = BahaviourTree.nodes.Cooldown

nodeClassRegistry['Failer'] = BahaviourTree.nodes.Failer
nodeClassRegistry['Succeeder'] = BahaviourTree.nodes.Succeeder
nodeClassRegistry['Runner'] = BahaviourTree.nodes.Runner
nodeClassRegistry['Wait'] = BahaviourTree.nodes.Wait



-- Utility functions ------------------
---------------------------------------
local function strToBool(str)
   if str == "true" then
      return true
   else
      return false
   end
end

local function strIsBool(str)
   return str == "true" or str == "false"
end

-- Custom behaviours ------------------
---------------------------------------
function MoveAction(config)
   local props = config.properties

   return BehaviourTree.Task:new({
      rname = 'MoveAction', -- rname stands for Readable Name

      start = function(t, state)
         --print(t.rname .. "started " .. " in " .. direction .. " direction")
      end,

      run = function(task, state)
         if props.movement ~= nil then state.movement = props.movement end
         if props.sideMovement ~= nil then state.sideMovement = props.sideMovement end
         task:running()
         --task:fail()
         --task:running()
      end,

      finish = function(t, state)
         print(t.rname .. " finished")
      end,
   })
end

nodeClassRegistry['MoveAction'] = MoveAction

function Approach()
   return MoveAction({ props = { movement = 1 } })
end

nodeClassRegistry['Approach'] = Approach

function Fallback()
   return MoveAction({ props = { movement = -1 } })
end

nodeClassRegistry['Fallback'] = Fallback

function Strafe(config)
   local props = config.properties
   props.sideMovement = props.direction
   return MoveAction(config)
end

nodeClassRegistry['Strafe'] = Strafe

function SwitchRun(config)
   local props = config.properties
   return BehaviourTree.Task:new({
      rname = 'SwitchRun', -- rname stands for Readable Name

      run = function(task, state)
         state.run = strToBool(props.state)
         task:success()
         --task:fail()
         --task:running()
      end
   })
end

nodeClassRegistry['SwitchRun'] = SwitchRun

function Jump(config)
   return BehaviourTree.Task:new({
      rname = 'Jump', -- rname stands for Readable Name

      run = function(task, state)
         state.jump = true
         task:success()
         --task:fail()
         --task:running()
      end,

      finish = function(task, state)
         print("Jump task finished (in game it only started)")
      end
   })
end

nodeClassRegistry['Jump'] = Jump

function HoldAttack(config)
   return BehaviourTree.Task:new({
      rname = 'HoldAttack', -- rname stands for Readable Name

      run = function(task, state)
         state.attack = 1
         task:running()
         --task:fail()
         --task:running()
      end,

      finish = function(task, state)
         print("HoldAttack finished")
      end
   })
end

nodeClassRegistry['HoldAttack'] = HoldAttack

function ReleaseAttack(config)
   return BehaviourTree.Task:new({
      rname = 'ReleaseAttack', -- rname stands for Readable Name

      run = function(task, state)
         state.attack = 0
         task:success()
         --task:fail()
         --task:running()
      end,

      finish = function(task, state)
         print("ReleaseAttack finished")
      end
   })
end

nodeClassRegistry['ReleaseAttack'] = ReleaseAttack






-- Parsin JSON behaviourtree -----
----------------------------------
local function readJSON(path)
   local myTable = {}
   local file = vfs.open("scripts\\MaxYari\\experiments\\MovementTree.json")

   if file then
      -- read all contents of file into a string
      local contents = file:read("*a")
      myTable = json.decode(contents)
      file:close()
      return myTable
   end
end

local treeData = readJSON("MovementTree.json")

local function parseNode(node)
   local initData = {}
   initData.properties = node.properties

   if node.child then
      initData.childNode = parseNode(treeData.nodes[node.child])
   end
   if node.children then
      initData.childNodes = {}
      for i, childId in pairs(node.children) do
         table.insert(initData.childNodes, parseNode(treeData.nodes[childId]))
      end
   end

   local fn = nodeClassRegistry[node.name]
   if not fn then
      return error("Can not find behaviour function " .. node.name)
   end

   for field, value in pairs(node.properties) do
      if strIsBool(value) then
         node.properties[field] = strToBool(value)
      end
   end

   if type(fn) == "table" then
      return fn:new(initData)
   elseif type(fn) == "function" then
      return fn(initData)
   end
end

local function parseTreeData(td)
   local rootNode = parseNode(td.nodes[td.root])
   print(view(rootNode, 420))

   return BehaviourTree:new({
      tree = rootNode
   })
end

local btree = parseTreeData(treeData)
btree:setObject(state)



-- Main update function (finally) --
------------------------------------
local function onUpdate(dt)
   -- Reset everything
   state:clear()

   -- Fill the state
   -- Distance to target
   local target = AI.getActiveTarget("Combat")
   if target then
      state.targetDistance = (target.position - self.object.position):length()
      --print(state.targetDistance)
   end
   -- Is attack animation group still playing, should make the whole attack animation detection fairly robust
   -- can use for that animation.getActiveGroup(actor, bonegroup) - it will return anim playing on a specific group of bones
   -- if not checkanim then
   --    print("Attack group " .. state.attackGroup .. " is not playing anymore, resetting.")
   --    state.attackState = "none"
   --    state.attackGroup = nil
   -- end
   anim.getActiveGroup(self.object, 4)


   -- Run the behaviour tree!
   btree:run()

   self.controls.run = state.run
   self.controls.movement = state.movement
   self.controls.sideMovement = state.sideMovement
   -- attack will never happen if this is set to 1 on the very first update, probably a bug
   self.controls.use = state.attack
   self.controls.jump = state.jump
end


-- Animation handlers --------
------------------------------
-- Notes: Theres no way do check what animation group is currently playing on a specific bonegroup?
-- In the text key handler: Theres no way to know for which bonegroup the text key was triggered?
-- I.AnimationController.addTextKeyHandler(nil, function(groupname, key)
--    print("Animation text key! " .. groupname .. " : " .. key)

--    -- Note: attack animation can be interrupted, so this states most likely should reset after few seconds just in case, to ponder: what if character holds the attack long enough for this to reset?
--    -- Probably need to check animation timings to figure for sure if we are in the attack group or not, can get the group during windup and then repeatedly check if its still playing, reset if not
--    if string.find(key, "chop") or string.find(key, "thrust") or string.find(key, "slash") then
--       state.attackState = "windup"
--       print("Animation attack group is ", groupname)
--       state.attackGroup = groupname
--    end

--    if string.find(key, "min attack") then
--       state.attackState = "min windup"
--    end

--    if string.find(key, "max attack") then
--       -- not correct, this will be reported both in the end of windup and beginning of attack
--       state.attackState = "max windup"
--    end

--    if string.find(key, "follow start") then
--       state.attackState = "swing"
--       --I.AnimationController.playBlendedAnimation('idle', { priority = anim.PRIORITY.Weapon })
--    end

--    if string.find(key, "follow stop") then
--       state.attackState = "none"
--    end
-- end)

-- Engine handlers -----------
------------------------------
return {
   engineHandlers = {
      onUpdate = onUpdate,
   },
}
