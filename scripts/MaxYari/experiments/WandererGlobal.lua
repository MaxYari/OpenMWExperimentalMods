local core = require('openmw.core')
local vfs = require('openmw.vfs')
local markup = require('openmw.markup')
local world = require('openmw.world')
local types = require('openmw.types')
local json = require('scripts/MaxYari/experiments/libs/json')
local storage = require('openmw.storage')
local util = require('openmw.util')
local gutils = require('scripts/MaxYari/experiments/scripts/gutils')

local wanderersFilePath = 'scripts/MaxYari/WandererIPC/Wanderers.yaml'
local fetchTimer = 0
local fetchPeriod = 1
local writeTimer = 10
local writePeriod = 1

local activeWandererNpcs = {}

local function findNpc(wandererId)    
    return activeWandererNpcs[wandererId]
end    

local function createWanderer(wanderer)
    local position = util.vector3(wanderer.pos.x, wanderer.pos.y, wanderer.pos.z)    
    local npc = world.createObject(wanderer.rid)
    npc:teleport(wanderer.cn or "", position)
    npc:addScript("scripts\\MaxYari\\experiments\\WandererNPC.lua")
    
    local inventory = types.Actor.inventory(npc)
    for slot, itemId in pairs(wanderer.eq) do
        local success, item = pcall(world.createObject, itemId)
        if success then
            item:moveInto(inventory)
        else
            print("Error creating item:", itemId)
        end
    end
    
    activeWandererNpcs[wanderer.id] = npc

    return npc
end

local function processNewWanderersData(data)
    local player = world.players[1]
    local precord = types.NPC.record(player)

    -- Create or update wanderers as necessary
    for _, wanderer in ipairs(data) do
        if wanderer.id == precord.name then goto continue end        
        print("Wanderer npcs:", gutils.tableToString(activeWandererNpcs))
        print("Wanderer id", wanderer.id)
        
        local npc = findNpc(wanderer.id)
        if npc then print("FOUND ACTIVE WANDERER!", npc) end

        if not npc then npc = createWanderer(wanderer) end
        
        if npc and npc.enabled then npc:sendEvent("WandererDataUpdate", wanderer) end
        
        ::continue::
    end

    -- Check if any of existing wanderers are not in the dataset anymore and remove them
    for wandererId, npc in pairs(activeWandererNpcs) do
        if not findNpc(wandererId) then
            -- A graceful removal event - wandere will leave the scene and delete
            npc:sendEvent("KeepOnRoaming")
        end
    end

end

local function printOutMyWandererData()
    local player = world.players[1]
    local record = types.NPC.record(player)
    
    local gender = "f"
    if record.isMale then gender = "m" end
    local recordId = record.race .. "_" .. gender .. "_Wanderer"

    print(recordId)

    if player then
        local playerData = {
            id = record.name,
            nm = record.name,
            rid = recordId,
            eq = {},
            pos = {
                x = player.position.x,
                y = player.position.y,
                z = player.position.z
            },
            c = player.cell.id,
            cn = player.cell.name
        }

        local equipment = types.Actor.getEquipment(player)
        for slot, item in pairs(equipment) do
            if item then
                playerData.eq[tostring(slot)] = tostring(item.recordId)
            end
        end

        local yamlContent = json.encode(playerData)
        print("[WnData]" .. yamlContent)
    else
        print("No player found")
    end
end

local lastCell = nil

local function onUpdate(dt)
    local player = world.players[1]
    if player.cell ~= lastCell then
        lastCell = player.cell
        printOutMyWandererData()
    end

    writeTimer = writeTimer + dt
    if writeTimer >= writePeriod then
        printOutMyWandererData()
        writeTimer = 0
    end

    fetchTimer = fetchTimer + dt
    if fetchTimer >= fetchPeriod then
        processNewWanderersData(gutils.readYamlFile(wanderersFilePath))
        fetchTimer = 0
    end
end

local function onImAWanderer(ev)
    if not ev.wandererId then
        print("Id-less wanderer, removing.",ev.npc.recordId)
        ev.npc:remove()
        return
    end
    if (activeWandererNpcs[ev.wandererId]) then
        print("Wanderer"..ev.wandererId.." already exists, replacing previous wanderer with this one.")
        activeWandererNpcs[ev.wandererId]:remove()
    end
    activeWandererNpcs[ev.wandererId] = ev.npc
end

return {
    engineHandlers = {
       onUpdate = onUpdate
    },
    eventHandlers = {
        ImAWanderer = onImAWanderer
    }
}
