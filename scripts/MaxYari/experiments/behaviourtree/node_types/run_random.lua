local _PACKAGE   = (...):match("^(.+)[%./][^%./]+"):gsub("[%./]?node_types", "")
local class      = require(_PACKAGE .. '/middleclass')
local BranchNode = require(_PACKAGE .. '/node_types/branch_node')
local RunRandom  = class('RunRandom', BranchNode)

function RunRandom:start()
  BranchNode.start(self)

  self.avoidRepeats = false
  if self.p.avoidRepeats then self.avoidRepeats = self.p.avoidRepeats() end

  if #self.usableChildNodes == 0 then
    return self:fail()
  end

  self.childNode = self.usableChildNodes[math.floor(math.random() * #self.usableChildNodes + 1)]

  if self.lastSelectedNode then
    table.insert(self.usableChildNodes, self.lastSelectedNode.indexInParent, self.lastSelectedNode)
    self.lastSelectedNode = nil
  end
  if self.avoidRepeats then
    self.lastSelectedNode = self.childNode
    table.remove(self.usableChildNodes, self.lastSelectedNode.indexInParent)
  end

  self.childNode:start()
end

return RunRandom
