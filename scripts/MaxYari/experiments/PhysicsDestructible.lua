-- OpenMW Lua Physics - Authors: Maksim Eremenko, GPT-4o (Copilot)

local mp = 'scripts/MaxYari/experiments/'

local core = require('openmw.core')
local util = require('openmw.util')
local types = require('openmw.types')
local nearby = require('openmw.nearby')
local vfs = require('openmw.vfs')
local omwself = require('openmw.self')
local interfaces = require('openmw.interfaces')

local gutils = require(mp..'scripts/gutils')


local PhysicsObject = require(mp..'PhysicsObject')



if omwself.recordId ~= "p_restore_health_s" then return end
local record = omwself.type.record(omwself)
local model = record.model

-- Extract clean name from the model path
local function getCleanName(modelPath, nukeTrailingNumbers)
    local filename = modelPath:match("([^/\\]+)$") -- Extract the filename from the path
    local cleanName = filename:gsub("%.nif$", "") -- Remove the .nif extension
    if nukeTrailingNumbers then cleanName = cleanName:gsub("_[%d]+$", "") end -- Remove trailing "_{number}" if it exists
    return cleanName
end

local cleanName = getCleanName(model, true)
print("Clean name extracted:", cleanName)

-- List to store all matching debris chunks
local debrisChunks = {}

-- Fetch all debris chunks from vfs that match the clean name
for filePath in vfs.pathsWithPrefix("meshes/m/debris") do
    if filePath:find("%.nif$") and filePath:find(cleanName) then
        local cleanChunkName = getCleanName(filePath, false)
        print("Found matching debris mesh:", cleanChunkName)
        table.insert(debrisChunks, cleanChunkName) -- Append to the list
    end
end

print("Total debris chunks found:", #debrisChunks)


local eventHandlersAttached = false

local function onCollision(hitResult)
    local physObject = interfaces.LuaPhysics.physicsObject
    if not omwself:isActive() then
        physObject.onCollision:removeEventHandler(onCollision)
        physObject.onIntersection:removeEventHandler(onCollision)
        return
    end

    print(omwself.recordId, "Collided! At", hitResult.hitPos)
    if hitResult.hitObject then print("With", hitResult.hitObject.recordId) end

    if physObject.velocity:length() > 400 then
        print("Spawning chunks!")
        core.sendGlobalEvent("SpawnDebris", {
            object = omwself,
            hitObject = hitResult.hitObject,
            debrisChunks = debrisChunks,
            originalRecord = {
                id = record.id,
                icon = record.icon,
            },
            baseImpulse = physObject.velocity*1.5
        })
    end
end

local function onUpdate(dt)
    if interfaces.LuaPhysics and not eventHandlersAttached then
        local physObject = interfaces.LuaPhysics.physicsObject
        physObject.onCollision:addEventHandler(onCollision)
        physObject.onIntersection:addEventHandler(onCollision)
        eventHandlersAttached = true
    end
end

return {
    engineHandlers = {        
        onUpdate = onUpdate        
    }
    
}







