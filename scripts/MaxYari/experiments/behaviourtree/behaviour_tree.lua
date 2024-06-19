-- Global interface----------
-- Not meant to be used the end-user directly, here mostly for the easy of access from another .lua files of this package
_BehaviourTreeGlobals                 = {}
----------------------------

local _PACKAGE                        = (...):match("^(.+)[%./][^%./]+") or ""
local class                           = require(_PACKAGE .. '/middleclass')
local Registry                        = require(_PACKAGE .. '/registry')
local Node                            = require(_PACKAGE .. '/node_types/node')
local RegisterPremadeNodes            = require(_PACKAGE .. '/nodes/nodes')
local ParseBehavior3Project           = require(_PACKAGE .. '/behavior3_parser')
local BehaviourTree                   = class('BehaviourTree', Node)
local g                               = _BehaviourTreeGlobals
local imports                         = _BehaviourTreeImports

BehaviourTree.Node                    = Node
BehaviourTree.Registry                = Registry
BehaviourTree.Task                    = Node
BehaviourTree.BranchNode              = require(_PACKAGE .. '/node_types/branch_node')
BehaviourTree.RunRandom               = require(_PACKAGE .. '/node_types/run_random')
BehaviourTree.Sequence                = require(_PACKAGE .. '/node_types/sequence')
BehaviourTree.SequenceUntilFailure    = require(_PACKAGE .. '/node_types/sequence_until_failure')
BehaviourTree.SequenceUntilSuccess    = require(_PACKAGE .. '/node_types/sequence_until_success')
BehaviourTree.Decorator               = require(_PACKAGE .. '/node_types/decorator')
BehaviourTree.InvertDecorator         = require(_PACKAGE .. '/node_types/invert_decorator')
BehaviourTree.AlwaysFailDecorator     = require(_PACKAGE .. '/node_types/always_fail_decorator')
BehaviourTree.AlwaysSucceedDecorator  = require(_PACKAGE .. '/node_types/always_succeed_decorator')
BehaviourTree.RepeaterDecorator       = require(_PACKAGE .. '/node_types/repeater_decorator')
BehaviourTree.RunTimeOutcomeDecorator = require(_PACKAGE .. '/node_types/run_time_outcome_decorator')
BehaviourTree.InterruptDecorator      = require(_PACKAGE .. '/node_types/interrupt_decorator')

BehaviourTree.register                = Registry.register


-- IMPORTANT NOTES TO SELF:
-- Dont forget to change readme, now "node" is a "childNode" and "nodes" are "childNodes"
-- BehaviourTree.register now registers node type, not node by name

-- Getting a hold on important environment methods
-- Code parsing method -------------------------
local loadCodeHere = _G.load or _G.loadstring or imports.loadCodeHere
g.loadCodeInScope  = imports.loadCodeInScope or function(code, scope)
  local func, err = loadCodeHere(code)
  if func then
    setfenv(func, scope) -- Set the environment to the provided scope
    return func
  else
    return nil, err
  end
end
-- Time measuring method -----------------------
g.clock            = _G.clock or os.clock or imports.clock
------------------------------------------------


-- Registering premade nodes -------------------
RegisterPremadeNodes(Registry)
Registry.register('Sequence', BehaviourTree.Sequence)
Registry.register('SequenceUntilFailure', BehaviourTree.SequenceUntilFailure)
Registry.register('SequenceUntilSuccess', BehaviourTree.SequenceUntilSuccess)
Registry.register('RunRandom', BehaviourTree.RunRandom)
Registry.register('Repeater', BehaviourTree.RepeaterDecorator)
Registry.register('Inverter', BehaviourTree.InvertDecorator)
Registry.register('AlwaysSucceed', BehaviourTree.AlwaysSucceedDecorator)
Registry.register('AlwaysFail', BehaviourTree.AlwaysFailDecorator)
Registry.register('RunTimeOutcome', BehaviourTree.RunTimeOutcomeDecorator)
------------------------------------------------



-- Behaviour tree methods --------------------------------------------------
----------------------------------------------------------------------------
-- BehaviourTree is essentially a Node class extension that represents a root node and the tree itself
function BehaviourTree:initialize(config)
  Node.initialize(self, config)

  self.childNode = config.root

  -- Walking the tree and setting up important properties
  -- This is borked, do it differently

  local function process(node, lvl)
    node.tree = self
    node.level = lvl
    if node.childNode then
      node.childNode.parentNode = node
      process(node.childNode, lvl + 1)
    end
    if node.childNodes then
      for i, childNode in pairs(node.childNodes) do
        childNode.parentNode = node
        process(childNode, lvl + 1)
      end
    end
  end
  process(self, 1)

  -- Interrupts
  self.interrupts = {}

  -- Next run will be the first one, so starting logic should be triggered
  self.firstRun = true

  -- Debugging variables
  self.debugLevel = 0
  self.branchString = ""
  self.lastPrint = ""

  self:print("Behaviour Tree " .. config.name .. " INITIALIZED!")
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

local function walkUpAndAbort(node, level)
  if node.level >= level then
    node:abort()
    if node.parentNode then walkUpAndAbort(node.parentNode, level) end
  end
end

function BehaviourTree:run()
  if self.firstRun then
    self:start()
    self.childNode:start()
    if self.finished then return end
    self.firstRun = false
  end

  -- check interrupts
  -- as of right now topmost interrupts first
  for level, interrupts in pairs(self.interrupts) do
    for i, interrupt in pairs(interrupts) do
      local should = interrupt:shouldInterrupt()
      if should then
        -- If interrupted, need to walk the brunch all the way up to the same level as the interrupt, and call finish on everything.
        -- but what if interrupt will interrupt itself? Good question! Probably should be handled by the node developer.

        -- This will walk up the old branch aborting everything, which in turn will deregister interrupts registered in that branch
        walkUpAndAbort(self.activeNode, interrupt.level)

        -- Should stop looping here
        interrupt:doInterrupt()

        goto fullbreak
      end
    end
  end
  ::fullbreak::

  if self.activeNode then
    self.activeNode:run()
  end
end

function BehaviourTree:success()
  -- Behaviour tree is essentially an infinite repeater, it will start its child again on next run()
  Node.success(self)

  self.activeNode = nil
  self.firstRun = true
end

function BehaviourTree:fail()
  -- Behaviour tree is essentially an infinite repeater, it will start its child again on next run()
  Node.fail(self)

  self.activeNode = nil
  self.firstRun = true
end

-- Debugging functions ----------------------------------------
BehaviourTree.debugLevel = 0
BehaviourTree.branchString = ""
BehaviourTree.lastPrint = ""

function BehaviourTree:setDebugLevel(val)
  self.debugLevel = val
end

function BehaviourTree:print(msg, lvl)
  if lvl == nil then lvl = 1 end

  if lvl <= self.debugLevel then
    print("[" .. tostring(self.name) .. " DEBUG]:", msg)
    self.lastPrint = msg
  end
end

function BehaviourTree:printLazy(msg, lvl)
  if self.lastPrint ~= msg then
    self:print(msg, lvl)
  end
end

----------------------------------------------------------------
----------------------------------------------------------------


-- Json data loading method ------------------------------------
----------------------------------------------------------------
BehaviourTree.LoadBehavior3Project = function(jsonTable, state)
  local roots = ParseBehavior3Project(jsonTable, state)

  for title, root in pairs(roots) do
    roots[title] = BehaviourTree:new({ root = root, name = title })
    roots[title]:setStateObject(state)
  end

  return roots
end
------------------------------------------------------------------
------------------------------------------------------------------

return BehaviourTree
