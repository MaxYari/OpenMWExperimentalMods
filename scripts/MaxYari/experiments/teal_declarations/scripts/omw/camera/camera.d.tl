--[[
  require('openmw.interfaces').Camera
]]

local record Camera
  --[[
    Disable with (optional) tag until the corresponding enable function is called with the same tag.
  ]]
  disableHeadBobbing: function(
    tag: string
  )
  
  --[[
    Disable with (optional) tag until the corresponding enable function is called with the same tag.
  ]]
  disableModeControl: function(
    tag: string
  )
  
  --[[
    Disable with (optional) tag until the corresponding enable function is called with the same tag.
  ]]
  disableStandingPreview: function(
    tag: string
  )
  
  --[[
    Disable with (optional) tag until the corresponding enable function is called with the same tag.
  ]]
  disableThirdPersonOffsetControl: function(
    tag: string
  )
  
  --[[
    Disable with (optional) tag until the corresponding enable function is called with the same tag.
  ]]
  disableZoom: function(
    tag: string
  )
  
  --[[
    Undo disableHeadBobbing
  ]]
  enableHeadBobbing: function(
    tag: string
  )
  
  --[[
    Undo disableModeControl
  ]]
  enableModeControl: function(
    tag: string
  )
  
  --[[
    Undo disableStandingPreview
  ]]
  enableStandingPreview: function(
    tag: string
  )
  
  --[[
    Undo disableThirdPersonOffsetControl
  ]]
  enableThirdPersonOffsetControl: function(
    tag: string
  )
  
  --[[
    Undo disableZoom
  ]]
  enableZoom: function(
    tag: string
  )
  
  --[[
    Get base third person distance (without applying angle and speed modifiers).
  ]]
  getBaseThirdPersonDistance: function(): number
  
  --[[
    Return primary mode (MODE.FirstPerson or MODE.ThirdPerson).
  ]]
  getPrimaryMode: function(): number
  
  --[[
    Get the desired third person distance if there would be no obstacles (with angle and speed modifiers)
  ]]
  getTargetThirdPersonDistance: function(): number
  
  --[[
    Whether head bobbing is enabled.
  ]]
  isHeadBobbingEnabled: function(): boolean
  
  --[[
    Whether the built-in mode control logic is enabled.
  ]]
  isModeControlEnabled: function(): boolean
  
  --[[
    Whether the built-in standing preview logic is enabled.
  ]]
  isStandingPreviewEnabled: function(): boolean
  
  --[[
    Whether the the third person offset can be changed by the built-in camera script.
  ]]
  isThirdPersonOffsetControlEnabled: function(): boolean
  
  --[[
    Whether the built-in zooming is enabled.
  ]]
  isZoomEnabled: function(): boolean
  
  --[[
    Set base third person distance
  ]]
  setBaseThirdPersonDistance: function(
    value: number
  )
  
  --[[
    Interface version is 1
  ]]
  version: number
  
end
return Camera