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
local PhysAiSystem = require(mp..'scripts/physics_ai_system')
local D = require(mp..'scripts/physics_defs')

--if omwself.recordId ~= "p_restore_health_s" then return end

local eventHandlersAttached = false
local heldByActor = nil
local minCollisionDmgSpeed = 300

local maxHp = 10
local hp = 10

local crashMaxDetecDist = 15*D.GUtoM
local function checkHeardByOwnerOrGuards(culprit)
    if PhysAiSystem.canTouch(omwself, culprit) then return false end

    local ownerId = omwself.owner.recordId
    local factionId = omwself.owner.factionId
    local owner, guards, factionMembers = PhysAiSystem.findRelevantNPCsInCell(omwself.cell, nearby.actors, ownerId, factionId)
    local checkDetection = function(npcs)
        for _, npc in ipairs(npcs) do
            if (omwself.position - npc.position):length() < crashMaxDetecDist then return true end
        end
    end
    local detected = checkDetection(owner)
    if not detected then detected = checkDetection(guards) end
    if not detected then detected = checkDetection(factionMembers) end
    return detected
end

local function onHitReceived(e)
    local lockLevel = types.Lockable.getLockLevel(omwself)
    if not e.ignoreLock and lockLevel and lockLevel > 0 then
        return
    end

    hp = hp - e.damage

    if hp <= 0 then
        core.sendGlobalEvent(D.e.FractureMe, {
            object = omwself,
            source = e.source,
            baseImpulse = e.impulse,
            detected = checkHeardByOwnerOrGuards(e.source)
        })
    end
end

local function onCollision(hitResult)
    local physObject = interfaces.LuaPhysics.physicsObject
    
    if hitResult.hitObject and hitResult.hitObject == heldByActor then return end

    if physObject.velocity:length() >= minCollisionDmgSpeed then
        onHitReceived({
            damage = 1,
            impulse = physObject.velocity * 1.2,
            source = hitResult.hitObject
        })
    end
end

local function onMaterialUpdate(mat)
    if mat == "Glass" then
        maxHp = 5
        if hp > maxHp then hp = maxHp end
    end
end



local function onUpdate(dt)
    local physObject = interfaces.LuaPhysics.physicsObject

    if not eventHandlersAttached then
        physObject.onCollision:addEventHandler(onCollision)
        physObject.onIntersection:addEventHandler(onCollision)
        physObject.onMaterialUpdate:addEventHandler(onMaterialUpdate)
        eventHandlersAttached = true
    end
end

return {
    engineHandlers = {        
        onUpdate = onUpdate        
    },
    eventHandlers = {
        [D.e.HeldBy] = function (e)
            heldByActor = e.actor
        end,
        [D.e.DestructibleHit] = function (e)
            onHitReceived(e)
        end
    },
    
}







