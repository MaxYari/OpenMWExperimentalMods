local _PACKAGE           = (...):match("^(.+)[%./][^%./]+"):gsub("[%./]?node_types", "")
local class              = require(_PACKAGE .. '/middleclass')
local Decorator          = require(_PACKAGE .. '/node_types/decorator')
local InterruptDecorator = class('InterruptDecorator', Decorator)
local g                  = _BehaviourTreeGlobals

function InterruptDecorator:initialize(config)
  self.isInterrupt = true
  self.branchIgnore = true
  if config.branchIgnore ~= nil then self.branchIgnore = config.branchIgnore end
  Decorator.initialize(self, config)
end

function InterruptDecorator:registered()
  g.print(self.name .. " INTERRUPT REGISTERED")

  self:initApiObject()

  self.api:registered(self.tree.stateObject)
end

function InterruptDecorator:deregistered()
  g.print(self.name .. " INTERRUPT DE-REGISTERED")
end

-- Will be called by the tree root every tree run
function InterruptDecorator:shouldInterrupt()
  local should = self.api:shouldInterrupt(self.tree.stateObject)
  return should
end

function InterruptDecorator:doInterrupt()
  g.print(self.name .. " INTERRUPT TRIGGERED")
  -- in case parent is a branch_node - should notify it that the child is different now
  if self.parentNode and self.parentNode.childSwitch then
    self.parentNode:childSwitch(self)
  end

  self:registerApiStatusFunctions()
  self.finished = false
  self.api:triggered(self.tree.stateObject)

  --Its possible that .triggered resulted in a Node reporting a success/fail task and finishing, in that case we should terminate. Reporting a success/fail state was supposedly
  --already done, since finished flag is set after that
  if self.finished then return end

  self:start()
end

return InterruptDecorator
