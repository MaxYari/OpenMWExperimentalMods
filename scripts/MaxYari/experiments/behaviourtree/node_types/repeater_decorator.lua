local _PACKAGE          = (...):match("^(.+)[%./][^%./]+"):gsub("[%./]?node_types", "")
local class             = require(_PACKAGE .. '/middleclass')
local Decorator         = require(_PACKAGE .. '/node_types/decorator')
local RepeaterDecorator = class('RepeaterDecorator', Decorator)
local g                 = _BehaviourTreeGlobals

function RepeaterDecorator:initialize(config)
  Decorator.initialize(self, config)

  self.maxLoop = config.maxLoop
  self.untilSuccess = config.untilSuccess
  self.untilFailure = config.untilFailure
end

function RepeaterDecorator:start()
  Decorator.start(self)

  self.currentLoop = 1
  if self.maxLoop == nil then self.maxLoop = -1 end
end

function RepeaterDecorator:success()
  self.currentLoop = self.currentLoop + 1
  if self.untilSuccess then
    return Decorator.success(self)
  elseif self.maxLoop ~= -1 and self.currentLoop > self.maxLoop then
    -- Out of repetitions
    if self.untilFailure then
      g.print("REPEATER maxLoop REACHED")
      return Decorator.fail(self) -- We were hoping to repeat until failure, but failed at failure.
    else
      g.print("REPEATER maxLoop REACHED")
      return Decorator.success(self) -- We were not waiting untilSuccess or untilFailure, whatever was the outcome of repititions - we did them all, this is considered a success.
    end
  else
    g.print((self.name or self.name or "NONAME_NODE") .. ' REPEAT')
    self.childNode:start()

    return Decorator.running(self)
  end
end

function RepeaterDecorator:fail()
  self.currentLoop = self.currentLoop + 1
  if self.untilFailure then
    return Decorator.success(self)
  elseif self.maxLoop ~= -1 and self.currentLoop > self.maxLoop then
    -- Out of repetitions
    if self.untilSuccess then
      g.print("REPEATER maxLoop REACHED")
      return Decorator.fail(self) -- We were hoping to repeat until success, but failed at success.
    else
      g.print("REPEATER maxLoop REACHED")
      return Decorator.success(self) -- We were not waiting untilSuccess or untilFailure, whatever was the outcome of repititions - we did them all, this is considered a success.
    end
  else
    g.print((self.name or self.name or "NONAME_NODE") .. ' REPEAT')
    self.childNode:start(self.stateObject)

    return Decorator.running(self)
  end
end

return RepeaterDecorator
