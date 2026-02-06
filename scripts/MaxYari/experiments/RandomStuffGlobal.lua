

local world = require('openmw.world')
local util = require('openmw.util')

local frame = 0

local function onUpdate(dt)
    for _, player in ipairs(world.players) do
        local vel = 10
        local newPos = player.position + util.vector3(vel*dt, 0, 0)
              
        player:teleport(player.cell, newPos, options)        
    end
end


return {
    engineHandlers = {
       onUpdate = onUpdate
    }
}
