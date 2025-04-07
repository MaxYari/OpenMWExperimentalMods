local core = require('openmw.core')
local world = require('openmw.world')
local util = require('openmw.util')


local function onUpdate(dt)
    
   
end

local function handleTeleportRequest(eventData)
    local object = eventData.object
    local position = eventData.position
    local rotation = eventData.rotation

    if object and object:isValid() then
        object:teleport(object.cell, position, { rotation = rotation })
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate
    },
    eventHandlers = {
        TeleportRequest = handleTeleportRequest
    }
}
