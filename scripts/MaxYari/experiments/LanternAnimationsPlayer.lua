local nearby = require('openmw.nearby')
local util = require('openmw.util')
local core = require('openmw.core')
local nearby = require('openmw.nearby')

local PLAYER_EVENT_RAYCAST_REQUEST = "LanternRaycastRequest"
local PLAYER_EVENT_RAYCAST_RESULT = "LanternRaycastResult"

local function onRaycastRequest(data)
    -- data.lantern is a GameObject
    local lantern = data.lantern
    local from = lantern.position
    local to = from - util.vector3(0, 0, 0.33 * 69)
    local rayRes = nearby.castRay(from, to, { ignore = lantern, collisionType = nearby.COLLISION_TYPE.World })
    local shouldInit = not (rayRes and rayRes.hit)
    core.sendGlobalEvent(PLAYER_EVENT_RAYCAST_RESULT, { lantern = lantern, shouldInit = true })
end

return {
    eventHandlers = {
        [PLAYER_EVENT_RAYCAST_REQUEST] = onRaycastRequest,
    }
}
