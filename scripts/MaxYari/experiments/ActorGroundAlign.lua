
local types = require('openmw.types')
local omwself = require('openmw.self')
local nearby = require('openmw.nearby')
local util = require('openmw.util')

local function onPreRender(dt)
    local res = nearby.castRay(omwself.position, omwself.position - util.vector3(0,0,50), {
        collisionType=nearby.COLLISION_TYPE.HeightMap + nearby.COLLISION_TYPE.World
    })

    if res.hit then        
        omwself:visualMoveTo(res.hitPos)
    end
end

return {
    engineHandlers = {
        onPreRender = onPreRender
    }
}
