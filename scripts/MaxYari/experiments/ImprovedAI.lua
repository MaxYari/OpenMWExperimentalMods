local self = require('openmw.self')
local core = require('openmw.core')
local types = require('openmw.types')
local AI = require('openmw.interfaces').AI
local vfs = require('openmw.vfs')
local view = require('openmw_aux.util').deepToString

local BehaviourTree = require('behaviourtree/behaviour_tree')
local json = require("json")

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

if self.object.recordId ~= "dralcea arethi" then return end

local actionRegistry = {}
local state = {
   clear = function(self)
      self.attack = 0
      self.movement = 0
      self.sideMovement = 0
      self.targetDistance = 1e42
      self.targetMovement = 0
      self.targetSideMovement = 0
   end
}

function MoveAction(params)
   if not direction then direction = 1 end
   if not params then params = {} end

   return BehaviourTree.Task:new({
      rname = 'MoveAction', -- rname stands for Readable Name

      start = function(t, state)
         print(t.rname .. "started " .. " in " .. direction .. " direction")
      end,

      run = function(task, state)
         if params.movement ~= nil then state.movement = params.movement end
         if params.sideMovement ~= nil then state.sideMovement = params.sideMovement end
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
   return MoveAction({ movement = 1 })
end

actionRegistry['Approach'] = Approach

function Fallback()
   return MoveAction({ movement = -1 })
end

actionRegistry['Fallback'] = Fallback

function Strafe(params)
   return MoveAction({ sideMovement = params.direction })
end

actionRegistry['Strafe'] = Strafe

function Wait(params)
   return BehaviourTree.Task:new({
      rname = 'wait',
      duration = 0,

      start = function(t, obj)
         print(t.rname .. "started")
         t.duration = params.duration
         if params.max ~= nil then
            t.duration = params.min + (params.max - params.min) * math.random()
            print("wait duration " .. t.duration)
         end
         t.startTime = core.getRealTime()
      end,

      run = function(t, obj)
         now = core.getRealTime()
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

-- Adding basic tree types into registry
actionRegistry['select'] = BehaviourTree.Priority
actionRegistry['sequence'] = BehaviourTree.Sequence
actionRegistry['ContinuousCondition'] = BehaviourTree.ContinuousCondition

-- Parsin JSON behaviourtree
local treeData = readJSON("MovementTree.json")

local function parseNode(node)
   local initData = {}

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
         parsedConditionFn = assert(load(field .. comparator))
      end

      initData.conditionFn = function(task, state)
         return parsedConditionFn()
      end
   end

   if type(fn) == "table" then
      return fn:new(initData)
   elseif type(fn) == "function" then
      return fn(node.properties)
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

--[[ local btree = BehaviourTree:new({
   tree = BehaviourTree.Priority:new({
      nodes = {
         BehaviourTree.ContinuousCondition:new({
            conditionFn = function(task, state)
               return state.targetDistance > 250
            end,

            node = BehaviourTree.Sequence:new({
               nodes = {
                  Wait({ min = 0, max = 1 }),
                  Approach()
               }
            })
         }),
         BehaviourTree.ContinuousCondition:new({
            conditionFn = function(task, state)
               return state.targetDistance < 150
            end,

            node = BehaviourTree.Sequence:new({
               nodes = {
                  Wait({ min = 0, max = 1 }),
                  Fallback()
               }
            })
         }),
      }
   })
}) ]]

btree:setObject(state)

local function onUpdate(dt)
   -- Reset everything
   state:clear()
   -- Fill the satate
   local target = AI.getActiveTarget("Combat")
   if target then
      state.targetDistance = (target.position - self.object.position):length()
      --print(state.targetDistance)
   end

   btree:run()

   self.controls.movement = state.movement
   self.controls.sideMovement = state.sideMovement
   self.controls.use = state.attack
end

return {
   engineHandlers = {
      onUpdate = onUpdate,
   },
}
