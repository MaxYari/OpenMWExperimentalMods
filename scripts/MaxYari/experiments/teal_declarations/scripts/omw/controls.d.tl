--[[
  `openmw.controls` Allows to override player controls
]]



local record controls
    overrideMovementControls: function(value:boolean)	
    overrideUiControls: function(value:boolean) 
    overrideCombatControls: function(value:boolean)
end

return controls