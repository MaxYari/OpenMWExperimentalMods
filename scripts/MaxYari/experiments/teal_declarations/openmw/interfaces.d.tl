--[[
  local I = require('openmw.interfaces')
]]

local scripts_omw_activationhandlers = require("scripts.omw.activationhandlers")
local scripts_omw_ai = require("scripts.omw.ai")
local scripts_omw_camera_camera = require("scripts.omw.camera.camera")
local scripts_omw_mwui_init = require("scripts.omw.mwui.init")
local scripts_omw_settings_player = require("scripts.omw.settings.player")
local scripts_omw_ui = require("scripts.omw.ui")
local record interfaces
  AI: scripts_omw_ai
  
  Activation: scripts_omw_activationhandlers
  
  Camera: scripts_omw_camera_camera
  
  MWUI: scripts_omw_mwui_init
  
  Settings: scripts_omw_settings_player
  
  UI: scripts_omw_ui
  
  metamethod __index: function(
    self: interfaces,
    key: string
  ): any
  
end
return interfaces