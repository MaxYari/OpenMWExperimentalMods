-- Global interface----------
-- Not meant to be used the end-user directly, here mostly for the easy of access from another .lua files of this package
_BehaviourTreeGlobals                = {
  debugLevel = 1,
  branchString = "",
  lastPrint = "",
  setDebugLevel = function(val)
    _BehaviourTreeGlobals.debugLevel = val
  end,
  print = function(msg, lvl)
    if lvl == nil then lvl = 1 end
    if lvl <= _BehaviourTreeGlobals.debugLevel then
      print("[BT DEBUG]:", msg)
      _BehaviourTreeGlobals.lastPrint = msg
    end
  end,
  printLazy = function(msg, lvl)
    local g = _BehaviourTreeGlobals
    if g.lastPrint ~= msg then
      g.print(msg, lvl)
    end
  end
}
----------------------------

local _PACKAGE                       = (...):match("^(.+)[%./][^%./]+") or ""
local class                          = require(_PACKAGE .. '/middleclass')
local Registry                       = require(_PACKAGE .. '/registry')
local Node                           = require(_PACKAGE .. '/node_types/node')
local RegisterPremadeNodes           = require(_PACKAGE .. '/nodes/nodes')
local ParseProjectJsonTable          = require(_PACKAGE .. '/json_parser')
local BehaviourTree                  = class('BehaviourTree', Node)
local g                              = _BehaviourTreeGlobals

BehaviourTree.Node                   = Node
BehaviourTree.Registry               = Registry
BehaviourTree.Task                   = Node
BehaviourTree.BranchNode             = require(_PACKAGE .. '/node_types/branch_node')
BehaviourTree.Priority               = require(_PACKAGE .. '/node_types/priority')
BehaviourTree.Random                 = require(_PACKAGE .. '/node_types/random')
BehaviourTree.Sequence               = require(_PACKAGE .. '/node_types/sequence')
BehaviourTree.Decorator              = require(_PACKAGE .. '/node_types/decorator')
BehaviourTree.InvertDecorator        = require(_PACKAGE .. '/node_types/invert_decorator')
BehaviourTree.AlwaysFailDecorator    = require(_PACKAGE .. '/node_types/always_fail_decorator')
BehaviourTree.AlwaysSucceedDecorator = require(_PACKAGE .. '/node_types/always_succeed_decorator')
BehaviourTree.RepeaterDecorator      = require(_PACKAGE .. '/node_types/repeater_decorator')
BehaviourTree.InterruptDecorator     = require(_PACKAGE .. '/node_types/interrupt_decorator')

BehaviourTree.register               = Registry.register
BehaviourTree.setDebugLevel          = _BehaviourTreeGlobals.setDebugLevel

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




-- Behaviour tree logic, this is essentially a Node class extension that represents a root node
function BehaviourTree:initialize(config)
  Node.initialize(self, config)

  self.childNode = config.root

  --Walking the tree and setting up important properties
  local currentLevel = 1
  local function process(node)
    node.tree = self
    node.level = currentLevel
    if node.childNode then
      currentLevel = currentLevel + 1
      node.childNode.parentNode = node
      process(node.childNode)
    end
    if node.childNodes then
      currentLevel = currentLevel + 1
      for i, childNode in pairs(node.childNodes) do
        childNode.parentNode = node
        process(childNode)
      end
    end
  end
  process(self)

  --Interrupts
  self.interrupts = {}

  self.firstRun = true
  g.print("Behaviour Tree " .. config.name .. " INITIALIZED!")
end

function BehaviourTree:registerInterrupt(interruptNode)
  local level = interruptNode.level
  if not self.interrupts[level] then self.interrupts[level] = {} end
  table.insert(self.interrupts[level], interruptNode)
  interruptNode:registered()
end

function BehaviourTree:deregisterInterrupts(level)
  if self.interrupts[level] then
    for i, interruptNode in pairs(self.interrupts[level]) do
      interruptNode:deregistered()
    end
    self.interrupts[level] = {}
  end
end

function BehaviourTree:setStateObject(obj)
  self.stateObject = obj
end

function BehaviourTree:setActiveNode(node)
  self.activeNode = node
end

local function walkUpAndFinish(node, level)
  if node.level >= level then
    node:abort()
    if node.parentNode then walkUpAndFinish(node.parentNode, level) end
  end
end

function BehaviourTree:run()
  if self.firstRun then
    self:start()
    self.childNode:start()
    self.firstRun = false
  end

  -- check interrupts
  -- as of right now topmost interrupts first
  for level, interrupts in pairs(self.interrupts) do
    for i, interrupt in pairs(interrupts) do
      local should = interrupt:shouldInterrupt()
      if should then
        -- If interrupted, need to walk the brunch all the way up to the same level as the interrupt, and call finish on everything.
        -- but what if interrupt will interrupt itself? Good question! Probably should be handled by the developer.
        walkUpAndFinish(self.activeNode, interrupt.level)
        interrupt:doInterrupt()
      end
    end
  end

  if self.activeNode then
    self.activeNode:run()
  end
end

function BehaviourTree:success()
  -- Behaviour tree is essentially an infinite repeater, it resters the child node when its done
  Node.success(self)

  self.activeNode = nil
  self.firstRun = true
end

function BehaviourTree:fail()
  -- Behaviour tree is essentially an infinite repeater, it resters the child node when its done
  Node.fail(self)

  self.activeNode = nil
  self.firstRun = true
end

-- Json loading logic
BehaviourTree.LoadFromJsonTable = function(jsonTable)
  local roots = ParseProjectJsonTable(jsonTable)

  for title, root in pairs(roots) do
    roots[title] = BehaviourTree:new({ root = root, name = title })
  end

  return roots
end

return BehaviourTree
