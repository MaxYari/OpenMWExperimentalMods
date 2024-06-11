local _PACKAGE          = (...):match("^(.+)[%./][^%./]+"):gsub("[%./]?node_types", "")
local class             = require(_PACKAGE .. '/middleclass')
local Decorator         = require(_PACKAGE .. '/node_types/decorator')
local RepeaterDecorator = class('RepeaterDecorator', Decorator)
local g                 = _BehaviourTreeGlobals

-- Note that decorators can override whatever, its not expected for developer to create decorator types by providing configs simlarly to how tasks are created.
-- New decorator types should be create similarly to this one - through overrides.
function RepeaterDecorator:start(state)
  Decorator.start(self, state)
  self:setStateObject(state)

  self.currentLoop = 1
  if self.maxLoop == nil then self.maxLoop = -1 end
end

function RepeaterDecorator:success()
  self.childNode:finish(self.stateObject)

  self.currentLoop = self.currentLoop + 1
  if self.untilSuccess then
    g.print((self.name or self.name or "NONAME_NODE") .. ' SUCCESS')
    return self.parentNode:success()
  elseif self.maxLoop ~= -1 and self.currentLoop > self.maxLoop then
    -- Out of repetitions
    if self.untilFailure then
      g.print((self.name or self.name or "NONAME_NODE") .. ' FAIL [maxLoop reached]')
      return self.parentNode:fail() -- We were hoping to repeat until failure, but failed at failure.
    else
      g.print((self.name or self.name or "NONAME_NODE") .. ' SUCCESS [maxLoop reached]')
      return self.parentNode:success() -- We were not waiting untilSuccess or untilFailure, whatever was the outcome of repititions - we did them all, this is considered a success.
    end
  else
    g.print((self.name or self.name or "NONAME_NODE") .. ' REPEAT')
    self.childNode:setParentNode(self)
    self.childNode:start(self.stateObject)

    return self.parentNode:running()
  end
end

function RepeaterDecorator:fail()
  self.childNode:finish(self.stateObject)

  self.currentLoop = self.currentLoop + 1
  if self.untilFailure then
    g.print((self.name or self.name or "NONAME_NODE") .. ' SUCCESS')
    return self.parentNode:success()
  elseif self.maxLoop ~= -1 and self.currentLoop > self.maxLoop then
    -- Out of repetitions
    if self.untilSuccess then
      g.print((self.name or self.name or "NONAME_NODE") .. ' FAIL [maxLoop reached]')
      return self.parentNode:fail() -- We were hoping to repeat until success, but failed at success.
    else
      g.print((self.name or self.name or "NONAME_NODE") .. ' SUCCESS [maxLoop reached]')
      return self.parentNode:success() -- We were not waiting untilSuccess or untilFailure, whatever was the outcome of repititions - we did them all, this is considered a success.
    end
  else
    g.print((self.name or self.name or "NONAME_NODE") .. ' REPEAT')
    self.childNode:setParentNode(self)
    self.childNode:start(self.stateObject)

    return self.parentNode:running()
  end
end

return RepeaterDecorator
