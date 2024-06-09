local _PACKAGE        = (...):match("^(.+)[%./][^%./]+"):gsub("[%./]?node_types", "")
local class           = require(_PACKAGE .. '/middleclass')
local Decorator       = require(_PACKAGE .. '/node_types/decorator')
local InvertDecorator = class('InvertDecorator', Decorator)

function InvertDecorator:success()
  self.parentNode:fail()
end

function InvertDecorator:fail()
  self.parentNode:success()
end

return InvertDecorator
