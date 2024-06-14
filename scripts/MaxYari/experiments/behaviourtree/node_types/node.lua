local _PACKAGE = (...):match("^(.+)[%./][^%./]+"):gsub("[%./]?node_types", "")
local class    = require(_PACKAGE .. '/middleclass')
local Node     = class('Node')
local g        = _BehaviourTreeGlobals

function Node:initialize(config)
  self._config = config or {}
  self.name = self._config.name
end

-- All the node:fn functions can be overriden in child classes to implement new node types. If you want to call the
-- original child function from the override do Child.fn(self, otherArguments)
function Node:initApiObject()
  self.api = {
    -- Functions provided by the module user
    start = function(self, stateObject) end,
    run = function(self, stateObject) end,
    finish = function(self, stateObject) end,
    shouldInterrupt = function(self, stateObject) end, --Interrupts only
    registered = function(self, stateObject) end,      --Interrupts only
    triggered = function(self, stateObject) end,       --Interrupts only
  }

  for k, v in pairs(self._config) do
    self.api[k] = v
  end
end

function Node:registerApiStatusFunctions()
  self.api.success = function() self:success() end
  self.api.fail = function() self:fail() end
  -- running is as needed inside the run() function
end

function Node:deregisterApiStatusFunctions()
  self.api.success = nil
  self.api.fail = nil
  self.api.running = nil
end

function Node:start()
  g.print(self._config.name .. " STARTED")
  -- Api is repopulated anew after every start
  self:initApiObject()
  self:registerApiStatusFunctions()
  self.finished = false

  self.tree:setActiveNode(self)

  self.api:start(self.tree.stateObject)
end

function Node:run()
  self.api.running = function() self:running() end
  self.api:run(self.tree.stateObject)
  self.api.running = nil --deregister so it can not be called outside the run function
end

-- This finish is a finish without success or fail
function Node:abort() -- Should rename to abort
  -- Call user-facing finish callback
  g.printLazy(self._config.name .. " ABORTED")
  self:finish()
end

-- TASK STATUSES - triggered by the module user, bubble up from childrent to parents
function Node:running()
  -- Adding this node's name to a branch string for debug printing
  g.printLazy(self._config.name .. " RUNNING")
end

function Node:success()
  g.print((self.name or "NONAME_NODE") .. ' SUCCESS')

  self:finish()
  if self.parentNode then
    self.parentNode:success()
  end
end

function Node:fail()
  g.print((self.name or "NONAME_NODE") .. ' FAIL')

  -- Deregister interrupts on the level below
  self.tree:deregisterInterrupts(self.level + 1)

  self:finish()
  if self.parentNode then
    self.parentNode:fail()
  end
end

function Node:finish()
  self:deregisterApiStatusFunctions()
  self.finished = true
  self.api:finish(self.tree.stateObject)
end

return Node
