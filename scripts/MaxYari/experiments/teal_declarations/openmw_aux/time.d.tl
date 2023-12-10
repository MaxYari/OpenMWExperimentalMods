--[[
  `openmw_aux.time` defines utility functions for timers.
  Implementation can be found in `resources/vfs/openmw_aux/time.lua`.
  local time = require('openmw_aux.time')
]]

local openmw_async = require("openmw.async")
local record time
  GameTime: string
  
  SimulationTime: string
  
  day: any
  
  hour: number
  
  minute: number
  
  --[[
    Alias of async:newSimulationTimer ; call callback(arg) in `delay` game seconds.
    Callback must be registered in advance.
  ]]
  newGameTimer: function(
    delay: number,
    callback: openmw_async.TimerCallback, --[[A callback returned by `registerTimerCallback`]]
    arg: any, --[[An argument for `callback`; can be `nil`.]]
    callbackArg: any
  )
  
  --[[
    Alias of async:newSimulationTimer ; call callback(arg) in `delay` simulation seconds.
    Callback must be registered in advance.
  ]]
  newSimulationTimer: function(
    delay: number,
    callback: openmw_async.TimerCallback, --[[A callback returned by `registerTimerCallback`]]
    arg: any, --[[An argument for `callback`; can be `nil`.]]
    callbackArg: any
  )
  
  --[[
    Alias of async:registerTimerCallback ; register a function as a timer callback.
  ]]
  registerTimerCallback: function(
    name: string,
    func: function,
    fn: any
  ): openmw_async.TimerCallback
  
  --[[
    Run given function repeatedly.
    Note that loading a save stops the evaluation. If it should work always, call it during initialization of the script (i.e. not in a handler)
    local stopFn = time.runRepeatedly(function() print('Test') end,
                                      5 * time.second)  -- print 'Test' every 5 seconds
    stopFn()  -- stop printing 'Test'
    time.runRepeatedly(  -- print 'Test' every 5 minutes with initial 30 second delay
        function() print('Test2') end, 5 * time.minute,
        { initialDelay = 30 * time.second })
  ]]
  runRepeatedly: function(
    fn: function, --[[the function that should be called]]
    period: number, --[[interval]]
    options: table
  ): function
  
  second: number
  
end
return time