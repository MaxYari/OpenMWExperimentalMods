--[[
  Allows to extend or override built-in item usage mechanics.
  Note: at the moment it can override item usage in inventory
  (dragging an item on the character's model), but
  
  * can't intercept actions performed by mwscripts;
  * can't intercept actions performed by the AI (i.e. drinking a potion in combat);
  * can't intercept actions performed via quick keys menu.
  local I = require('openmw.interfaces')
  
  -- Override Use action (global script).
  -- Forbid equipping armor with weight > 5
  I.ItemUsage.addHandlerForType(types.Armor, function(armor, actor)
      if types.Armor.record(armor).weight > 5 then
          return false -- disable other handlers
      end
  end)
  
  -- Call Use action (any script).
  core.sendGlobalEvent('UseItem', {object = armor, actor = player})
]]

local openmw_core = require("openmw.core")
local record ItemUsage
  --[[
    Add new use action handler for a specific object.
    If `handler(object, actor, options)` returns false, other handlers for
    the same object (including type handlers) will be skipped.
  ]]
  addHandlerForObject: function(
    obj: openmw_core.GameObject, --[[The object.]]
    handler: function
  )
  
  --[[
    Add new use action handler for a type of objects.
    If `handler(object, actor, options)` returns false, other handlers for
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
return ItemUsage