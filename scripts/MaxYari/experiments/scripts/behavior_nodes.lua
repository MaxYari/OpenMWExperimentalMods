-- Mod files
local gutils = require(mp .. "scripts/gutils")
local moveutils = require(mp .. "scripts/movementutils")
local NavigationService = require(mp .. "scripts/navservice")
local voiceManager = require(mp .. "scripts/voice_manager")
local animManager = require(mp .. "scripts/anim_manager")
local enums = require(mp .. "scripts/enums")

-- OpenMW libs
local omwself = require('openmw.self')
local selfActor = gutils.Actor:new(omwself)
local core = require('openmw.core')
local AI = require('openmw.interfaces').AI
local util = require('openmw.util')
local types = require('openmw.types')
local nearby = require('openmw.nearby')
local animation = require('openmw.animation')

_BehaviourTreeImports = {
    loadCodeInScope = util.loadCode,
    clock = core.getRealTime
}
local BT = require('scripts.MaxYari.behaviourtreelua2e.lib.behaviour_tree')

local navService = NavigationService({
    cacheDuration = 1,
    targetPosDeadzone = 50,
    pathingDeadzone = 35
})

-- Custom behaviours ------------------
---------------------------------------

function ChaseTarget(config)
    local props = config.properties


    config.start = function(task, state)
        config.findTargetActor(task, state)
        task.desiredSpeed = -1
        if props.speed then task.desiredSpeed = props.speed() end
    end

    config.run = function(task, state)
        config.findTargetActor(task, state)
        if not task.targetActor or types.Actor.isDead(task.targetActor) then
            return task:fail()
        end

        navService:setTargetPos(task.targetActor.position)
        local movement, sideMovement, run, lookDirection = navService:run({
            desiredSpeed = task.desiredSpeed,
            ignoredObstacleObject = task
                .targetActor
        })
        if navService.doorStuck then
            gutils.print("Chase Target aborted due to the actor being stuck on a door.", 1)
            return task:fail()
        end

        local proximity = 0
        local distance = gutils.getDistanceToBounds(task.targetActor, omwself)
        if props.proximity then proximity = props.proximity() end
        if distance <= proximity or navService:isPathCompleted() then
            return task:success()
        end


        state.movement, state.sideMovement, state.run, state.lookDirection = movement, sideMovement, run, lookDirection
        if config.getLookDirection and config.getLookDirection(task, state) then
            state.lookDirection = config
                .getLookDirection(task, state)
        end

        return task:running()
    end

    return BT.Task:new(config)
end

function MoveInDirection(config)
    -- Directions are relative to the direction from actor to its target, i.e closer to target, further, strafe around to the right and to the left.
    local props = config.properties

    config.name = config.name .. " " .. tostring(props.direction())

    config.start = function(self, state)
        self.lastPos = omwself.position
        self.coveredDistance = 0
        self.startedAt = core.getRealTime()

        self.runSpeed = selfActor:getRunSpeed()
        self.walkSpeed = selfActor:getWalkSpeed()
        self.desiredSpeed = props.speed()
        if self.desiredSpeed == -1 then self.desiredSpeed = self.runSpeed end
        self.desiredDistance = props.distance()
        if props.lookAt then self.lookAt = props.lookAt() end
        self.bounds = selfActor:getPathfindingAgentBounds()
        self.timeLimit = self.desiredDistance / self.desiredSpeed + 1.5

        config.run(self, state)
    end

    config.run = function(self, state)
        if not state.enemyActor then
            return self:fail()
        end

        local now = core.getRealTime()
        local currentPos = omwself.position
        self.coveredDistance = self.coveredDistance + (currentPos - self.lastPos):length()

        -- Vector magic to calculate a run direction
        local dirToEnemy = (state.enemyActor.position - omwself.object.position):normalize()
        local moveDir = moveutils.directionRelativeToVec(dirToEnemy, props.direction())

        local canMove, reason = navService:canMoveInDirection(moveDir)

        local shouldAbort = false

        if not canMove then
            --gutils.print("Move finished due to: " .. reason,2)
            shouldAbort = true
        end

        -- Measure time passed and abort if more than distance/speed + 1.5 have passed
        if now - self.startedAt >= self.timeLimit then
            --gutils.print("Move finished due to time limit of " .. self.timeLimit .. " have been reached.",2)
            shouldAbort = true
        end

        -- Abort if should
        if shouldAbort then
            if self.coveredDistance > self.desiredDistance * 0.33 then
                -- Atleast we moved some distance, consider it a success
                return self:success()
            else
                -- We barely moved, its a fail
                return self:fail()
            end
        end

        -- Done if we covered required distance
        if self.coveredDistance > self.desiredDistance then
            --gutils.print("Move success since distance was covered", 2)
            return self:success()
        end

        -- Calculating speed
        local speedMult, shouldRun = moveutils.calcSpeedMult(self.desiredSpeed, self.walkSpeed, self.runSpeed)
        state.run = shouldRun

        -- And movement values!
        local movement, sideMovement = moveutils.calculateMovement(omwself.object,
            moveDir)
        state.movement, state.sideMovement = movement * speedMult, sideMovement * speedMult
        if self.lookAt == "ahead" then
            state.lookDirection = moveDir
        end


        self.lastPos = currentPos

        if self["running"] then return self:running() end
        -- we are also running this run() method on start() to avoid having gaps between movements on repeated tasks
        -- but on start() we won't have running status reporter available, so just ignore if thats the case
    end

    return BT.Task:new(config)
end

BT.register('MoveInDirection', MoveInDirection)


function JumpInDirection(config)
    local props = config.properties

    config.start = function(self, state)
        self.startedAt = core.getRealTime()
        self.warmupTime = 0.5
        self.justStarted = true
        -- Here we only start moving
        config.run(self, state)
    end

    config.run = function(self, state)
        if not state.enemyActor then
            return self:fail()
        end

        local now = core.getRealTime()

        -- Vector magic to calculate a run direction
        local dirToEnemy = (state.enemyActor.position - omwself.object.position):normalize()
        local moveDir = moveutils.directionRelativeToVec(dirToEnemy, props.direction())

        local canMove, reason = navService:canMoveInDirection(moveDir, types.Actor.getRunSpeed(omwself))

        if not canMove then
            gutils.print("Jump aborted due to: " .. reason)
            return self:fail()
        end

        if now - self.startedAt >= self.warmupTime and selfActor:isOnGround() then
            gutils.print("Jump is finished since actor is on ground")
            return self:success()
        end

        local movement, sideMovement = moveutils.calculateMovement(omwself.object,
            moveDir)
        state.movement, state.sideMovement = movement, sideMovement
        if self.justStarted then
            self.justStarted = false
        else
            -- Trigger jump on the 2nd frame
            state.jump = true
        end

        if self["running"] then return self:running() end
    end

    return BT.Task:new(config)
end

BT.register('JumpInDirection', JumpInDirection)

function StartAttack(config)
    config.start = function(self, state)
        self.frame = 0
        -- Pick the best attack type accounting for the weapon skill and some randomness

        -- If weaponRecord is nil - this will assume its hand-to-hand
        local attacks = state.weaponAttacks
        local goodAttacks = gutils.getGoodAttacks(attacks)
        -- print("Good attacks: ", #goodAttacks)
        -- for index, value in ipairs(goodAttacks) do
        --    print("Good attack: ", value.type, " avgDmg: ", value.averageDamage)
        -- end
        local attack

        local skill = state.weaponSkill
        local prob = util.clamp(util.remap(skill, 0, 75, 0, 100), 0, 90)

        if math.random() * 100 < prob then
            -- if random less than weapon skill (rescale to 0-75 skill, and clamp chance to 0-90)
            attack = gutils.pickWeightedRandomAttackType(goodAttacks)
        else
            -- otherwise pure random
            attack = attacks[math.random(1, #attacks)]
        end

        self.ATTACK_TYPE = omwself.ATTACK_TYPE[attack.type]

        state.attack = self.ATTACK_TYPE
    end

    config.run = function(self, state)
        -- TO DO: Currently stagger is read on a full body, it does create an interesting effect that enemies dont attack during stagger at all, but maybe it should be changed
        -- print(state.attackState, config.successAttackState, enums.ATTACK_STATE.WINDUP_MAX)
        if not state.staggerGroup then
            self.frame = self.frame + 1
            -- print("CURRENT ATTACK FRAME: ", self.frame, " STATE: ", gutils.findField(ATTACK_STATE, state.attackState))
            if self.frame > 3 and state.attackState == enums.ATTACK_STATE.NO_STATE then
                return self:fail()
            end

            if state.attackState >= config.successAttackState then
                return self:success()
            end

            if state.attackState >= enums.ATTACK_STATE.WINDUP_MAX then
                return self:success()
            end
        end

        state.attack = self.ATTACK_TYPE

        return self:running()
    end

    return BT.Task:new(config)
end

function StartSmallAttack(config)
    config.successAttackState = enums.ATTACK_STATE.WINDUP_MIN
    return StartAttack(config)
end

function StartFullAttack(config)
    config.successAttackState = enums.ATTACK_STATE.WINDUP_MAX
    return StartAttack(config)
end

BT.register('StartSmallAttack', StartSmallAttack)
BT.register('StartFullAttack', StartFullAttack)

function HoldAttack(config)
    local hodl = function(self, state)
        if state.attackState ~= enums.ATTACK_STATE.WINDUP_MAX then
            return self:fail()
        else
            state.attack = 1
        end
    end

    config.start = hodl
    config.run = hodl

    return BT.Task:new(config)
end

BT.register('HoldAttack', HoldAttack)

function AttackHoldTimeout(config)
    local p = config.properties
    local duration
    local heldFrom

    config.isStealthy = true

    config.registered = function(self, state)
        duration = p.duration()
        heldFrom = nil
    end

    config.shouldRun = function(self, state)
        local now = core.getRealTime()
        if state.attackState == enums.ATTACK_STATE.WINDUP_MAX then
            if not heldFrom then
                heldFrom = now
            end
        else
            heldFrom = nil
        end

        if heldFrom and now - heldFrom > duration then
            return true
        end

        return false
    end

    return BT.InterruptDecorator:new(config)
end

BT.register("AttackHoldTimeout", AttackHoldTimeout)

function ReleaseAttack(config)
    config.run = function(self, state)
        state.attack = 0
        if state.attackState == enums.ATTACK_STATE.NO_STATE then
            return self:success()
        end
    end

    return BT.Task:new(config)
end

BT.register('ReleaseAttack', ReleaseAttack)

function ChaseEnemy(config)
    config.findTargetActor = function(task, state)
        task.targetActor = state.enemyActor
    end

    config.getLookDirection = function(task, state)
        if state.enemyActor then
            local distanceVec = state.enemyActor.position - omwself.position
            if distanceVec:length() < state.engageRange then
                return distanceVec:normalize()
            end
        end
    end

    return ChaseTarget(config)
end

BT.register('ChaseEnemy', ChaseEnemy)



function FriendsNearby(config)
    local p = config.properties

    config.start = function(task, state)
        local distThreshold = p.distance()
        for _, actor in ipairs(nearby.actors) do
            if (omwself.position - actor.position):length() <= distThreshold and gutils.isMyFriend(actor) and not types.Actor.isDead(actor) then return end
        end
        return task:fail()
    end

    return BT.Decorator:new(config)
end

BT.register("FriendsNearby", FriendsNearby)



function RetreatToFriend(config)
    config.findTargetActor = function(task, state)
        if task.targetActor then return end

        local closestFriend = nil
        local closestFriendDist = nil

        for index, actor in ipairs(nearby.actors) do
            local dist = gutils.getDistanceToBounds(omwself, actor)
            if gutils.isMyFriend(actor) and not types.Actor.isDead(actor) and (not closestFriend or (dist > 350 and dist < closestFriendDist)) then
                closestFriend = actor
                closestFriendDist = dist
            end
        end

        if closestFriend then
            gutils.print("Found a fight-ready NPC, seeking their help! Actor is: " .. closestFriend.recordId)
            task.targetActor = closestFriend
        end
    end

    return ChaseTarget(config)
end

BT.register("RetreatToFriend", RetreatToFriend)

function RetreatBreaker(config)
    -- Mostly written by ChatGPT 2024
    local p = config.properties
    local registeredTime
    local warmupTime
    local dmgProbability
    local onlyMeleeDamage
    local warmupComplete

    local function resetVars()
        registeredTime = core.getRealTime()
        warmupTime = p.warmup()
        dmgProbability = p.dmgProbability()
        onlyMeleeDamage = p.onlyMeleeDamage()
        warmupComplete = false
    end

    config.registered = resetVars

    config.shouldRun = function(task, state)
        if task.started then return true end
        -- Check if warmup period has passed and mark it as complete
        local now = core.getRealTime()
        if (now - registeredTime) >= warmupTime then
            warmupComplete = true
        end

        local baseHealth = selfActor.stats.dynamic:health().base

        -- Check if enough damage was taken
        if warmupComplete and state.damageValue > 0 then
            -- Calculate damage threshold percentage
            local damagePercentage = state.damageValue / baseHealth * 100

            -- Calculate adjusted probability based on damage percentage and dmgProbability range
            local baseProbability = dmgProbability
            local adjustedProbability = util.clamp(baseProbability * (damagePercentage / 10), 0, baseProbability)

            -- Convert dmgProbability from 0-100 range to 0-1 range and clamp it
            adjustedProbability = adjustedProbability / 100

            -- Check if enemy is close enough
            local distance = gutils.getDistanceToBounds(omwself, state.enemyActor)
            local closeEnough = true
            if onlyMeleeDamage then closeEnough = distance <= 300 end

            -- Check if interrupt conditions are met
            return closeEnough and math.random() <= adjustedProbability
        end

        return false
    end
    config.start = function(task, state)
        task.started = true
    end
    config.finish = function(task, state)
        task.started = false
        resetVars()
    end

    return BT.InterruptDecorator:new(config)
end

BT.register("RetreatBreaker", RetreatBreaker)

function PlayerInsolence(config)
    local p = config.properties

    config.shouldRun = function(task, state)
        if task.started then return true end

        if not state.staringProgress then state.staringProgress = 0 end

        local distance = gutils.getDistanceToBounds(omwself, state.enemyActor)

        local raycast = nearby.castRay(gutils.getActorLookRayPos(omwself),
            gutils.getActorLookRayPos(state.enemyActor), { ignore = omwself })
        --print("Raycast: " .. tostring(raycast.hitObject), omwself.position, state.enemyActor.position)
        if raycast.hitObject and raycast.hitObject == state.enemyActor then
            state.staringProgress = state.staringProgress + state.dt
        end

        if distance <= p.proximity() or state.staringProgress >= p.presenceTime() then
            return true
        end

        -- Check if triggered by enemy damage
        if p.triggerOnDamage() and state.damageValue > 0 then
            return true
        end

        return false
    end

    config.start = function(task, state)
        task.started = true
    end

    config.finish = function(task, state)
        task.started = false
    end

    return BT.InterruptDecorator:new(config)
end

BT.register("PlayerInsolence", PlayerInsolence)

function EnemyIsRanged(config)
    -- Mostly written by ChatGPT 2024
    local p = config.properties
    local reactionTime

    config.registered = function(task, state)
        reactionTime = p.reactionTime()
    end

    config.shouldRun = function(task, state)
        if task.started then return true end

        if not state.enemyActor then
            return false
        end

        -- Check if enemy actor is ranged
        local enemyActor = gutils.Actor:new(state.enemyActor)


        if enemyActor:isRanged() then
            task.rangedDetectedTime = task.rangedDetectedTime or core.getRealTime()
        else
            -- Reset ranged detected time if not ranged
            task.rangedDetectedTime = nil
        end

        -- Check if enough reaction time has passed
        if task.rangedDetectedTime then
            local currentTime = core.getRealTime()
            if (currentTime - task.rangedDetectedTime) >= reactionTime then
                return true
            end
        end

        return false
    end

    config.start = function(task, state)
        task.started = true
    end

    config.finish = function(task, state)
        task.started = false
    end

    return BT.InterruptDecorator:new(config)
end

BT.register("EnemyIsRanged", EnemyIsRanged)

function LookAround(config)
    local p = config.properties

    config.start = function(task, state)
        task.lastLookChange = 0
        task.period = p.period()
    end

    config.run = function(task, state)
        local now = core.getRealTime()

        if now - task.lastLookChange > task.period then
            task.lastLookChange = now
            task.period = p.period()
            task.lookDirection = gutils.randomDirection()
        end

        state.lookDirection = task.lookDirection
        task:running()
    end

    return BT.Task:new(config)
end

BT.register("LookAround", LookAround)

function SetCombatState(config)
    local p = config.properties

    config.start = function(task, state)
        local stateString = p.state()
        if not enums.COMBAT_STATE[stateString] then
            error("Wrong combat state provided to combat state set.")
        end
        state.combatState = enums.COMBAT_STATE[stateString]
        return task:success()
    end

    return BT.Task:new(config)
end

BT.register("SetCombatState", SetCombatState)

function SetStateWhenOver(config)
    local p = config.properties
    config.finish = function(task, state)
        for key, val in pairs(p) do
            state[key] = val()
        end
    end

    return BT.Decorator:new(config)
end

BT.register("SetStateWhenOver", SetStateWhenOver)

function OverrideStance(config)
    local p = config.properties

    config.start = function(task, state)
        task.stance = p.stance()
        if not types.Actor.STANCE[task.stance] then
            error("Stance of type " .. tostring(task.stance) .. " doesn't exist.")
        end
    end

    config.run = function(task, state)
        state.stance = types.Actor.STANCE[task.stance]
        return task:running()
    end

    return BT.Task:new(config)
end

BT.register("OverrideStance", OverrideStance)

function OnAnimationKey(config)
    local p = config.properties
    local configId = p.animation()
    local animConfig = assert(animManager.animationConfigs[configId],
        "No animation config " .. tostring(configId) .. " found.")
    local groupname

    local shouldStart = false

    local function onKeyHandler(groupname, key)
        if groupname == animConfig.groupname and key == p.key() then
            shouldStart = true
        end
    end

    config.registered = function(task, state)
        shouldStart = false
        groupname = animConfig.groupname
        if type(groupname) == "table" then
            error("List animation groupnames are not supported in a " ..
                config.name .. " node.")
        end
        animManager.addOnKeyHandler(onKeyHandler)
    end

    config.shouldRun = function(task, state)
        if shouldStart then return true end
    end

    config.finish = function(task, state)
        shouldStart = false
    end

    config.deregistered = function(task, state)
        animManager.removeOnKeyHandler(onKeyHandler)
    end

    return BT.InterruptDecorator:new(config)
end

BT.register("OnAnimationKey", OnAnimationKey)


function PlayAnimation(config)
    local p = config.properties
    local configId = p.animation()
    local animConfig = assert(animManager.animationConfigs[configId],
        "No animation config " .. tostring(configId) .. " found.")
    local groupname

    local lastCompletion = nil

    config.start = function(task, state)
        groupname = animConfig.groupname
        if type(groupname) == "table" then groupname = groupname[math.random(1, #groupname)] end
        task.anim = animManager.Animation:play(groupname, animConfig)
        task.anim:addOnKeyHandler(function(key)
            if key == animConfig.stopkey then task.shouldSucceed = true end
        end)
    end

    config.run = function(task, state)
        if task.shouldSucceed then return task:success() end

        -- Often even arrives too late and in breaks with completion clause
        local completion = animation.getCompletion(omwself, groupname)
        if lastCompletion ~= nil and completion == nil then
            if lastCompletion > 0.9 then
                -- Completion status will be different at different framerates, an edgecase where this be considered
                -- a fail although it properly completed - is quite possible
                return task:success()
            else
                return task:fail()
            end
        end
        lastCompletion = completion

        return task:running()
    end

    config.finish = function(task, state)
        task.anim:cancel()
        task.anim:removeOnKeyHandler()
    end

    return BT.Task:new(config)
end

BT.register("PlayAnimation", PlayAnimation)


function DumpInventory(config)
    config.start = function(task)
        core.sendGlobalEvent("dumpInventory", { actorObject = omwself, position = omwself.position })
        return task:success()
    end

    return BT.Task:new(config)
end

BT.register("DumpInventory", DumpInventory)


function HasDumpableItems(config)
    config.start = function(task)
        if #selfActor:getDumpableInventoryItems() <= 0 then
            return task:fail()
        end
    end

    return BT.Decorator:new(config)
end

BT.register("HasDumpableItems", HasDumpableItems)

function Pacify(config)
    config.start = function(task)
        AI.removePackages("Combat") -- As of right now this makes actors stuck in an Unknown package
        selfActor.stats.ai:fight().base = 30

        task:success()
    end

    return BT.Task:new(config)
end

BT.register("Pacify", Pacify)


function Say(config)
    local p = config.properties

    config.start = function(task, state)
        voiceManager.say(omwself, state.enemyActor, p.recordType(), p.force())
        return task:success()
    end

    return BT.Task:new(config)
end

BT.register("Say", Say)

function SayGroup(config)
    local p = config.properties
    local voices = 0

    config.start = function(task, state)
        local maxVoices = p.maxVoices()

        gutils.forEachNearbyActor(700, function (actor)
            if core.sound.isSayActive(actor) then
                voices = voices + 1
                if voices > maxVoices then
                    return task:fail()
                end
            end
        end)
        
        voiceManager.say(omwself, state.enemyActor, p.recordType(), p.force())
        return task:success()
    end

    return BT.Task:new(config)
end

BT.register("SayGroup", SayGroup)


