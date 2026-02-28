--[[
Better Sneak for OpenMW.
Copyright (C) 2026 Maksim Eremenko, Erin Pentecost

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]

local mp = "scripts/MaxYari/experiments/"

local I = require("openmw.interfaces")
local types = require("openmw.types")
local nearby = require("openmw.nearby")
local core = require("openmw.core")
local self = require("openmw.self")
local util = require("openmw.util")
local ui = require('openmw.ui')
local aux_util = require('openmw_aux.util')

local gutils = require(mp .. 'scripts/gutils')
local itemutil = require(mp .. "scripts/item_utils")
local DetectionMarker = require(mp .. "Sneak_ui_elements")
local selfActor = gutils.Actor:new(self)

DebugLevel = 1

gutils.print("Sneak! started")

-- Main config ---------
fSneakUseDist = core.getGMST("fSneakUseDist")
detectionRange = fSneakUseDist -- to do, dont forget to change this
nearDetectionRange = detectionRange*0.66
------------------------

local sneakCheckPeriod = 0.33 -- seconds between sneak checks per actor
local followTargetsCheckPeriod = 2.0 -- seconds between follow target updates per actor
local losCheckPeriod = 0.2
local isSneaking = false
local isMoving = false
local isInvisible = false
local chameleon = 0

-- For the following sneak check methods: based on code by Blurpandra lifterd from Burglary Overhaul --
----------------------------------------------------------------------------------------------
local function elusiveness(distance)
    -- https://en.uesp.net/wiki/Morrowind:Sneak

    local sneakTerm = selfActor:getSkillStat("sneak").modified
    local agilityTerm = selfActor:getAttributeStat("agility").modified / 5
    local luckTerm = selfActor:getAttributeStat("luck").modified / 10    
    local fatigueStat = selfActor:getDynamicStat("fatigue")
    local fatigueTerm = 0.75 + (0.5 * math.min(1, math.max(0, fatigueStat.current / fatigueStat.base)))

    -- Vanilla is more or less local distanceTerm = 0.5 + (distance / detectionRange) -- vanilla detection Range is 500, ours will be at 1000 or more, vanilla dist term is 0.5-1.5
    local distTermFar = 2.0
    local distTermNear = 1.0
    local distTerm = 1
    if distance <= nearDetectionRange then
        distTerm = distTermNear
    else
        distTerm = util.remap(distance, nearDetectionRange, detectionRange, distTermNear, distTermFar)
    end   
    
    
    local invisTerm = 0
    if isInvisible then invisTerm = 100 end
    -- TO DO: Double-check that invis suppose to work this way

    local chameleonTerm = chameleon
    
    local standStillTerm = 1.25 -- not in vanilla, newly added
    if isMoving then
        standStillTerm = 1
    end     

    local elusivenessScore = (sneakTerm + agilityTerm + luckTerm) * distTerm * fatigueTerm * standStillTerm + chameleonTerm + invisTerm
    -- gutils.print("elusiveness: " .. elusivenessScore .. " = " .. "(" .. sneakTerm .. "+" .. agilityTerm .. "+" ..
    --                        luckTerm .. ") * " .. distTerm .. " * " .. fatigueTerm .. " + " .. chameleon)
    return elusivenessScore
end

local function facingFactor(actor)
    -- 1 if actor is facing player, -1 if facing away
    local facing = actor.rotation:apply(util.vector3(0.0, 1.0, 0.0)):normalize()
    local relativePos = (self.position - actor.position):normalize()
    return facing:dot(relativePos)
end

local function directionMult(actor)
    local facing = facingFactor(actor)
    facing = util.clamp(facing, -1, 0)

    local mult = util.remap(facing, -1, 0.25, 0.5, 0.75)
    -- This is modified from vanilla, in vanilla its hardcoded to be 1.5 past 90 deg and 0.5 behind
    -- 0.75 on a side (actually slighly closer to front than pure 90deg, maybe 100-110deg or so)
    -- 0.5 behind
    -- gutils.print("direction mult: " .. mult .. " (facing factor: " .. facing .. ")")
    return mult
end

local function LOS(player, actor)
    -- cast once from center of box to center of box
    local playerBounds = types.Actor.getPathfindingAgentBounds(player) -- Use pathfinding bounds as they should match collider size. If mesh bounding box is used instead - center is sometimes outside the collider.
    local playerHeight = playerBounds.halfExtents.z * 2    
    local playerEyes = player.position + util.vector3(0,0,playerHeight * 0.75)
    local actorEyes = actor:getBoundingBox().center -- Some actors (like creatures) have wonky pathfinding bounds, so better use mesh bounding box here

    local castResult = nearby.castRay(actorEyes, playerEyes, {
        collisionType = nearby.COLLISION_TYPE.AnyPhysical,
        ignore = actor
    })
    --gutils.print("raycast(center, "..tostring(actorCenter)..") from " .. actor.recordId .. " hit" ..
    --                        aux_util.deepToString(castResult.hitObject, 4))

    if (castResult.hitObject ~= nil) and (castResult.hitObject.id == player.id) then
        return true
    end

    return false
end

local function awareness(ast)
    -- https://en.uesp.net/wiki/Morrowind:Sneak    

    local sneakTerm = ast.gactor:getSneakValue()
    local agilityTerm = ast.gactor:getAttributeStat("agility").modified / 5
    local luckTerm = ast.gactor:getAttributeStat("luck").modified / 10

    local fatigueStat = ast.gactor:getDynamicStat("fatigue")
    local fatigueTerm = 0.75 + (0.5 * math.min(1, math.max(0, fatigueStat.current / fatigueStat.base)))

    local blindEffect = ast.gactor:activeEffects():getEffect(core.magic.EFFECT_TYPE.Blind)
    local blind = 0
    if blindEffect ~= nil then
        blind = blindEffect.magnitude
    end

    local isFacing = facingFactor(ast.actor) > 0.25
    local facingTerm = 0
    if isFacing then
        facingTerm = 100
    end
    if chameleon > 0 then
        facingTerm = facingTerm * (1 - chameleon / 100)
    end
    if isInvisible then
        facingTerm = 0
    end
    
    local awarenessScore = (sneakTerm + agilityTerm + luckTerm - blind) * fatigueTerm * directionMult(ast.actor) + facingTerm
    -- gutils.print("awareness: " .. awarenessScore .. " = " .. "(" .. sneakTerm .. "+" .. agilityTerm .. "+" ..
    --                      luckTerm .. "-" .. blind .. ") * " .. fatigueTerm .. " * " .. directionMult)  
    
    return awarenessScore
end


--------------------------------------------------
-- Calm effect check (NPC vs creature aware)
--------------------------------------------------

local function hasCalm(actor)
    local effects = types.Actor.activeEffects(actor)

    if types.NPC.objectIsInstance(actor) then
        local calm = effects:getEffect(core.magic.EFFECT_TYPE.CalmHumanoid)
        return calm and calm.magnitude > 0
    else
        local calm = effects:getEffect(core.magic.EFFECT_TYPE.CalmCreature)
        return calm and calm.magnitude > 0
    end
end

--------------------------------------------------
-- Distance bias (matches engine math)
--------------------------------------------------
local iFightDistanceBase = core.getGMST('iFightDistanceBase')
local fFightDistanceMultiplier = core.getGMST('fFightDistanceMultiplier')
local fFightDispMult = core.getGMST('fFightDispMult')
local function getFightDistanceBias(actor, target)
    local dist = (actor.position - target.position):length()    

    return iFightDistanceBase - fFightDistanceMultiplier * dist
end

--------------------------------------------------
-- Disposition bias (creatures fixed at 50)
--------------------------------------------------

local function getFightDispositionBias(disposition)
    local mult = fFightDispMult
    return (50 - disposition) * mult
end

--------------------------------------------------
-- Aggression decision
--------------------------------------------------

local function isAggressive(ast, target)
    -- TO DO: Doesnt really make sense as some monsters are not agressive
    --------------------------------------------------
    -- NPC override rule
    --------------------------------------------------

    if types.NPC.objectIsInstance(ast.actor) then
        return not hasCalm(ast.actor)
    end

    --------------------------------------------------
    -- Creature logic
    --------------------------------------------------

    -- calm suppresses aggression
    if hasCalm(ast.actor) then
        return false
    end

    local aiFight = ast.gactor:aiFightStat().modified

    -- fight score calculation
    local fight =
        aiFight  -- Access the modified value of the AI stat
        + getFightDistanceBias(ast.actor, target)
        + getFightDispositionBias(50)

    local res = fight >= 100

    --[[ if not res then
        print("Actor", ast.actor.recordId, "is not agressive towards target", target.recordId, "Fight:", aiFight, "Distance Bias:", getFightDistanceBias(ast.actor, target), "Disposition Bias:", getFightDispositionBias(50), "Total: ", fight)
    end ]]
    
    return fight >= 100
end

local function aggroDistance(ast)
    local aiFight = ast.gactor:aiFightStat().modified
    return (iFightDistanceBase + aiFight - 100) / fFightDistanceMultiplier
end

    











-- sneakCheck should return true if the actor can't see the player.
local function sneakCheck(ast)
    -- if we aren't sneaking, then you don't pass the check.
    if isSneaking ~= true then return false, nil end    

    ast.inLOS = LOS(self.object, ast.actor)
    if ast.inLOS == false then return true,nil end 

    local elusivenessScore = elusiveness(ast.distance)
    local awarenessScore = awareness(ast)
    local sneakChance = math.min(100, math.max(0, elusivenessScore - awarenessScore))    
    local success = math.random(0, 100) <= sneakChance
    -- gutils.print("elusivenessScore: " .. elusivenessScore .. ", awarenessScore: " .. awarenessScore .. ", sneakChance: " .. sneakChance .. ", success: " .. tostring(success))
    

    -- gutils.print("sneak chance: " .. sneakChance .. ", roll: " .. roll)
    return success, sneakChance
end

local DECREASE_RATE = 0.25  -- fixed decrease rate per second

local function getDetectionVelocity(sneakChance)
    -- returns a velocity multiplier based on sneak chance
    -- sneakChance is 0-100
    -- at 0 sneakChance, velocity is 2.0 (detected quickly)
    -- at 100 sneakChance, velocity is 0.05 (detection slows to a crawl)
    local maxDetectDur = 8
    local minDetectDur = 0.5
    if not sneakChance then
        sneakChance = 0
    end

    local detectDur = util.remap(sneakChance, 0, 100, minDetectDur, maxDetectDur)
    return 1 / detectDur
end

local function isTalking(actor)
    return core.sound.isSayActive(actor)
end

local function posAboveActor(actor)
    local bbox = actor:getBoundingBox()
    return bbox.center + util.vector3(0, 0, bbox.halfSize.z)
end

local function getFollowTargets(actor)
    actor:sendEvent("MaxYariUtil_GetFollowTargets")
end




local observerActorStatuses = {}
local persistantActorStatuses = {}

local function getAst(actor)
    local ast = persistantActorStatuses[actor.id]
    if not ast then
        -- gutils.print("Creating new persistant actor status for " .. actor.recordId)
        ast = {
            actor = actor,
            gactor = gutils.Actor:new(actor),
            cell = actor.cell,
            distance = 250,
            progress = 0.0,
            successRolls = 0
        }

        persistantActorStatuses[actor.id] = ast
    end
    return ast
end

local function getAstIfExists(actor)
    if not persistantActorStatuses[actor.id] then return nil end
    return getAst(actor)
end

local function isFriend(ast)    
    if not ast.followTargets then return false end
    if gutils.arrayContains(ast.followTargets, self.object) and (not ast.combatTargets or not gutils.arrayContains(ast.combatTargets, self.object)) then
        return true
    end
    return false
end



local function detectionCheck(dt)
    if isSneaking then
        for _, actor in ipairs(nearby.actors) do 

            if actor == self.object then goto continue end   
            
            local ast = nil   
            local isDead = types.Actor.isDead(actor)
            
            if isDead then
                ast = getAstIfExists(actor)
                if ast then
                    ast.noticing = false
                    ast.progress = 0
                    ast.successRolls = 0
                    ast.isDead = isDead
                end
                goto continue
            end
            
            ast = getAst(actor)
            ast.isDead = isDead
            
            local distance = (self.position - actor.position):length()                
            local noticing = false
            local sneakChance = 100
            local isAggro = false

            -- print(ast.actor.recordId, " Aggro range is ", aggroDistance(ast), " while currect detection range is ", detectionRange)
            
            -- Detection check! ------------
            --------------------------------
            if distance <= detectionRange and not ast.isFriend then                
                if ast.checker == nil then                        
                    ast.checker = gutils.cachedFunction(sneakCheck, sneakCheckPeriod, math.random() * sneakCheckPeriod)
                end
                if ast.followTargetsChecker == nil then                    
                    ast.followTargetsChecker = gutils.cachedFunction(getFollowTargets, followTargetsCheckPeriod, math.random() * followTargetsCheckPeriod)
                end

                local newSneakChance = nil
                isNotDetected, newSneakChance = ast.checker(ast)
                
                noticing = not isNotDetected
                if newSneakChance ~= nil then sneakChance = newSneakChance end

                ast.followTargetsChecker(actor)    
                
                -- Check if agressive
                isAggro = isAggressive(ast, self.object)
                -- print(actor.recordId .. " is " .. (isAggro and "aggressive" or "not aggressive") .. " towards player")
            end
            
            ast.noticing = noticing
            ast.sneakChance = sneakChance
            ast.distance = distance
            ast.isAggressive = isAggro

            -- Add to observerActorStatuses if noticing OR if there's existing progress that needs to be tracked
            if ast.noticing or ast.progress > 0 then
                observerActorStatuses[actor.id] = ast
            end               
            
            ::continue::
        end
    end
    
    
    
    for actorId, ast in pairs(observerActorStatuses) do
        -- Manage detection progress ----
        ---------------------------------
        local detectionVel = getDetectionVelocity(ast.sneakChance)

        if ast.progress == nil then ast.progress = 0.0 end
        if ast.successRolls == nil then ast.successRolls = 0 end
        
        if ast.isDead or not ast.actor:isValid() then
            ast.progress = 0.0
            ast.successRolls = 0
        elseif not ast.inLOS then
            -- Out of LOS: immediate fixed decrease, set successRolls to 5
            ast.progress = math.max(0.0, ast.progress - dt * DECREASE_RATE)
            ast.successRolls = 3
        elseif ast.noticing then
            -- Detected: increase with sneak-based velocity, reset counter
            ast.progress = math.min(1.0, ast.progress + dt * detectionVel)
            ast.successRolls = 0
        else
            -- Not detected: count success rolls
            ast.successRolls = ast.successRolls + 1
            if ast.successRolls >= 3 then
                -- After 3 successes, start decreasing at fixed rate
                ast.progress = math.max(0.0, ast.progress - dt * DECREASE_RATE)
            end
            -- else: progress stays same
        end

        -- Send spotted event and break sneak only when detection progress reaches 1.0
        if ast.progress >= 1.0 and ast.isAggressive then            
            self.controls.sneak = false  -- Break sneak when fully detected                    
        end

        -- Manage ui markers ------------------
        ---------------------------------------
        -- Show markers only when sneaking and detection progress is happening
        local shouldShowMarker = isSneaking and not ast.isDead and ast.inLOS        
        if shouldShowMarker then
            -- If marker doesnt exist but should - make it
            if not ast.marker then ast.marker = DetectionMarker:new() end
        elseif ast.marker then
            -- If it shouldnt exist but does - remove it
            local isSuccesful = ast.progress >= 1.0
            ast.marker:disappear(isSuccesful)
        end

        if ast.marker and ast.marker.destroyed then
            ast.marker = nil
        end

        if ast.marker then
            -- Update the marker's progress and position
            ast.marker:setProgress(ast.progress)
            ast.marker:setWorldPos(posAboveActor(ast.actor))
            ast.marker:setAggressive(ast.isAggressive)
        end

        -- Final cleanup, if no marker and no progress - remove the status object --
        ----------------------------------------------------------------------------
        if (ast.marker == nil) and (ast.progress == 0.0) then
            observerActorStatuses[actorId] = nil
        end
    end
end

---------------------------------------------------------
---------------------------------------------------------

local modifiedSkill = nil
local skillMod = 0
local lastCell = nil

local function onUpdate(dt)
    if dt == 0 then
        return
    end   

    -- Fetching locomotion statuses
    isMoving = selfActor:getCurrentSpeed() > 0 or not selfActor:isOnGround()
    isSneaking = self.controls.sneak

    -- Fetching invisibility status
    local activeEffects = selfActor:activeEffects()
    local invisibilityEffect = activeEffects:getEffect(core.magic.EFFECT_TYPE.Invisibility)
    isInvisible = (invisibilityEffect ~= nil) and (invisibilityEffect.magnitude > 0)

    -- Fetching chameleon effeect
    local chameleonEffect = activeEffects:getEffect(core.magic.EFFECT_TYPE.Chameleon)    
    if chameleonEffect ~= nil then
        chameleon = chameleonEffect.magnitude
    end

    -- Fetching cell changes and removing actors from other cells
    local cell = self.cell
    if not lastCell or (lastCell ~= cell and not (lastCell.isExterior and cell.isExterior)) then
        lastCell = cell
        for id, ast in pairs(persistantActorStatuses) do
            if ast.cell ~= cell then 
                if ast.marker then
                    ast.marker:disappear()
                end                
                persistantActorStatuses[id] = nil
                observerActorStatuses[id] = nil
            end
        end
    end
    
    detectionCheck(dt)

    -- Update all active tweeners for markers
    for actorId, ast in pairs(observerActorStatuses) do
        if ast.marker then ast.marker:updateTweeners(dt) end
    end

    -- Increase the weapon skill while sneaking
    local weaponObj = selfActor:getEquipment(types.Actor.EQUIPMENT_SLOT.CarriedRight)
    local skill = "handtohand"
    if weaponObj then   
        skill = itemutil.getSkillTypeForEquipment(weaponObj).id        
    end           
    stat = selfActor:getSkillStat(skill)    
    
    if isSneaking then
        if modifiedSkill ~= skill then
            -- if we switched to a different skill, remove old modifier
            if modifiedSkill then
                local oldStat = selfActor:getSkillStat(modifiedSkill)
                oldStat.modifier = oldStat.modifier - skillMod
            end

            skillMod = stat.base / 2            
            modifiedSkill = skill
            stat.modifier = stat.modifier + skillMod
        end        
    else
        if modifiedSkill then
            -- remove modifier when not sneaking
            stat.modifier = stat.modifier - skillMod
            modifiedSkill = nil
            skillMod = 0
        end
    end
    
    
end


local function onCombatTargetsChanged(e)
    -- gutils.print("Player: Combat targets changed for " .. e.actor.recordId)
    if e.actor == self.object then return end
    -- print("Combat targets changed for " .. e.actor.recordId)

    local ast = getAst(e.actor)    
    ast.combatTargets = e.targets    
    ast.isFriend = isFriend(ast)
    ast.isDead = types.Actor.isDead(e.actor) 

    if not ast.isDead and gutils.arrayContains(ast.combatTargets, self.object) then
        ast.noticing = true
        ast.progress = 1.0
        ast.successRolls = 0
        observerActorStatuses[e.actor.id] = ast
    end
end

local function onGetFollowTargets(e)
    -- gutils.print("Player: Received follow targets resp from " .. e.actor.recordId, 1)
    for _, actor in ipairs(e.targets) do
        gutils.print("Target:",actor.recordId)
    end
    if e.actor == self.object then return end

    local ast = getAst(e.actor)
    ast.followTargets = e.targets
    ast.isFriend = isFriend(ast)
    -- gutils.print(e.actor.recordId, "Is a friend",ast.isFriend, 1)
end

local function onReportAttack(e)
    if e.target == self.object then return end

    -- gutils.print("Reported attack by " .. e.attacker.recordId .. " on " .. e.target.recordId)
    local ast = getAst(e.target)
    ast.isFriend = isFriend(ast)
    ast.isDead = types.Actor.isDead(e.target) 

    if not ast.isDead then
        ast.noticing = true
        ast.progress = 1.0
        ast.successRolls = 0
        observerActorStatuses[e.target.id] = ast
    end
end

local function onSave()
    return {
        modifiedSkill = modifiedSkill,
        skillMod = skillMod
    }
end

local function onLoad(data)
    if data.modifiedSkill then
        modifiedSkill = data.modifiedSkill
        skillMod = data.skillMod
    end
end

return {    
    engineHandlers = {
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad
    },
    eventHandlers = { 
        OMWMusicCombatTargetsChanged = onCombatTargetsChanged,
        MaxYariUtil_FollowTargets = onGetFollowTargets,
        SneakExclamation_ReportAttack = onReportAttack
    }
}