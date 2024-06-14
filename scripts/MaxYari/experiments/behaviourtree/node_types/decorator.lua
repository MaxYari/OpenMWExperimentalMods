local _PACKAGE  = (...):match("^(.+)[%./][^%./]+"):gsub("[%./]?node_types", "")
local class     = require(_PACKAGE .. '/middleclass')
local Node      = require(_PACKAGE .. '/node_types/node')
local Decorator = class('Decorator', Node)

function Decorator:initialize(config)
  if config.childNode then
    self.childNode = config.childNode
  end
  Node.initialize(self, config)
end

function Decorator:start()
  Node.start(self)

  --Its possible that .start resulted in a Node reporting a success/fail task and finishing, in that case we should terminate. Reporting a success/fail state was supposedly
  --already done, since finished flag is set after that
  if self.finished then return end

  --Register all interrupts
  if self.childNode.isInterrupt then
    self.tree:registerInterrupt(self.childNode)
  end

  --The only child is an interrupt (or another node) that doesnt want to be called directly, so can't do much of anything here but fail
  if self.childNode.branchIgnore then
    return self:fail()
  end

  self.childNode:start()
end

function Decorator:abort()
  self.childNode:abort()
  Node.abort(self)
end

function Decorator:run()
  Node.run(self)
  self.childNode:run()
end

function Decorator:finish()
  -- Deregister interrupts on the level below
  self.tree:deregisterInterrupts(self.level + 1)
  Node.finish(self)
end

return Decorator
