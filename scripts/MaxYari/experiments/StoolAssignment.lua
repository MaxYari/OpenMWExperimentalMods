local core = require('openmw.core')
local world = require('openmw.world')
local types = require('openmw.types')
local util = require('openmw.util')

local assignedNpcs = {}

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
        npc:sendEvent("SitDownPlease", { stool = stools[i] })
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
        assignedNpcs[ev.npc] = { position = ev.hitPos, facingDirection = ev.facingDirection }
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
        -- print("Teleporting npc to stool", npc, data.position)
        local trans = util.transform
        local t = trans.rotateZ(math.sin(data.facingDirection.x))
        npc:teleport(npc.cell, data.position, {rotation=t})
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
