local types = require("openmw.types")
local self = require("openmw.self")
local util = require("openmw.util")
local core = require("openmw.core")
local nearby = require("openmw.nearby")
local anim = require('openmw.animation')

local recordId = "furn_de_shack_basket_01"
local rotation = 0
local shift = 0
local shiftDirection = 1
local effectId = "head_effect"

local function getMesh(recordId)
    local record = types.Miscellaneous.record(recordId)
    if not record then record = types.Weapon.record(recordId) end
    if not record then record = types.Armor.record(recordId) end
    if not record then record = types.Static.record(recordId) end
    return record and record.model or nil
end

local function attachMesh(mesh)
    local options = {
        boneName = "Bip01 Head",
        localOffset = util.transform.move(shift, 0, 0) * util.transform.rotateZ(rotation),
        vfxId = effectId
    }
    anim.addVfx(self, mesh, options)
end

local function onUpdate(dt)
    rotation = rotation + dt * 0.5 -- Rotate around Z axis
    shift = shift + shiftDirection * dt * 50 -- Shift up and down
    if shift > 25 or shift < -25 then
        shiftDirection = -shiftDirection
    end

    local mesh = getMesh(recordId);
    print("Mesh is " .. mesh)
    anim.removeVfx(self, effectId)
    attachMesh(mesh)
end

return {
    engineHandlers = {
        onUpdate = onUpdate
    }
}
