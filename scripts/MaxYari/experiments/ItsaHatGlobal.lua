local world = require('openmw.world')
local types = require('openmw.types')
local util = require('openmw.util')

local lantern = nil

local function onUpdate(dt)
    local p = world.players[1]
    if not lantern then
        print("Spawning garment prop")
        lantern = world.createObject('light_de_lantern_02_blue', 1)
        lantern:teleport(p.cell,p.position)
        lantern:addScript("scripts\\MaxYari\\experiments\\ItsaHat.lua")
        lantern:sendEvent("AttachTo", {actor = p})
    end
    if lantern and lantern.cell ~= p.cell then
        print("Updating garment prop cell")
        lantern:teleport(p.cell,p.position)
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate
    }
}
