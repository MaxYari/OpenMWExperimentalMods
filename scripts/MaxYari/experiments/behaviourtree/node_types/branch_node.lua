local _PACKAGE   = (...):match("^(.+)[%./][^%./]+"):gsub("[%./]?node_types", "")
local class      = require(_PACKAGE .. '/middleclass')
local Registry   = require(_PACKAGE .. '/registry')
local Node       = require(_PACKAGE .. '/node_types/node')
local BranchNode = class('BranchNode', Node)

function BranchNode:start(object)
  if not self.nodeRunning then
    self:setStateObject(object)
    self.actualTask = 1
  end
end

function BranchNode:run(object)
  if self.actualTask <= #self.childNodes then
    self:_run(object)
  end
end

function BranchNode:_run(object)
  if not self.nodeRunning then
    self.childNode = Registry.getNode(self.childNodes[self.actualTask])
    self.childNode:start(object)
    self.childNode:setParentNode(self)
  end
  self.childNode:run(object)
end

function BranchNode:running()
  self.nodeRunning = true
  self.parentNode:running()
end

function BranchNode:success()
  self.nodeRunning = false
  self.childNode:finish(self.stateObject)
  self.childNode = nil
end

function BranchNode:fail()
  self.nodeRunning = false
  self.childNode:finish(self.stateObject);
  self.childNode = nil
end

return BranchNode
