local gutils = require("utils/gutils")
local types = require('openmw.types')



return {
    eventHandlers = {
        dumpInventory = function(data)
            -- data.actor, data.position
            local actor = gutils.Actor:new(data.actorObject)
            local items = actor:getDumpableInventoryItems()

            for i, item in pairs(items) do
                local isEquipped = actor.hasEquipped(item)

                print("i: " ..
                    i ..
                    " recordId: " ..
                    item.recordId ..
                    " equipped: " .. tostring(isEquipped))

                item:teleport(data.actorObject.cell, data.position, { onGround = true })
                ::continue::
            end
        end
    },
}
