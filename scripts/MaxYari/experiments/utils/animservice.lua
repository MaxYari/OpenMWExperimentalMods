local I = require('openmw.interfaces')
local animation = require('openmw.animation')
local gutils = require("utils/gutils")
local omwself = require('openmw.self')


local cbRegistry = {}

local function addOnKeyHandler(cb, anim)
    if not anim then anim = true end
    if cbRegistry[cb] then
        error("There's already an animation callback with id " ..
            tostring(cb) .. " in the registry. This should never happen. A bug?", 2)
    end
    cbRegistry[cb] = anim
end

local function removeOnKeyHandler(cb)
    if not cbRegistry[cb] then
        error("There's no animation callback with id " ..
            tostring(cb) .. " to remove in the registry. This should never happen. A bug?", 2)
    end
    cbRegistry[cb] = nil
end


local Animation = {}


function Animation:play(groupname, opts)
    local anim = {
        groupname = groupname,
        opts = opts
    }

    I.AnimationController.playBlendedAnimation(anim.groupname, anim.opts)

    setmetatable(anim, self)
    self.__index = self

    -- if animRegistry[anim.groupname] then
    --     gutils.print(
    --         "WARNING WARNING: " ..
    --         anim.groupname ..
    --         " animation is already registered as playing. This attempt to play it again will lead to undefined behavior.",
    --         0)
    -- end

    anim.onKeyHandler = function(groupname, key)
        if groupname == anim.groupname and anim.onKey then
            anim:onKey(key)
        end
    end
    addOnKeyHandler(anim.onKeyHandler, anim)

    return anim
end

local function isPlaying(groupname)
    local time = animation.getCurrentTime(omwself, groupname)
    return time and time >= 0
end

function Animation:isPlaying()
    return isPlaying(self.groupname)
end

function Animation:destroy()
    --animRegistry[self.groupname] = nil
    -- this should self-remove from the dictionary
    removeOnKeyHandler(self.onKeyHandler)
end

I.AnimationController.addTextKeyHandler(nil, function(groupname, key)
    for cb, anim in pairs(cbRegistry) do
        cb(groupname, key)
    end
    -- local anim = animRegistry[groupname]
    -- if anim and anim.onKey then
    --     anim:onKey(key)
    -- end
end)

local module = {
    Animation = Animation,
    isPlaying = isPlaying,
    addOnKeyHandler = addOnKeyHandler,
    removeOnKeyHandler = removeOnKeyHandler,
    run = function()
        for cb, anim in pairs(cbRegistry) do
            if type(anim) == "table" and not anim:isPlaying() then
                print("Animation", anim.groupname, "is not playing anymore, destroying.")
                anim:destroy()
            end
        end
    end
}

return module
