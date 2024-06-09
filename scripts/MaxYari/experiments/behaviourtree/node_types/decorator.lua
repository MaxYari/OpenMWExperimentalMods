local _PACKAGE  = (...):match("^(.+)[%./][^%./]+"):gsub("[%./]?node_types", "")
local class     = require(_PACKAGE .. '/middleclass')
local Registry  = require(_PACKAGE .. '/registry')
local Node      = require(_PACKAGE .. '/node_types/node')
local Decorator = class('Decorator', Node)

function Decorator:initialize(config)
  if config.run ~= nil or config.start ~= nil or config.finish ~= nil then
    error(
      "It seems that you are attempting to implement a custom decorator by providing a run/start/finish function to decorator's instance. This is supported only for Tasks. New decorators should be implemented by implementing a new decorator class. See different decorator classes implemented in this library for an example.",
      2)
  end
  Node.initialize(self, config)
  self.childNode = Registry.getNode(self.childNode)
end

function Decorator:setChildNode(node)
  self.childNode = Registry.getNode(node)
end

function Decorator:start(object)
  self.childNode:start(object)
end

function Decorator:finish(object)
  self.childNode:finish(object)
end

function Decorator:run(object)
  self.childNode:setParentNode(self)
  self.childNode:call_run(object)
end

return Decorator
