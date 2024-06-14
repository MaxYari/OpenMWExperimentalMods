local _PACKAGE   = (...):match("^(.+)[%./][^%./]+"):gsub("[%./]?node_types", "")
local class      = require(_PACKAGE .. '/middleclass')
local BranchNode = require(_PACKAGE .. '/node_types/branch_node')
local Node       = require(_PACKAGE .. '/node_types/node')
local Priority   = class('Priority', BranchNode)

function Priority:selectChild()
  self.childIndex = self.childIndex + 1
  BranchNode.selectChild(self)
end

function Priority:success()
  Node.success(self)
end

function Priority:fail()
  BranchNode.fail(self)
  -- Out of children, we are done
  if not self.childNode then
    Node.fail(self)
  end
end

return Priority
