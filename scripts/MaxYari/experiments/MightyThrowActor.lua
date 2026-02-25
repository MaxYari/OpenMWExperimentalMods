local I = require("openmw.interfaces")
local omwself = require("openmw.self")
local types = require("openmw.types")


function onGetHit(attackInfo)
    print("Get hit!",omwself)
    I.Combat.onHit(attackInfo)
end

return {
    eventHandlers = {
        MightyThrow_GetHit = onGetHit
    }    
}