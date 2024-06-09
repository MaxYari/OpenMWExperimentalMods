local _PACKAGE   = (...):match("^(.+)[%./][^%./]+"):gsub("[%./]?node_types", "")
local class      = require(_PACKAGE .. '/middleclass')
local BranchNode = require(_PACKAGE .. '/node_types/branch_node')
local Sequence   = class('Sequence', BranchNode)

function Sequence:success()
  BranchNode.success(self)
  self.actualTask = self.actualTask + 1
  if self.actualTask <= #self.childNodes then
    self:_run(self.stateObject)
  else
    self.parentNode:success()
  end
end

function Sequence:fail()
  BranchNode.fail(self)
  self.parentNode:fail()
end

return Sequence
