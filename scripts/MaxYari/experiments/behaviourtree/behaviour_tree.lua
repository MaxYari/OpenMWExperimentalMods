-- Global interface----------
-- Not meant to be used the end-user directly, here mostly for the easy of access from another .lua files of this package
_BehaviourTreeGlobals                      = {
  debugLevel = 1,
  branchString = "",
  lastPrintedBranchString = "",
  setDebugLevel = function(val)
    _BehaviourTreeGlobals.debugLevel = val
  end,
  print = function(msg, lvl)
    if lvl == nil then lvl = 1 end
    if lvl <= _BehaviourTreeGlobals.debugLevel then print("[BT DEBUG]:", msg) end
  end
}
----------------------------

local _PACKAGE                             = (...):match("^(.+)[%./][^%./]+") or ""
local class                                = require(_PACKAGE .. '/middleclass')
local Registry                             = require(_PACKAGE .. '/registry')
local Node                                 = require(_PACKAGE .. '/node_types/node')
local RegisterPremadeNodes                 = require(_PACKAGE .. '/nodes/nodes')
local ParseProjectJsonTable                = require(_PACKAGE .. '/json_parser')
local BehaviourTree                        = class('BehaviourTree', Node)
local g                                    = _BehaviourTreeGlobals

BehaviourTree.childNode                    = Node
BehaviourTree.Registry                     = Registry
BehaviourTree.Task                         = Node
BehaviourTree.BranchNode                   = require(_PACKAGE .. '/node_types/branch_node')
BehaviourTree.Priority                     = require(_PACKAGE .. '/node_types/priority')
BehaviourTree.ActivePriority               = require(_PACKAGE .. '/node_types/active_priority')
BehaviourTree.Random                       = require(_PACKAGE .. '/node_types/random')
BehaviourTree.Sequence                     = require(_PACKAGE .. '/node_types/sequence')
BehaviourTree.Decorator                    = require(_PACKAGE .. '/node_types/decorator')
BehaviourTree.ContinuousConditionDecorator = require(_PACKAGE .. '/node_types/continuous_condition_decorator')
BehaviourTree.ConditionDecorator           = require(_PACKAGE .. '/node_types/condition_decorator')
BehaviourTree.InvertDecorator              = require(_PACKAGE .. '/node_types/invert_decorator')
BehaviourTree.AlwaysFailDecorator          = require(_PACKAGE .. '/node_types/always_fail_decorator')
BehaviourTree.AlwaysSucceedDecorator       = require(_PACKAGE .. '/node_types/always_succeed_decorator')
BehaviourTree.RepeaterDecorator            = require(_PACKAGE .. '/node_types/repeater_decorator')

BehaviourTree.register                     = Registry.register
BehaviourTree.setDebugLevel                = _BehaviourTreeGlobals.setDebugLevel

-- IMPORTANT NOTES TO SELF:
-- Dont forget to change readme, now "node" is a "childNode" and "nodes" are "childNodes"
-- Also registry might be removed, so node name based registration will not be a thing
-- BehaviourTree.register now registers node type, not node by name

-- Registering premade nodes
RegisterPremadeNodes(Registry)
Registry.register('Sequence', BehaviourTree.Sequence)
Registry.register('Priority', BehaviourTree.Priority)
Registry.register('Random', BehaviourTree.Random)
Registry.register('Repeater', BehaviourTree.RepeaterDecorator)
Registry.register('Inverter', BehaviourTree.InvertDecorator)
Registry.register('AlwaysSucceed', BehaviourTree.AlwaysSucceedDecorator)
Registry.register('AlwaysFail', BehaviourTree.AlwaysFailDecorator)




-- Behaviour tree logic
function BehaviourTree:run(object)
  self.name = "root"
  if self.started then
    -- Note: If one of the nodes will not report atleast _some_ state (running/success/fail) during its run function or something will prevent that state from bubbling up to this level -
    -- the whole tree will be stuck here forever. A very strange behaviour that probably should be re-evaluated in the future.
    Node.running(self) --call running if we have control
  else
    self.started = true
    self.stateObject = object or self.stateObject
    self.rootNode = self.tree
    self.rootNode:setParentNode(self)
    self.rootNode:start(self.stateObject)
    self.rootNode:call_run(self.stateObject)
  end
end

local function printBranch()
  if g.lastPrintedBranchString ~= g.branchString then
    g.print(g.branchString)
    g.lastPrintedBranchString = g.branchString
  end
  g.branchString = ""
end

function BehaviourTree:running()
  Node.running(self)
  self.started = false

  -- Single run finished - printing branch debug string and reseting
  printBranch()
end

function BehaviourTree:success()
  -- These calls bubble up from a child to the parent through self.parentNode:success()
  self.rootNode:finish(self.stateObject);
  self.started = false
  Node.success(self)
end

function BehaviourTree:fail()
  self.rootNode:finish(self.stateObject);
  self.started = false
  Node.fail(self)
end

-- Json loading logic
BehaviourTree.LoadFromJsonTable = function(jsonTable)
  local trees = ParseProjectJsonTable(jsonTable)

  for title, config in pairs(trees) do
    trees[title] = BehaviourTree:new({ tree = config })
  end

  return trees
end

return BehaviourTree
