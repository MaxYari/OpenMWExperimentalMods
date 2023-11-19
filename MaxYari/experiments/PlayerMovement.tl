
local input = require('openmw.input')

local self = require('openmw.self')
local util = require('openmw.util')
local core = require('openmw.core')


local function MoveActorAround(dt: number)
    local now = core.getRealTime()
    local velocity = util.vector3(150,150,150) * math.sin(now)
    local params: ActorCollisionParams = {}
    params.maxWalkableSlope = 90;
    params.stepSizeDown = 200;
    params.stepSizeUp = 200;
    --self:setFlying(true)
    self:setCollisionParams(params)
    --self:setVelocity(velocity)
end

return {
    engineHandlers = {
        onUpdate = function(dt: number)
            MoveActorAround(dt)
        end,
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