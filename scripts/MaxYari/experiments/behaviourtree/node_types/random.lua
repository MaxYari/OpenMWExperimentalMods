local _PACKAGE   = (...):match("^(.+)[%./][^%./]+"):gsub("[%./]?node_types", "")
local class      = require(_PACKAGE .. '/middleclass')
local BranchNode = require(_PACKAGE .. '/node_types/branch_node')
local Random     = class('Random', BranchNode)

function Random:start(object)
  BranchNode.start(self, object)
  self.actualTask = math.floor(math.random() * #self.childNodes + 1)
end

function Random:success()
  BranchNode.success(self)
  self.parentNode:success()
end

function Random:fail()
  BranchNode.fail(self)
  self.parentNode:fail()
end

return Random
