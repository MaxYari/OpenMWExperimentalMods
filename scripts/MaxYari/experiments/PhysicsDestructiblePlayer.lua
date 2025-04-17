-- OpenMW Lua Physics - Authors: Maksim Eremenko, GPT-4o (Copilot)

local mp = 'scripts/MaxYari/experiments/'

local types = require('openmw.types')
local omwself = require('openmw.self')
local interfaces = require('openmw.interfaces')
local core = require('openmw.core')
local util = require('openmw.util')
local camera = require('openmw.camera')
local animation = require('openmw.animation')
local I = require('openmw.interfaces')

local gutils = require(mp..'scripts/gutils')
local animManager = require(mp..'scripts/anim_manager')
local PhysicsUtilities = require(mp..'PhysicsUtilities')
local HitImpulse = 600

animManager.addOnKeyHandler(function(groupname, key)
    --print("Animation event", groupname,"Key",key)
    
    if key:match(" hit$") then
        PhysicsUtilities.GetLookAtObject(200, function(obj)
            print(obj)
            if obj then
                local direction = camera.viewportToWorldVector(util.vector2(0.5, 0.5)):normalize()
                core.sendGlobalEvent("FractureMe", {
                    object = obj,
                    baseImpulse = direction * HitImpulse + util.vector3(0, 0, 1) * HitImpulse,
                })
            end
        end)
    end

    --[[ if groupname == "spellcast" and key:match(" start$") then
        print("Canceling spellcast")
        -- Testing spellcast cancel (largely irrelevant to the mod)
        animation.cancel(omwself, groupname)
    end ]]
end)

--[[ I.AnimationController.addPlayBlendedAnimationHandler(function(groupname, options) 
    print("Animation start event", groupname,"Key",options.startkey)
end) ]]

local function onUpdate(dt)
    
end

return {
    engineHandlers = {        
        onUpdate = onUpdate        
    }
}







