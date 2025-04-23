local mp = 'scripts/MaxYari/experiments/'


local world = require('openmw.world')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local vfs = require('openmw.vfs')

local gutils = require(mp..'scripts/gutils')
local PhysicsUtils = require(mp..'scripts/physics_utils')
local D = require(mp..'scripts/physics_defs')

local debrisMap = {}

-- Extract clean name from the model path
local function getCleanName(modelPath)
    local filename = modelPath:match("([^/\\]+)$") -- Extract the filename from the path
    filename = filename:gsub("^x", "") -- Remove leading "x" if it exists
    local cleanName = filename:gsub("%.nif$", "") -- Remove the .nif extension
    return cleanName
end

-- Build debris map at startup
local function buildDebrisMap()
    for filePath in vfs.pathsWithPrefix("meshes/debris") do
        if filePath:find("%.nif$") then
            local fileName = getCleanName(filePath)
            local objectName = fileName:gsub("__.+$", "") -- Remove trailing "__something" for debris chunks
            
            if not debrisMap[objectName] then
                debrisMap[objectName] = {}
            end

            if debrisMap[objectName][filePath] then
                local recordId = debrisMap[objectName][filePath]
                --print("Chunk record exists:", filePath, recordId)
            else 
                --print("Chunk record does not exist, making for:", filePath)
                local tempRecord = types.Miscellaneous.createRecordDraft({
                    name = "Debris",
                    model = filePath,
                    icon = "icons/m/debris.dds",
                })                
                local record = world.createRecord(tempRecord) 
                debrisMap[objectName][filePath] = record.id
            end
        end
    end
    --print("Debris map built")
end


-- Function to split an item stack into smaller stacks
local function splitItemStack(item, nSplits)
    if item.count == 1 then return { item } end
    local nPerStack = math.ceil(item.count / nSplits)
    local stacks = {}
    while item.count > nPerStack do
        local splitStack = item:split(nPerStack) -- Split off a stack of size nPerStack
        table.insert(stacks, splitStack)
    end
    table.insert(stacks, item) -- Add the remaining stack
    return stacks
end

local function handleContainer(eventData)
    
    -- Handle container contents if the object is a container
    local object = eventData.object
    local position = object.position
    local baseImpulse = eventData.baseImpulse    
    
    print("Handling container fracture",object)
    local inventory = types.Container.content(object)
    inventory:resolve()
    local contents = inventory:getAll()
    print(contents)
    for _, item in pairs(contents) do
        -- print("Item in container:", item.recordId)
        local splitItems = splitItemStack(item, 5) -- Split the item stack into 5 smaller stacks
        for _, it in ipairs(splitItems) do
            it:teleport(object.cell, position)
            it:sendEvent(D.e.ApplyImpulse, { impulse = PhysicsUtils.randomizeImpulse(baseImpulse, 0.33) })
        end
    end
    
end

local function handlePotion(e)
    local object = e.object
    if not e.source then return end
    -- Apply potion effect
    if e.source and types.Actor.objectIsInstance(e.source) and types.Potion.objectIsInstance(e.object) then
        types.Actor.activeSpells(e.source):add({
            id = object.recordId,
            effects = {0},
            name = "Struck by potion",
            caster = world.players[1],
            quiet = false
        })
        -- Commit a crime
        I.Crimes.commitCrime(world.players[1], {victim = e.source, type = types.Player.OFFENSE_TYPE.Assault})
    end
end

-- Handle the FractureMe event
local function handleFractureMe(eventData)
    local object = eventData.object
    if not object or not object:isValid() or object.count == 0 then return end

    local position = object.position
    local baseImpulse = eventData.baseImpulse
    local cleanName = getCleanName(object.type.record(object).model) -- Pass `false` for model names
    cleanName = cleanName:gsub("_[%d]+$", "") -- Remove trailing "_number" for model names

    -- Check if debris exists for this object
    if not debrisMap[cleanName] then return end

    -- Spawn debris chunks
    for _, recordId in pairs(debrisMap[cleanName]) do
        local chunkObject = world.createObject(recordId)
        chunkObject:teleport(object.cell, position, { rotation = object.rotation })
        chunkObject:setScale(object.scale)

        -- Apply impulse to the debris chunk
        chunkObject:sendEvent(D.e.SetPhysicsProperties, { ignorePhysObjectCollisions = true, material = I.LuaPhysics.getMaterialFromObject(object) })
        chunkObject:sendEvent(D.e.ApplyImpulse, { impulse = PhysicsUtils.randomizeImpulse(baseImpulse, 0.33) })
    end

    -- Play crash sound
    I.LuaPhysics.playCrashSound({
        object = object,
        params = { volume = 2, pitch =  0.8 + math.random() * 0.2, loop = false }
    })

    -- print("Object type",object.type,object.recordId)
    if types.Container.objectIsInstance(object) then
        handleContainer(eventData)
    elseif types.Potion.objectIsInstance(object) then
        handlePotion(eventData)
    end

    -- Remove the fractured object
    object:remove()
end

local function onSave()
    return {
        debrisMap = debrisMap,
    }
end

local function onLoad(data)
    if not data then return end
    --print("OnLoad, debris map:", data.debrisMap)
    debrisMap = data.debrisMap or {}
    buildDebrisMap()
end

return {
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad
    },
    eventHandlers = {
        [D.e.FractureMe] = handleFractureMe
    }
}
