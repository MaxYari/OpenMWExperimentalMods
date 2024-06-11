local _PACKAGE                     = (...):match("^(.+)[%./][^%./]+"):gsub("[%./]?node_types", "")
local class                        = require(_PACKAGE .. '/middleclass')
local Decorator                    = require(_PACKAGE .. '/node_types/decorator')
local ContinuousConditionDecorator = class('ContinuousConditionDecorator', Decorator)

function ContinuousConditionDecorator:start(object)
  --print("Starting continuous condition")
  self.childNodeRunning = false
  local conditionMet = self.condition(self, object)

  if conditionMet then
    self.childNodeRunning = true
    self.childNode:setParentNode(self)
    self.childNode:start(object)
  end
end

function ContinuousConditionDecorator:run(object)
  --print("Running condition")
  local conditionMet = self.condition(self, object)

  if conditionMet then
    self.childNode:call_run(object)
  else
    if self.childNodeRunning then
      self.childNode:finish(object)
    end
    self:fail(object)
  end
end

function ContinuousConditionDecorator:finish(object)
  if self.childNodeRunning then self.childNode:finish(object) end
end

return ContinuousConditionDecorator
