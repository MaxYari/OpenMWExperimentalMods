local input = require('openmw.input')
local omwself = require('openmw.self')
local core = require('openmw.core')
local types = require('openmw.types')
local camera = require('openmw.camera')
local util = require('openmw.util')
local nearby = require('openmw.nearby')
local animation = require('openmw.animation')
local I = require('openmw.interfaces')
local animManager = require("scripts.MaxYari.experiments.scripts.anim_manager")
local gutils = require("scripts.MaxYari.experiments.scripts.gutils")

local attackNum = 0
local shouldOverride = false
local overrideWalk = true
local scheduledAnim = nil

local function ends_with(str, ending)
    return ending == "" or str:sub(- #ending) == ending
end

local function isSupportedAttackType(key, suffix)
    if suffix then suffix = " " .. suffix end
    if not suffix then suffix = "" end
    return string.find(key, "chop" .. suffix) or string.find(key, "slash" .. suffix) or string.find(key, "thrust" .. suffix)
end

local runAnimOpts = nil

I.AnimationController.addPlayBlendedAnimationHandler(function(groupname, options)
    print("New animation started! " .. groupname .. " : " .. options.startkey .. " --> " .. options.stopkey)

    if groupname == "runforward1h" then
        -- Learn usual options of a running anim
        if not runAnimOpts then
            runAnimOpts = gutils.shallowTableCopy(options)
        end
    end

    -- if groupname == "idle1h" then
    --     animation.cancel(omwself,"runbounce")
    -- end

    if groupname == "weapononehand" or groupname == "weapononehand1" then
        overrideWalk = true
    end

    if groupname == "weapononehand" and isSupportedAttackType(options.startkey, "start") then
        attackNum = attackNum + 1
        if attackNum % 2 == 1 then
            print("Should override next")
            shouldOverride = true
        else
            shouldOverride = false
        end
    end

    if shouldOverride and groupname == "weapononehand" and isSupportedAttackType(options.startkey) then
        --print("canceling")

        --Canceling doesnt work here, prob its not even playing yet
        print("Overriding")

        I.AnimationController.playBlendedAnimation(groupname .. "1", options)

        options.priority = 12
        options.blendmask = 0

        -- scheduledAnim = {
        --     groupname = groupname,
        --     options = options
        -- }
    end
end)


local function onUpdate()
    print("Completion:",animation.getCompletion(omwself, "bowandarrow"))
    

    local shootHoldTime = animation.getTextKeyTime(omwself, "bowandarrow: shoot max attack")
    local currentTime = animation.getCurrentTime(omwself, "bowandarrow")

    if currentTime and math.abs(shootHoldTime-currentTime) < 0.001  then
        if not animManager.isPlaying("bowandarrow1") then
            I.AnimationController.playBlendedAnimation("bowandarrow1", {
                startkey = "tension start",
                stopkey = "tension end",
                loops = 999,
                forceloop = true,
                autodisable = false,
                priority = animation.PRIORITY.Block
            })
        end
    else
        animation.cancel(omwself, "bowandarrow1")
    end

    if scheduledAnim then
        I.AnimationController.playBlendedAnimation(scheduledAnim.groupname .. "1", scheduledAnim.options)
        scheduledAnim = nil
    end

    if animManager.isPlaying("runforward1h") then
        if animManager.isPlaying("weapononehand") and not animManager.isPlaying("runbounce") then
            animation.cancel(omwself, "runforward1h")
            local newOpts = gutils.shallowTableCopy(runAnimOpts)
            newOpts.priority = 1
            newOpts.blendmask = 0
            I.AnimationController.playBlendedAnimation("runforward1h", newOpts)
            I.AnimationController.playBlendedAnimation("runbounce", runAnimOpts)
        end
    else
        animation.cancel(omwself, "runbounce")
    end

    if not animManager.isPlaying("runforward1h") then
        animation.cancel(omwself, "runbounce")
    end

    if not animManager.isPlaying("weapononehand") then
        animation.cancel(omwself, "weapononehand1")
    end
end


return {
    engineHandlers = {
        onUpdate = onUpdate,
    }
}
