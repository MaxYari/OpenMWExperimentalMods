local input = require('openmw.input')
local self = require('openmw.self')
local core = require('openmw.core')
local types = require('openmw.types')
local camera = require('openmw.camera')
local util = require('openmw.util')
local nearby = require('openmw.nearby')
local animation = require('openmw.animation')
local I = require('openmw.interfaces')

I.AnimationController.addPlayBlendedAnimationHandler(function(groupname, options)
    --I.AnimationController.addTextKeyHandler(nil, function(groupname, key)
    --print("Animation text key! " .. groupname .. " : " .. key)
    print("New animation started! " .. groupname .. " : " .. options.startkey .. " --> " .. options.stopkey)
    -- Note: attack animation can be interrupted, so this states most likely should reset after few seconds just in case, to ponder: what if character holds the attack long enough for this to reset?
    -- Probably need to check animation timings to figure for sure if we are in the attack group or not, can get the group during windup and then repeatedly check if its still playing, reset if not
    if string.find(options.startkey, "chop start") then
        -- Cancel vanilla chops, we are taking care of this
        --print("Overriding")
        --options.startkey = string.gsub(options.startkey, "chop", "chop1")
        --options.stopkey = string.gsub(options.stopkey, "chop", "chop1")
        --[[ print("canceling")
       animation.cancel(self, groupname) ]]
        I.AnimationController.playBlendedAnimation(groupname, {
            startkey = string.gsub(options.startkey, "chop", "chop1"),
            stopkey = string.gsub(options.stopkey, "chop", "chop1"),
            priority = animation.PRIORITY.Weapon
        })
    end
end)
