
local types = require('openmw.types')
local omwself = require('openmw.self')

local actor = nil

local function onPreRender(dt)
    if not actor then return end

    local headPos = types.Actor.getBonePosition(actor, "Bip01 Head");

    omwself:visualMoveTo(headPos)
end

return {
    engineHandlers = {
        onPreRender = onPreRender
    },
    eventHandlers = {
        AttachTo = function(e)
            print("Attaching to " .. e.actor.recordId)
            actor = e.actor
        end
    }
}
