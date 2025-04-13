local mp = 'scripts/MaxYari/experiments/'

local core = require('openmw.core')
local world = require('openmw.world')
local util = require('openmw.util')
local types = require('openmw.types')
local I = require('openmw.interfaces')

local gutils = require(mp..'scripts/gutils')
local PhysicsObject = require(mp..'PhysicsObject')
local PhysicsUtils = require(mp..'PhysicsUtilities')

local function handleSpawnDebris(e)
    local debrisChunks = e.debrisChunks
    local originalRecord = e.originalRecord
    local object = e.object
    local position = object.position

    
    -- Apply potion effect
    if e.hitObject and types.Actor.objectIsInstance(e.hitObject) and types.Potion.objectIsInstance(e.object) then
        types.Actor.activeSpells(e.hitObject):add({
            id = object.recordId,
            effects = {0},
            name = "Struck by potion",
            caster = world.players[1],
            quiet = false
        })
        -- Commit a crime
        I.Crimes.commitCrime(world.players[1], {victim = e.hitObject, type = types.Player.OFFENSE_TYPE.Assault})
    end
    -- Remove the original object
    object:remove()
    

    for _, chunkName in ipairs(debrisChunks) do
        local recordId = chunkName:lower() -- Use the clean chunk name as the record ID
        local record = types.Miscellaneous.record(recordId)

        -- Create a new record if it doesn't exist
        if not record then
            print("Creating new record for debris chunk:", recordId)
            local tempRecord = types.Miscellaneous.createRecordDraft({
                id = recordId,
                name = chunkName,
                model = "meshes/m/debris/" .. chunkName .. ".nif",
                icon = originalRecord.icon,
            })
            record = world.createRecord(tempRecord)
            print("World record created", record.id)
        end

        -- Spawn the debris chunk in the world
        local chunkObject = world.createObject(record.id)
        chunkObject:teleport(world.players[1].cell, position)
        chunkObject:sendEvent('SetPhysicsProperties', { ignorePhysObjectCollisions = true })
        local impulse = PhysicsUtils.randomizeImpulse(e.baseImpulse,0.5)
        chunkObject:sendEvent('ApplyImpulse', { impulse = impulse })
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate
    },
    eventHandlers = {
        LuaPhysics_UpdateVisPos = handleUpdateVisPos,
        SpawnDebris = handleSpawnDebris, -- Handle the global event
    }
}
