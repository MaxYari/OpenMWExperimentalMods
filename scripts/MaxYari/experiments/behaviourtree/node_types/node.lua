local _PACKAGE = (...):match("^(.+)[%./][^%./]+"):gsub("[%./]?node_types", "")
local class    = require(_PACKAGE .. '/middleclass')
local Node     = class('Node')
local g        = _BehaviourTreeGlobals

function Node:initialize(config)
  config = config or {}
  for k, v in pairs(config) do
    self[k] = v
  end
end

-- Functions provided by developer
function Node:start() end

function Node:finish() end

function Node:run() end

function Node:call_run(object)
  -- Status report functions, statuses propagate up from children to parent
  success = function() self:success() end
  fail = function() self:fail() end
  running = function() self:running() end
  self:run(object)
  success, fail, running = nil, nil, nil
end

function Node:setStateObject(object)
  self.stateObject = object
end

function Node:setParentNode(control)
  self.parentNode = control
end

function Node:running()
  -- Adding this node's name to a branch string for debug printing
  local name = self.name or self.name or "NONAME_NODE"
  g.branchString = g.branchString .. "--" .. name

  -- Bubble running state to parent
  if self.parentNode then
    self.parentNode:running(self)
  end
end

function Node:success()
  g.print((self.name or self.name or "NONAME_NODE") .. ' SUCCESS')

  if self.parentNode then
    self.parentNode:success()
  end
end

function Node:fail()
  g.print((self.name or "NONAME_NODE") .. ' FAIL')

  if self.parentNode then
    self.parentNode:fail()
  end
end

return Node
