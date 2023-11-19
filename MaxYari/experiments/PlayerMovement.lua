local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local math = _tl_compat and _tl_compat.math or math
local input = require('openmw.input')

local self = require('openmw.self')
local util = require('openmw.util')
local core = require('openmw.core')


local function MoveActorAround(dt)
   local now = core.getRealTime()
   local velocity = util.vector3(150, 150, 150) * math.sin(now)
   local params = {}
   params.maxWalkableSlope = 90;
   params.stepSizeDown = 200;
   params.stepSizeUp = 200;

   self:setCollisionParams(params)

end

return {
   engineHandlers = {
      onUpdate = function(dt)
         MoveActorAround(dt)
      end,
      onKeyPress = function(key)
         if key.symbol == 'x' then

         end
      end,
      onKeyRelease = function(key)
         if key.symbol == 'x' then

         end
      end,
   },
}
