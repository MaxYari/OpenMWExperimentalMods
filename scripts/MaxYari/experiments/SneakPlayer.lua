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
        standStillTerm = 1.0
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

    local mult = util.remap(facing, -1, 0, 0.5, 0.75)
    -- This is modified from vanilla, in vanilla its hardcoded to be 1.5 past 90 deg and 0.5 behind
    -- 0.75 on a side
    -- 0.5 behind
    -- gutils.print("direction mult: " .. mult .. " (facing factor: " .. facing .. ")")
    return mult
end

local function LOS(player, actor)
    if facingFactor(actor) < 0.25 then
        return false -- early escape from LOS checks for facing-away actors
    end

    -- cast once from center of box to center of box
    local playerCenter = player:getBoundingBox().center
    local actorCenter = actor:getBoundingBox().center

    local castResult = nearby.castRay(actorCenter, playerCenter, {
        collisionType = nearby.COLLISION_TYPE.AnyPhysical,
        ignore = actor
    })
    --gutils.print("raycast(center, "..tostring(actorCenter)..") from " .. actor.recordId .. " hit" ..
    --                        aux_util.deepToString(castResult.hitObject, 4))

    if (castResult.hitObject ~= nil) and (castResult.hitObject.id == player.id) then
        return true
    end

    -- and one more check from top of one box to near-center of other.
    -- this exists so merchants can spot you behind counters.
    local actorHead = actor:getBoundingBox().center + util.vector3(0, 0, actor:getBoundingBox().halfSize.z)
    local playerChest = player:getBoundingBox().center + util.vector3(0, 0, (player:getBoundingBox().halfSize.z) / 2)

    castResult = nearby.castRay(actorHead, playerChest, {
        collisionType = nearby.COLLISION_TYPE.AnyPhysical,
        ignore = actor
    })
    --gutils.print("raycast(head, "..tostring(actorHead)..") from " .. actor.recordId .. " hit" ..
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

    local hasLOS = LOS(self, ast.actor)
    local losTerm = 0
    if hasLOS then
        losTerm = 100
    end
    if chameleon > 0 then
        losTerm = losTerm * (1 - chameleon / 100)
    end
    if isInvisible then
        losTerm = 0
    end

    local awarenessScore = (sneakTerm + agilityTerm + luckTerm - blind) * fatigueTerm * directionMult(ast.actor) + losTerm
    -- gutils.print("awareness: " .. awarenessScore .. " = " .. "(" .. sneakTerm .. "+" .. agilityTerm .. "+" ..
    --                      luckTerm .. "-" .. blind .. ") * " .. fatigueTerm .. " * " .. directionMult)  
    
    return awarenessScore
end


-- sneakCheck should return true if the actor can't see the player.
local function sneakCheck(ast)
    -- if we aren't sneaking, then you don't pass the check.
    if isSneaking ~= true then
        return false, 0
    end

    local elusivenessScore = elusiveness(ast.distance)
    local awarenessScore = awareness(ast)
    local sneakChance = math.min(100, math.max(0, elusivenessScore - awarenessScore))    
    local success = math.random(0, 100) <= sneakChance
    -- gutils.print("elusivenessScore: " .. elusivenessScore .. ", awarenessScore: " .. awarenessScore .. ", sneakChance: " .. sneakChance .. ", success: " .. tostring(success))
    

    -- gutils.print("sneak chance: " .. sneakChance .. ", roll: " .. roll)

    return success, sneakChance
end

local function getDetectionVelocities(sneakChance)
    -- returns a velocity multiplier based on sneak chance
    -- sneakChance is 0-100
    -- at 0 sneakChance, velocity is 2.0 (detected quickly)
    -- at 100 sneakChance, velocity is 0.1 (detection slows to a crawl) 
    local maxDetectDur = 20.0  
    local minDetectDur = 0.5    
    if not sneakChance then
        sneakChance = 0
    end

    local gainDur = util.remap(sneakChance, 0, 100, minDetectDur, maxDetectDur)
    local lossDur = util.remap(sneakChance, 0, 100, maxDetectDur, minDetectDur)
    return 1/gainDur, 1/lossDur
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
            distance = 250,
            progress = 0.0
        }
        
        persistantActorStatuses[actor.id] = ast
    end
    return ast
end

local function isFriend(ast)    
    if not ast.followTargets or not ast.combatTargets then return false end
    if gutils.arrayContains(ast.followTargets,self) and not gutils.arrayContains(ast.combatTargets,self) then
        return true
    end
    return false
end



local function detectionCheck(dt)
    if isSneaking then
        for _, actor in ipairs(nearby.actors) do 

            if actor == self.object then goto continue end            
            
            ast = getAst(actor)
            ast.isDead = ast.gactor:isDead()
            
            if ast.isDead then goto continue end

            
            local distance = (self.position - actor.position):length()                
            local noticing = false
            local sneakChance = 100
            
            -- Detection check! ------------
            --------------------------------
            if distance <= detectionRange and not ast.isFriend then                    
                if ast.checker == nil then
                    -- TO DO: This will not work, they will all do it at the same time, since after first execution theyll align
                    ast.checker = gutils.cachedFunction(sneakCheck, sneakCheckPeriod, -math.random() * sneakCheckPeriod - sneakCheckPeriod)
                end
                if ast.followTargetsChecker == nil then
                    ast.followTargetsChecker = gutils.cachedFunction(getFollowTargets, followTargetsCheckPeriod, math.random() * followTargetsCheckPeriod)
                end
                
                isNotDetected, sneakChance = ast.checker(ast)
                noticing = not isNotDetected          
                
                ast.followTargetsChecker(actor)
            end 
            
            ast.noticing = noticing
            ast.sneakChance = sneakChance                
            ast.distance = distance

            if ast.noticing then
                observerActorStatuses[actor.id] = ast
            end
               
            
            ::continue::
        end
    end
    
    
    
    for actorId, ast in pairs(observerActorStatuses) do
        -- Manage detection progress ----
        ---------------------------------
        detectionVel, cooldownVel = getDetectionVelocities(ast.sneakChance)

        if ast.progress == nil then ast.progress = 0.0 end
        if not ast.isDead then
            if ast.noticing then
                ast.progress = math.min(1.0, ast.progress + dt * detectionVel) -- Increase at 0.25 per second            
            else
                -- Decrease detection progress when not detected
                ast.progress = math.max(0.0, ast.progress - dt * cooldownVel) -- Decrease at 0.25 per second
            end
        else
            -- If dead, instantly drop progress to 0
            ast.progress = 0.0
        end

        -- Send spotted event and break sneak only when detection progress reaches 1.0
        if ast.progress >= 1.0 then            
            self.controls.sneak = false  -- Break sneak when fully detected                    
        end

        -- Manage ui markers ------------------
        ---------------------------------------
        local shouldShowMarker = isSneaking and not ast.isDead and (ast.distance <= detectionRange or ast.progress > 0)
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


local function onUpdate(dt)
    if dt == 0 then
        return
    end   

    isMoving = selfActor:getCurrentSpeed() > 0 or not selfActor:isOnGround()
    isSneaking = self.controls.sneak

    local invisibilityEffect = selfActor:activeEffects():getEffect(core.magic.EFFECT_TYPE.Invisibility)
    isInvisible = (invisibilityEffect ~= nil) and (invisibilityEffect.magnitude > 0)

    local chameleonEffect = selfActor:activeEffects():getEffect(core.magic.EFFECT_TYPE.Chameleon)    
    if chameleonEffect ~= nil then
        chameleon = chameleonEffect.magnitude
    end
    
    detectionCheck(dt)

    -- Update all active tweeners for markers
    for actorId, ast in pairs(observerActorStatuses) do
        if ast.marker then ast.marker:updateTweeners(dt) end
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

    if not ast.isDead then
        ast.noticing = true
        ast.progress = 1.0
        observerActorStatuses[e.actor.id] = ast
    end
end

local function onGetFollowTargets(e)
    -- gutils.print("Player: Received follow targets resp from " .. e.actor.recordId)
    if e.actor == self.object then return end

    local ast = getAst(e.actor)    
    ast.followTargets = e.targets
    ast.isFriend = isFriend(ast)
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
        observerActorStatuses[e.target.id] = ast
    end
end

return {    
    engineHandlers = {
        onUpdate = onUpdate
    },
    eventHandlers = { 
        OMWMusicCombatTargetsChanged = onCombatTargetsChanged,
        MaxYariUtil_FollowTargets = onGetFollowTargets,
        SneakExclamation_ReportAttack = onReportAttack
    }
}