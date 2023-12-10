--[[
  require('openmw.interfaces').UI
]]

local record UI
  --[[
    All available UI modes.
    Use `view(I.UI.MODE)` in `luap` console mode to see the list.
  ]]
  MODE: table
  
  --[[
    All windows.
    Use `view(I.UI.WINDOW)` in `luap` console mode to see the list.
  ]]
  WINDOW: table
  
  --[[
    Add mode to stack without dropping other active modes.
    I.UI.addMode('Journal') -- open journal without dropping active modes.
  ]]
  addMode: function(
    mode: string, --[[New mode]]
    options: table
  )
  
  --[[
    Get current mode (nil if all windows are closed), equivalent to `I.UI.modes[#I.UI.modes]`
  ]]
  getMode: function(): string
  
  --[[
    Returns windows that can be shown in given mode.
  ]]
  getWindowsForMode: function(
    mode: string
  ): table
  
  --[[
    Returns if the player HUD is visible or not
  ]]
  isHudVisible: function(): boolean
  
  --[[
    Stack of currently active modes
  ]]
  modes: any
  
  --[[
    Register new implementation for the window with given name; overrides previous implementation.
    Adding new windows is not supported yet. At the moment it is only possible to override built-in windows.
  ]]
  registerWindow: function(
    windowName: string,
    showFn: function, --[[Callback that will be called when the window should become visible]]
    hideFn: function
  )
  
  --[[
    Remove the specified mode from active modes.
  ]]
  removeMode: function(
    mode: string
  )
  
  --[[
    Set whether the UI should be visible.
  ]]
  setHudVisibility: function(
    showHud: boolean
  )
  
  --[[
    Drop all active modes and set mode.
    I.UI.setMode() -- drop all modes
  ]]
  setMode: function(
    mode: string, --[[(optional) New mode]]
    options: table
  )
  
  --[[
    Set whether the mode should pause the game.
  ]]
  setPauseOnMode: function(
    mode: string, --[[Mode to configure]]
    shouldPause: boolean
  )
  
  --[[
    Interface version
  ]]
  version: number
  
end
return UI