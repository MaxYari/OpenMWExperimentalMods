local I = require('openmw.interfaces')

local module = {
    initialized = false,
}

local function init()
    if I.impactEffects then
        I.impactEffects.registerModelMaterial("misc_com_pillow_01.nif","Fabric")
        module.initialized = true
    end
end
module.init = init

local function getMaterialFromObject(object)
    if not object then return "Unknown" end
    if not I.impactEffects then return "Unknown" end
    
    local mat = I.impactEffects.getMaterialByObject(object)
    if mat == nil or mat == "Unknown" then
        -- Potential additional material fallback here
    end
    return mat
end
module.getMaterialFromObject = getMaterialFromObject

local function spawnMaterialEffect(material, position)
    if not I.impactEffects then return end
    I.impactEffects.spawnEffect({                
        hitPos = position,
        material = material             
    })
end
module.spawnMaterialEffect = spawnMaterialEffect

local function spawnCollilsionEffects(data)
    if not I.impactEffects then return end

    local om = getMaterialFromObject(data.object)
    local sm = getMaterialFromObject(data.surface)

    local spawnProb = 0.75
    local effectMaterial = sm

    if sm == "Metal" or sm == "Stone" then
        effectMaterial = "Unknown"
    end
    if (sm == "Metal" or sm == "Stone") and (om == "Metal" or om == "Stone") then
        effectMaterial = sm
        spawnProb = 0.25
    end
    if sm == "Wood" or om == "Wood" then
        effectMaterial = "Wood"
    end

    if math.random() > spawnProb then return end

    spawnMaterialEffect(effectMaterial, data.position)
end
module.spawnCollilsionEffects = spawnCollilsionEffects

return module