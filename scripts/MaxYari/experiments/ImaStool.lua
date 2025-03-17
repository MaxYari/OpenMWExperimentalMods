local core = require('openmw.core')
local nearby = require('openmw.nearby')
local util = require('openmw.util')
local self = require('openmw.self')

local function onInit()
    local from = self.position + util.vector3(0, 0, 100)
    local to = self.position
    local result = nearby.castRay(from, to, { collisionType = nearby.COLLISION_TYPE.World })
    if result.hit and result.hitObject == self then
        core.sendGlobalEvent("StoolRaycastResult", { hitPos = result.hitPos })
    end
end

return {
    engineHandlers = {
        onInit = onInit
    }
}
