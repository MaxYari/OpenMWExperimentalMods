
local omwself = require('openmw.self')

local animation = require('openmw.animation')
local I = require('openmw.interfaces')
local animManager = require("scripts.MaxYari.experiments.scripts.anim_manager")
local gutils = require("scripts.MaxYari.experiments.scripts.gutils")

local attackTypes = { "chop", "slash", "thrust" }
local attackCounters = {}


local function ends_with(str, ending)
    return ending == "" or str:sub(- #ending) == ending
end

local function isAttackType(key, suffix)
    if suffix then suffix = " " .. suffix end
    if not suffix then suffix = "" end
    for _, type in ipairs(attackTypes) do
        if string.find(key, type .. suffix) then
            return type
        end
    end
    return false
end

local function isAttackTypeStart(key)
    return isAttackType(key, "start")
end



local animations = {
    {
        parent = nil,
        groupname = "bowandarrow1",
        condition = function(self)
            local shootHoldTime = animation.getTextKeyTime(omwself, "bowandarrow: shoot max attack")
            local currentTime = animation.getCurrentTime(omwself, "bowandarrow")

            return currentTime and math.abs(shootHoldTime - currentTime) < 0.001
        end,
        stopCondition = function(self)
            return not self:condition()
        end,
        options = function(self)
            return {
                startkey = "tension start",
                stopkey = "tension end",
                loops = 999,
                forceloop = true,
                autodisable = false,
                priority = animation.PRIORITY.Weapon + 1,
                blendmask = animation.BLEND_MASK.UpperBody,
                startKey = "tension start",
                stopKey = "tension end",
                forceLoop = true,
                autoDisable = false,
                blendMask = animation.BLEND_MASK.UpperBody
            }
        end,
        startOnUpdate = true
    },
    {
        parent = "idle1h",
        groupname = "idle1hsneak",
        condition = function(self)
            return omwself.controls.sneak
        end,
        stopCondition = function(self)
            return not self:condition()
        end,
        options = function(self)
            local opts = gutils.shallowTableCopy(self.parentOptions)
            opts.loops = 999
            opts.priority = self.parentOptions.priority + 1

            return opts
        end,
        startOnUpdate = true
    },
    {
        parent = "idle1s",
        groupname = "idle1ssneak",
        condition = function(self)
            return omwself.controls.sneak
        end,
        stopCondition = function(self)
            return not self:condition()
        end,
        options = function(self)
            local opts = gutils.shallowTableCopy(self.parentOptions)
            opts.loops = 999
            opts.priority = self.parentOptions.priority + 1
            return opts
        end,
        startOnUpdate = true
    },
    {
        parent = "idlebow",
        groupname = "idlebowsneak",
        condition = function(self)
            return omwself.controls.sneak
        end,
        stopCondition = function(self)
            return not self:condition()
        end,
        options = function(self)
            local opts = gutils.shallowTableCopy(self.parentOptions)
            opts.loops = 999
            opts.priority = self.parentOptions.priority + 1
            return opts
        end,
        startOnUpdate = true
    },
    {
        parent = "weapononehand",
        groupname = "weapononehand1",
        condition = function(self)
            local startKey = self.parentOptions.startkey or self.parentOptions.startKey
            if not isAttackType(startKey) then return false end
            local counterKey = self.parent .. isAttackType(startKey)
            return attackCounters[counterKey] == 1
        end,
        options = function(self)
            --For some reason being hit interrupts this override
            local opts = gutils.shallowTableCopy(self.parentOptions)
            return opts
        end,
        hideParent = true,
        startOnAnimEvent = true
    }
}



I.AnimationController.addPlayBlendedAnimationHandler(function(groupname, options)
    local startKey = options.startkey or options.startKey
    local stopKey = options.stopkey or options.stopKey
    print("New animation started! " .. groupname .. " : " .. startKey .. " --> " .. stopKey)

    -- Learn parent options of animations
    for _, anim in ipairs(animations) do
        if anim.parent and anim.parent == groupname then
            anim.parentOptions = options
        end
    end

    -- Count attacks
    if isAttackTypeStart(startKey) then
        local key = groupname .. isAttackType(startKey)
        if not attackCounters[key] then attackCounters[key] = -1 end
        attackCounters[key] = (attackCounters[key] + 1) % 2
    end

    -- Starting override anims
    for _, anim in ipairs(animations) do
        if anim.startOnAnimEvent and anim.parent == groupname then
            local shouldStart = anim:condition()
            if shouldStart then
                print("Overriding " .. anim.parent .. " with " .. anim.groupname)
                animation.cancel(omwself, anim.groupname)
                I.AnimationController.playBlendedAnimation(anim.groupname, anim:options())
                if anim.hideParent then
                    -- TO DO: do more granular priority instead, one that will be unique and will not be canceled by the engine
                    options.priority = animation.PRIORITY.Weapon - 1
                    options.blendMask = 0
                    options.blendmask = 0
                end
            end
        end
    end
end)


-- local cameraYaw = omwself.rotation:getYaw()
-- local viewModelYaw = omwself.rotation:getYaw()


local function onUpdate(dt)
    for _, anim in ipairs(animations) do
        local isParentPlaying = nil
        if anim.parent then isParentPlaying = animManager.isPlaying(anim.parent) end

        local isPlaying = animManager.isPlaying(anim.groupname)

        local shouldStop = (anim.stopCondition and anim:stopCondition()) or (anim.parent and not isParentPlaying)

        local shouldStart = anim.startOnUpdate and (not anim.parent or isParentPlaying) and anim:condition()

        if shouldStart and not isPlaying then
            I.AnimationController.playBlendedAnimation(anim.groupname, anim:options())
        elseif isPlaying and shouldStop then
            animation.cancel(omwself, anim.groupname)
        end
    end


    -- if animManager.isPlaying("runforward1h") then
    --     if animManager.isPlaying("weapononehand") and not animManager.isPlaying("runbounce") then
    --         animation.cancel(omwself, "runforward1h")
    --         local newOpts = gutils.shallowTableCopy(runAnimOpts)
    --         newOpts.priority = 1
    --         newOpts.blendmask = 0
    --         I.AnimationController.playBlendedAnimation("runforward1h", newOpts)
    --         I.AnimationController.playBlendedAnimation("runbounce", runAnimOpts)
    --     end
    -- else
    --     animation.cancel(omwself, "runbounce")
    -- end

    -- if not animManager.isPlaying("runforward1h") then
    --     animation.cancel(omwself, "runbounce")
    -- end




    -- View inertia experiments
    --print(omwself.controls.pitchChange,omwself.rotation:getPitch())


    -- cameraYaw = cameraYaw + omwself.controls.yawChange
    -- camera.setYaw(cameraYaw)
    -- omwself.controls.yawChange = 0

    -- local newViewModelYaw = gutils.lerp(viewModelYaw, cameraYaw, 1 - 0.000001 ^ dt)
    -- if cameraYaw - newViewModelYaw > 0.2 then
    --     newViewModelYaw = cameraYaw - 0.2
    -- end
    -- local deltaModelYaw = newViewModelYaw - viewModelYaw
    -- viewModelYaw = newViewModelYaw
    -- omwself.controls.yawChange = deltaModelYaw
end


return {
    engineHandlers = {
        onUpdate = onUpdate,
    }
}
