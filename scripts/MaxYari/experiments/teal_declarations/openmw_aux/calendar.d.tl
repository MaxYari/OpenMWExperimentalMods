--[[
  `openmw_aux.calendar` defines utility functions for formatting game time.
  Implementation can be found in `resources/vfs/openmw_aux/calendar.lua`.
  local calendar = require('openmw_aux.calendar')
]]

local record calendar
  --[[
    The number of days in a month
  ]]
  daysInMonth: function(
    monthIndex: any
  ): number
  
  --[[
    The number of days in a week
  ]]
  daysInWeek: number
  
  --[[
    The number of days in a year
  ]]
  daysInYear: number
  
  --[[
    An equivalent of `os.date` for game time.
    See [https://www.lua.org/pil/22.1.html](https://www.lua.org/pil/22.1.html).
    It is a slow function. Please try not to use it in every frame.
  ]]
  formatGameTime: function(
    format: string, --[[format of date (optional)]]
    time: number
  ): string
  
  --[[
    An equivalent of `os.time` for game time.
    See [https://www.lua.org/pil/22.1.html](https://www.lua.org/pil/22.1.html)
  ]]
  gameTime: function(
    table: table
  ): number
  
  --[[
    The number of months in a year
  ]]
  monthCount: number
  
  --[[
    The name of a month
  ]]
  monthName: function(
    monthIndex: any
  ): string
  
  --[[
    The name of a month in genitive (for English is the same as `monthName`, but in some languages the form can differ).
  ]]
  monthNameInGenitive: function(
    monthIndex: any
  ): string
  
  --[[
    The name of a weekday
  ]]
  weekdayName: function(
    dayIndex: any
  ): string
  
end
return calendar