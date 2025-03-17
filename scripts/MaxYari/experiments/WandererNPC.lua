local types = require("openmw.types")
local omwself = require("openmw.self")
local AI = require('openmw.interfaces').AI
local util = require('openmw.util')
local core = require('openmw.core')

local wandererId = nil

local function onSave()
    return { wandererId = wandererId }
end

local function onLoad(data)
    if data then
        wandererId = data.wandererId
    end
end

core.sendGlobalEvent("ImAWanderer", {npc = omwself.object, wandererId = wandererId})

local function onUpdate(dt)
   
end

local function onWandererDataUpdate(data)
    wandererId = data.id
    -- Set equipment
    local equipment = {}
    for slot, itemId in pairs(data.eq) do
        equipment[tonumber(slot)] = itemId
    end
    
    types.Actor.setEquipment(omwself, equipment)

    print("Sending ai to travel")
    AI.startPackage({
        type = "Travel",
        destPosition = util.vector3(data.pos.x, data.pos.y, data.pos.z),
        isRepeat = false
    })
end

local function onKeepOnRoaming()
    -- self-remove somehow, or maybe just walk away
    print("I have to Keep on roaming", omwself.object.id)
end

local function onRespondToTopic(ev)
    local responses = {
        ["Greeting"] = "Hello, traveler!",
        ["Job"] = "I am a wanderer, exploring the world.",
        ["Background"] = "I come from a distant land, seeking adventure."
    }
    local response = responses[ev.topic] or "I have nothing to say about that."
    core.sendGlobalEvent("UpdateResponse", { response = response })
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad
    },
    eventHandlers = {
        WandererDataUpdate = onWandererDataUpdate,
        KeepOnRoaming = onKeepOnRoaming,
        RespondToTopic = onRespondToTopic
    }
}