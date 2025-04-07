local core = require('openmw.core')
local world = require('openmw.world')
local types = require('openmw.types')
local util = require('openmw.util')
local gutils = require('scripts/MaxYari/experiments/scripts/gutils')

local assignedNpcs = {}
local sittingZOffset = -36
local sittingForwardOffset = -7
local lerpDuration = 1

local function assignNpcsToStools(cell)
    local stools = {}
    for _, obj in ipairs(cell:getAll()) do
        if obj.recordId == "furn_de_p_stool_01" or obj.recordId == "furn_de_p_bench_03" then
            table.insert(stools, obj)        
        end
    end

    local npcs = cell:getAll(types.NPC)
    for i = 1, math.min(#stools, #npcs) do
        local npc = npcs[i]
        npc:sendEvent("ConsiderTheStool", { stool = stools[i] })
    end
end

local function onCellChange()
    local player = world.players[1]
    local cell = player.cell
    assignedNpcs = {}
    assignNpcsToStools(cell)
end

local function onStoolCheckResult(ev)
    if ev.usable then
        assignedNpcs[ev.npc] = { position = ev.hitPos, facingDirection = ev.facingDirection, lerpStartTime = nil }
        print("Sending npc to walk")
        ev.npc:sendEvent('StartAIPackage', {type="Travel", destPosition = ev.hitPos, isRepeat = false})
    end
end

local lastCell = nil

local function onUpdate(dt)
    local player = world.players[1]
    if player.cell ~= lastCell then
        lastCell = player.cell
        onCellChange()
    end
    for npc, data in pairs(assignedNpcs) do
        local distance = (npc.position - data.position):length()
        if distance < 100 then
            if data.npcStandingPos == nil then
                data.npcStandingPos = npc.position
                data.npcStandingRot = npc.rotation
            end
            if data.lerpTime == nil then
                data.lerpTime = 0
            else
                data.lerpTime = data.lerpTime + dt
            end
            local lerpProgress = data.lerpTime / lerpDuration
            
            if lerpProgress >= 1 then
                lerpProgress = 1                
            end
            if lerpProgress >= 0.5 then
                npc:sendEvent('SitDownPlease')
            end
            local forwardOffset = util.vector2(data.facingDirection.x, data.facingDirection.y):normalize() * sittingForwardOffset
            local offset = util.vector3(forwardOffset.x, forwardOffset.y, sittingZOffset)
            local sittingPos = data.position + offset
            local newPosition = gutils.lerp(data.npcStandingPos, sittingPos, lerpProgress)
            
            local targetAngle = math.atan2(data.facingDirection.x, data.facingDirection.y)
            local newAngle = gutils.lerpAngle(data.npcStandingRot:getYaw(), targetAngle, lerpProgress)

            npc:teleport(npc.cell, newPosition, {rotation = util.transform.rotateZ(newAngle)})
        end
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate
    },
    eventHandlers = {
        CellChange = onCellChange,
        StoolCheckResult = onStoolCheckResult
    }
}
