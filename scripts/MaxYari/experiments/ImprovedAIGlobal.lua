local gutils = require("scripts/gutils")
local core = require("openmw.core")

if core.API_REVISION < 63 then return end

return {
    eventHandlers = {
        dumpInventory = function(data)
            -- data.actor, data.position
            local actor = gutils.Actor:new(data.actorObject)
            local items = actor:getDumpableInventoryItems()
            for _, item in pairs(items) do
                item:teleport(data.actorObject.cell, data.position, { onGround = true })
                ::continue::
            end
        end
    },
}
