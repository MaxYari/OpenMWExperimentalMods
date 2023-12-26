local ui = require('openmw.ui')
local input = require('openmw.input')
local nearby = require('openmw.nearby')
local camera = require('openmw.camera')
local self = require('openmw.self')
local util = require('openmw.util')
local core = require('openmw.core')
local types = require('openmw.types')
local camera = require('openmw.camera')
local I = require('openmw.interfaces')

-- Config ------------------
----------------------------
local distanceToPlayer = 400
local verticalOffset = 100
----------------------------
----------------------------


local function onUpdate(dt: number)
    camera.setMode(camera.MODE.Static)
    camera.setStaticPosition(self.object.position + util.vector3(0,1,0)*distanceToPlayer + util.vector3(0,0,1)*verticalOffset)
    -- Adjust yaw to alway look at the player
    camera.setYaw(camera.getYaw()+ 1*dt)
    camera.setPitch(0)
    camera.setRoll(0)  
    
    local look = self.object.position - camera.getPosition()
    local yaw = math.atan2(look.x, look.y)
    
    camera.setYaw(yaw)
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onKeyPress = function(key: input.KeyboardEvent)
            if key.symbol == 'x' then
                
            end
        end,
        onKeyRelease = function(key: input.KeyboardEvent)
            if key.symbol == 'x' then
                
            end
        end
    }
}