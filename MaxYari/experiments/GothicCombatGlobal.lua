local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local table = _tl_compat and _tl_compat.table or table

local types = require('openmw.types')
local world = require('openmw.world')
local core = require('openmw.core')













local bloodTimers = {}
local bloodDuration = 0.5

return {
   engineHandlers = {
      onUpdate = function(dt)
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
      end,
   },
   eventHandlers = {
      GCombat_grazed_hit = function(e)
         print("Got global hit event")

         local activatorRecord = {}
         activatorRecord.model = "meshes\\vfx\\blood.nif"
         activatorRecord.name = "GCombat blood grazed hit VFX"

         local bloodGrazedRecordDraft = types.Activator.createRecordDraft(activatorRecord);
         local newRecord = world.createRecord(bloodGrazedRecordDraft)
         local blood = world.createObject(newRecord.id, 1)

         blood:teleport(e.target.cell, e.damageData.hitPosition)

         local timerData = {}
         timerData.endTime = core.getRealTime() + bloodDuration
         timerData.object = blood
         table.insert(bloodTimers, timerData)
      end,
   },
}
