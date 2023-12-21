local _PACKAGE  = (...):match("^(.+)[%./][^%./]+"):gsub("[%./]?node_types", "")
local class     = require(_PACKAGE .. '/middleclass')
local Decorator = require(_PACKAGE .. '/node_types/decorator')
local Condition = class('Condition', Decorator)

function Condition:initialize(config)
  Decorator.initialize(self, config)
end

function Condition:start(object)
  self.childCanRun = false
  local conditionMet = self.conditionFn(self, object)

  if conditionMet then
    self.childCanRun = true
    self.node:setControl(self)
    self.node:start(object)
  end
end

function Condition:run(object)
  --print("Running condition")
  if self.childCanRun then
    self.node:setControl(self)
    self.node:call_run(object)
  else
    self:fail()
  end
end

function Condition:finish(object)
  -- This is responsible for calling finish on all children down the hierarchy
  if self.childCanRun then
    self.node:finish(object)
  end
end

return Condition
