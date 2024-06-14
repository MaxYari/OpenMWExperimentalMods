local _PACKAGE   = (...):match("^(.+)[%./][^%./]+"):gsub("[%./]?node_types", "")
local class      = require(_PACKAGE .. '/middleclass')
local BranchNode = require(_PACKAGE .. '/node_types/branch_node')
local Random     = class('Random', BranchNode)
local Node       = require(_PACKAGE .. '/node_types/node')

function Random:start()
  BranchNode.start(self)

  if #self.usableChildNodes == 0 then
    return self:fail()
  end

  self.childNode = self.usableChildNodes[math.floor(math.random() * #self.usableChildNodes + 1)]
  self.childNode:start()
end

return Random
