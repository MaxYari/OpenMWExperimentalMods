local mp = 'scripts/MaxYari/experiments/'

local core = require('openmw.core')
local util = require('openmw.util')
local types = require('openmw.types')
local nearby = require('openmw.nearby')
local ui = require('openmw.ui')
local camera = require('openmw.camera')
local omwself = require('openmw.self')
local input = require('openmw.input')
local I = require('openmw.interfaces')

local gutils = require(mp..'scripts/gutils')
local PhysicsUtils = require(mp..'scripts/physics_utils')
local animManager = require(mp..'scripts/anim_manager')
local D = require(mp..'scripts/physics_defs')

local selfActor = gutils.Actor:new(omwself)

local frame = 0


local function onUpdate(dt)
    frame = frame + 1

    -- Utilities update loop
    PhysicsUtils.HoldGrabbedObject(dt, input.isShiftPressed())

    if I.impactEffects and I.impactEffects.version < 107 then
        return ui.showMessage("LuaPhysics: OpenMW Impact Effects mod detected, but it's an old version. Please update OpenMW Impact Effects.")
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onKeyPress = function(key)
            --[[ if key.symbol == 'y' then
                PhysicsUtils.ExplodeObjects()
            end ]]
            if key.symbol == 'x' then
                PhysicsUtils.GrabObject()
                types.Actor.setStance(omwself, types.Actor.STANCE.Nothing)
            end
            if key.symbol == 'c' then
                PhysicsUtils.PushObjects()
            end           
         end,
         onKeyRelease = function(key)
            if key.symbol == 'x' then
                PhysicsUtils.DropObject()
            end
         end,
    }   
}
