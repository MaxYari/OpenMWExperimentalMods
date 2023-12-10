--[[
  require('openmw.interfaces').Controls
]]

local record Controls
  --[[
    When set to true then the controls "attack", "toggle spell", "toggle weapon" are not processed and can be handled by another script.
    If combat should be disallowed completely, consider to use `types.Player.setControlSwitch` instead.
  ]]
  overrideCombatControls: function(
    value: boolean
  )
  
  --[[
    When set to true then the movement controls including jump and sneak are not processed and can be handled by another script.
    If movement should be disallowed completely, consider to use `types.Player.setControlSwitch` instead.
  ]]
  overrideMovementControls: function(
    value: boolean
  )
  
  --[[
    When set to true then the controls "open inventory", "open journal" and so on are not processed and can be handled by another script.
  ]]
  overrideUiControls: function(
    value: boolean
  )
  
  --[[
    Interface version
  ]]
  version: number
  
end
return Controls