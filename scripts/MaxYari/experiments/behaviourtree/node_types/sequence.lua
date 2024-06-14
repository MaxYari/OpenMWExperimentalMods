local _PACKAGE   = (...):match("^(.+)[%./][^%./]+"):gsub("[%./]?node_types", "")
local class      = require(_PACKAGE .. '/middleclass')
local BranchNode = require(_PACKAGE .. '/node_types/branch_node')
local Node       = require(_PACKAGE .. '/node_types/node')
local Sequence   = class('Sequence', BranchNode)

function Sequence:switchToNextChild()
  local index = self.childNode.indexInParent

  while index < #self.childNodes do
    index = index + 1
    self.childNode = self.childNodes[index]
    if not self.childNode.branchIgnore then
      return
    end
  end

  self.childNode = nil
end

function Sequence:start()
  BranchNode.start(self)

  if #self.usableChildNodes == 0 then
    return self:fail()
  end
  self.childNode = self.usableChildNodes[1]
  self.childNode:start()
end

function Sequence:success()
  self:switchToNextChild()
  if self.childNode then
    self.childNode:start()
  else
    -- Out of children, we are done
    BranchNode.success(self)
  end
end

function Sequence:fail()
  BranchNode.fail(self)
end

return Sequence
