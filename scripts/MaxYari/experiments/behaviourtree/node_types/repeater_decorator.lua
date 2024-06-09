local _PACKAGE          = (...):match("^(.+)[%./][^%./]+"):gsub("[%./]?node_types", "")
local class             = require(_PACKAGE .. '/middleclass')
local Decorator         = require(_PACKAGE .. '/node_types/decorator')
local RepeaterDecorator = class('RepeaterDecorator', Decorator)

-- Note that decorators can override whatever, its not expected for developer to create decorator types by providing configs simlarly to how tasks are created.
-- New decorator types should be create similarly to this one - through overrides.
function RepeaterDecorator:start(state)
  self:setStateObject(state)
end

function RepeaterDecorator:success()
  -- Ooops we need to store object somehow somewhere (object is a state), maybe in call_run, using self.setObject?
  print("Repeater success, starting node again")
  self.childNode:setParentNode(self)     --This lets the child know who's its parent
  self.childNode:start(self.stateObject) --Do we also need to trigger run? Probably not.
end

function RepeaterDecorator:fail()
  -- Ooops we need to store object somehow somewhere (object is a state)
  print("Repeater failure, starting node again")
  self.childNode:setParentNode(self)
  self.childNode:start(self.stateObject)
end

return RepeaterDecorator
