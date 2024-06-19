local util = require('openmw.util')

local module = {}

local function lookDirection(actor)
    return actor.rotation:apply(util.vector3(0, 1, 0))
end
module.lookDirection = lookDirection

local function flatAngleBetween(a, b)
    return math.atan2(a.x * b.y - a.y * b.x, a.x * b.x + a.y * b.y)
end

local function lookRotation(actor, targetPos)
    local lookDir = lookDirection(actor)
    local desiredLookDir = targetPos - actor.position
    local angle = flatAngleBetween(lookDir, desiredLookDir)
    return angle
end
module.lookRotation = lookRotation

local function calculateMovement(actor, targetPos, speed)
    local lookDir = lookDirection(actor)
    local moveDir = targetPos - actor.position
    local angle = flatAngleBetween(lookDir, moveDir)

    local forwardVec = util.vector2(1, 0)
    local movementVec = forwardVec:rotate(-angle):normalize() * speed;

    return movementVec.x, movementVec.y
end
module.calculateMovement = calculateMovement

local function calcSpeedMult(desiredSpeed, walkSpeed, runSpeed)
    local speedMult = 1
    local shouldRun = true
    if desiredSpeed < walkSpeed then
        shouldRun = false
        speedMult = desiredSpeed / walkSpeed
    elseif desiredSpeed < runSpeed then
        shouldRun = true
        speedMult = desiredSpeed / runSpeed
    end

    return speedMult, shouldRun
end
module.calcSpeedMult = calcSpeedMult

return module
