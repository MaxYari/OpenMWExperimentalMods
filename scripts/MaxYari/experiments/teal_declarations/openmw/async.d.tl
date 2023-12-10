--[[
  `openmw.async` contains timers and coroutine utils.
  All functions require
  the package itself as a first argument.
  local async = require('openmw.async')
]]

local record async
  --[[
    Wraps Lua function with `Callback` object that can be used in async API calls.
  ]]
  callback: function(
    self: async,
    func: function
  ): async.Callback
  
  --[[
    Calls callback(arg) in `delay` game seconds.
    Callback must be registered in advance.
  ]]
  newGameTimer: function(
    self: async,
    delay: number,
    callback: async.TimerCallback, --[[A callback returned by `registerTimerCallback`]]
    arg: any
  )
  
  --[[
    Calls callback(arg) in `delay` simulation seconds.
    Callback must be registered in advance.
  ]]
  newSimulationTimer: function(
    self: async,
    delay: number,
    callback: async.TimerCallback, --[[A callback returned by `registerTimerCallback`]]
    arg: any
  )
  
  --[[
    Calls `func()` in `delay` game seconds.
    The timer will be lost if the game is saved and loaded.
  ]]
  newUnsavableGameTimer: function(
    self: async,
    delay: number,
    func: function
  )
  
  --[[
    Calls `func()` in `delay` simulation seconds.
    The timer will be lost if the game is saved and loaded.
  ]]
  newUnsavableSimulationTimer: function(
    self: async,
    delay: number,
    func: function
  )
  
  --[[
    Register a function as a timer callback.
  ]]
  registerTimerCallback: function(
    self: async,
    name: string,
    func: function
  ): async.TimerCallback
  
  record Callback
  end
  record TimerCallback
  end
end
return async