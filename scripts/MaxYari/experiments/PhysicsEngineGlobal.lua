local core = require('openmw.core')
local world = require('openmw.world')
local util = require('openmw.util')
local gutils = require('scripts/MaxYari/experiments/scripts/gutils')


local function onUpdate(dt)
    
   
end

local function handleTeleportRequest(d)
    local object = d.object
    local position = d.position + d.rotation:apply(d.offset)
    local rotation = d.rotation
    --print(object)
    if object and object:isValid() and object.count > 0 then
        object:teleport(object.cell, position, { rotation = rotation })
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate
    },
    eventHandlers = {
        TeleportRequest = handleTeleportRequest,
        SpawnObject = function(e)
            gutils.spawnObject(e.recordId, e.position, e.cell)
        end,
    }
}
