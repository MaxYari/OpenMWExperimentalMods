--[[
  require('openmw.interfaces').Activation
]]

local openmw_core = require("openmw.core")
local record Activation
  --[[
    Add new activation handler for a specific object.
    If `handler(object, actor)` returns false, other handlers for
    the same object (including type handlers) will be skipped.
  ]]
  addHandlerForObject: function(
    obj: openmw_core.GameObject, --[[The object.]]
    handler: function
  )
  
  --[[
    Add new activation handler for a type of objects.
    If `handler(object, actor)` returns false, other handlers for
    the same object (including type handlers) will be skipped.
  ]]
  addHandlerForType: function(
    type: any, --[[A type from the `openmw.types` package.]]
    handler: function
  )
  
  --[[
    Interface version
  ]]
  version: number
  
end
return Activation