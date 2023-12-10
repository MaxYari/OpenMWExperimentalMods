

local types = require('openmw.types')
local world = require('openmw.world')
local core = require('openmw.core')


local record TimerData
    endTime: number
    object: core.GameObject
end

local type EventData = record
    target: core.GameObject
    damageData: DamageData
end


local bloodTimers: {TimerData} = {}
local bloodDuration = 0.5

return {
    engineHandlers = {
        onUpdate = function(dt: number)
            local now = core.getRealTime()
            local i = 1
            while i <= #bloodTimers do
                local timerData = bloodTimers[i]
                if timerData.endTime < now then
                    timerData.object:remove()
                    table.remove(bloodTimers, i)
                else
                    i = i + 1
                end
            end
        end
    },
    eventHandlers = { 
        GCombat_grazed_hit = function(e: EventData)
            print("Got global hit event")

            local activatorRecord: types.ActivatorRecord = {}
            activatorRecord.model = "meshes\\vfx\\blood.nif"
            activatorRecord.name = "GCombat blood grazed hit VFX"

            local bloodGrazedRecordDraft = types.Activator.createRecordDraft(activatorRecord);
            local newRecord = world.createRecord(bloodGrazedRecordDraft) as types.ActivatorRecord
            local blood = world.createObject(newRecord.id,1)

            blood:teleport(e.target.cell, e.damageData.hitPosition)

            local timerData: TimerData = {}
            timerData.endTime = core.getRealTime() + bloodDuration
            timerData.object = blood
            table.insert(bloodTimers, timerData)
        end
    }
}