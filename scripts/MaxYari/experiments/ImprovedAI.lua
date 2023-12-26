local self = require('openmw.self')
local core = require('openmw.core')
local types = require('openmw.types')
local AI = require('openmw.interfaces').AI
local vfs = require('openmw.vfs')
local view = require('openmw_aux.util').deepToString
local util = require('openmw.util')
local I = require('openmw.interfaces')

local BehaviourTree = require('behaviourtree/behaviour_tree')
local json = require("json")


-- For testing
if self.object.recordId ~= "dralcea arethi" then return end


-- Behaviour state of this actor --
-----------------------------------

local state = {
   -- Permanent state
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
local actionRegistry = {}
-- Adding built-in tree types into registry
actionRegistry['select'] = BehaviourTree.Priority
actionRegistry['sequence'] = BehaviourTree.Sequence
actionRegistry['ContinuousCondition'] = BehaviourTree.ContinuousCondition
actionRegistry['always_succeed'] = BehaviourTree.AlwaysSucceedDecorator


-- Utility functions ------------------
---------------------------------------
local function durationOrRange(p)
   local dur = p.duration
   if p.max ~= nil then
      dur = p.min + (p.max - p.min) * math.random()
   end
   return dur
end

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
   if not direction then direction = 1 end

   local props = config.props

   return BehaviourTree.Task:new({
      rname = 'MoveAction', -- rname stands for Readable Name

      start = function(t, state)
         print(t.rname .. "started " .. " in " .. direction .. " direction")
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

actionRegistry['MoveAction'] = MoveAction

function Approach()
   return MoveAction({ props = { movement = 1 } })
end

actionRegistry['Approach'] = Approach

function Fallback()
   return MoveAction({ props = { movement = -1 } })
end

actionRegistry['Fallback'] = Fallback

function Strafe(config)
   local props = config.props
   props.sideMovement = props.direction
   return MoveAction(config)
end

actionRegistry['Strafe'] = Strafe

function SwitchRun(config)
   local props = config.props
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

actionRegistry['SwitchRun'] = SwitchRun

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

actionRegistry['Jump'] = Jump

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

actionRegistry['HoldAttack'] = HoldAttack

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

actionRegistry['ReleaseAttack'] = ReleaseAttack

function RandomOutcome(config)
   local props = config.props
   return BehaviourTree.Task:new({
      rname = 'RandomOutcome', -- rname stands for Readable Name

      run = function(task, state)
         if props.probability > math.random() * 100 then
            task:success()
         else
            task:fail()
         end
      end
   })
end

actionRegistry['RandomOutcome'] = RandomOutcome

function RandomCondition(config)
   local p = config.props
   return BehaviourTree.Condition:new({
      conditionFn = function(task, state)
         if p.probability > math.random() * 100 then
            return true
         else
            return false
         end
      end,

      node = config.node
   })
end

actionRegistry['RandomCondition'] = RandomCondition

local function stateConditionFn(task, state)
   local satisfied = true

   for key, val in pairs(p) do
      if strIsBool(val) then
         val = strToBool(val)
      end
      if state[key] ~= val then
         satisfied = false
      end
   end

   return satisfied
end

function StateCondition(config)
   local p = config.props
   return BehaviourTree.Condition:new({
      conditionFn = stateConditionFn,
      node = config.node
   })
end

actionRegistry['StateCondition'] = StateCondition

function StateContinuousCondition(config)
   local p = config.props
   return BehaviourTree.ContinuousCondition:new({
      conditionFn = stateConditionFn,
      node = config.node
   })
end

actionRegistry['StateContinuousCondition'] = StateContinuousCondition

function Cooldown(config)
   local p = config.props
   return BehaviourTree.Condition:new({
      conditionFn = function(task, state)
         local now = core.getRealTime()
         if not state.duration then
            task.duration = durationOrRange(p)
         end
         if not state.lastUseTime or now - state.lastUseTime > task.duration then
            state.lastUseTime = now
            return true
         end
      end,

      node = config.node
   })
end

actionRegistry['Cooldown'] = Cooldown

function Wait(config)
   local p = config.props
   return BehaviourTree.Task:new({
      rname = 'wait',
      duration = 0,

      start = function(t, obj)
         print(t.rname .. "started")
         t.duration = durationOrRange(p)
         t.startTime = core.getRealTime()
      end,

      run = function(t, obj)
         local now = core.getRealTime()
         if now - t.startTime > t.duration then
            t:success()
         else
            t:running()
         end
      end,

      finish = function(t, obj)
         print(t.rname .. " finished")
      end
   })
end

actionRegistry['Wait'] = Wait


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
   initData.props = node.properties

   if node.child then
      initData.node = parseNode(treeData.nodes[node.child])
   end
   if node.children then
      initData.nodes = {}
      for i, childId in pairs(node.children) do
         table.insert(initData.nodes, parseNode(treeData.nodes[childId]))
      end
   end

   local fn = actionRegistry[node.name]
   if not fn then
      return error("Can not find behaviour function " .. node.name)
   end
   if node.name == "ContinuousCondition" then
      -- parse the condition function
      local parsedConditionFn;

      for field, comparator in pairs(node.properties) do
         parsedConditionFn = util.loadCode("return " .. field .. comparator, state)
      end

      initData.conditionFn = function(task, state)
         return parsedConditionFn()
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
   if not checkanim then
      print("Attack group " .. state.attackGroup .. " is not playing anymore, resetting.")
      state.attackState = "none"
      state.attackGroup = nil
   end

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
I.AnimationController.addTextKeyHandler(nil, function(groupname, key)
   print("Animation text key! " .. groupname .. " : " .. key)

   -- Note: attack animation can be interrupted, so this states most likely should reset after few seconds just in case, to ponder: what if character holds the attack long enough for this to reset?
   -- Probably need to check animation timings to figure for sure if we are in the attack group or not, can get the group during windup and then repeatedly check if its still playing, reset if not
   if string.find(key, "chop") or string.find(key, "thrust") or string.find(key, "slash") then
      state.attackState = "windup"
      print("Animation attack group is ", groupname)
      state.attackGroup = groupname
   end

   if string.find(key, "min attack") then
      state.attackState = "min windup"
   end

   if string.find(key, "max attack") then
      -- not correct, this will be reported both in the end of windup and beginning of attack
      state.attackState = "max windup"
   end

   if string.find(key, "follow start") then
      state.attackState = "swing"
      --I.AnimationController.playBlendedAnimation('idle', { priority = anim.PRIORITY.Weapon })
   end

   if string.find(key, "follow stop") then
      state.attackState = "none"
   end
end)

-- Engine handlers -----------
------------------------------
return {
   engineHandlers = {
      onUpdate = onUpdate,
   },
}
