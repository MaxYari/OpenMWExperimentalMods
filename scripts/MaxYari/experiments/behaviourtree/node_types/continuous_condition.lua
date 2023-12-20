local _PACKAGE            = (...):match("^(.+)[%./][^%./]+"):gsub("[%./]?node_types", "")
local class               = require(_PACKAGE .. '/middleclass')
local Decorator           = require(_PACKAGE .. '/node_types/decorator')
local ContinuousCondition = class('ContinuousCondition', Decorator)

function ContinuousCondition:initialize(config)
  Decorator.initialize(self, config)
end

function ContinuousCondition:start(object)
  --print("Starting continuous condition")
  self.childNodeRunning = false
  local conditionMet = self.conditionFn(self, object)

  if conditionMet then
    self.childNodeRunning = true
    self.node:setControl(self)
    self.node:start(object)
  end
end

function ContinuousCondition:run(object)
  --print("Running condition")
  local conditionMet = self.conditionFn(self, object)

  if self.childNodeRunning and conditionMet then
    self.node:call_run(object)
  else
    if self.childNodeRunning then
      self.node:fail(object)
    else
      self:fail(object)
    end
  end
end

function ContinuousCondition:finish(object)
  --print("Continuous condition finished")
  -- This is responsible for calling finish on all children down the hierarchy
  if self.childNodeRunning then
    self.node:finish(object)
  end
end

return ContinuousCondition
