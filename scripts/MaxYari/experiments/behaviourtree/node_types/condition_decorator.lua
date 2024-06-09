local _PACKAGE           = (...):match("^(.+)[%./][^%./]+"):gsub("[%./]?node_types", "")
local class              = require(_PACKAGE .. '/middleclass')
local Decorator          = require(_PACKAGE .. '/node_types/decorator')
local ConditionDecorator = class('ConditionDecorator', Decorator)

function ConditionDecorator:start(object)
  self.childCanRun = false
  local conditionMet = self.condition(self, object)

  if conditionMet then
    self.childCanRun = true
    self.childNode:setParentNode(self)
    self.childNode:start(object)
  end
end

function ConditionDecorator:run(object)
  --print("Running condition")
  if self.childCanRun then
    self.childNode:setParentNode(self)
    self.childNode:call_run(object)
  else
    self:fail()
  end
end

function ConditionDecorator:finish(object)
  -- This is responsible for calling finish on all children down the hierarchy
  if self.childCanRun then
    self.childNode:finish(object)
  end
end

return ConditionDecorator
