local core = require('openmw.core')
local nearby = require('openmw.nearby')
local util = require('openmw.util')
local self = require('openmw.self')

local stool = nil

local function determineBenchOrientationAndLength(bench)
    local center = bench.position
    local xHits, yHits = 0, 0
    local xLength, yLength = 0, 0
    local zLevel = center.z

    for i = -5, 5 do
        local xFrom = center + util.vector3(i * 10, 0, 100)
        local xTo = center + util.vector3(i * 10, 0, 0)
        local xResult = nearby.castRay(xFrom, xTo, { collisionType = nearby.COLLISION_TYPE.World })
        if xResult.hit and xResult.hitObject == bench then
            xHits = xHits + 1
            xLength = xLength + 10
            zLevel = xResult.hitPos.z
        end

        local yFrom = center + util.vector3(0, i * 10, 100)
        local yTo = center + util.vector3(0, i * 10, 0)
        local yResult = nearby.castRay(yFrom, yTo, { collisionType = nearby.COLLISION_TYPE.World })
        if yResult.hit and yResult.hitObject == bench then
            yHits = yHits + 1
            yLength = yLength + 10
            zLevel = yResult.hitPos.z
        end
    end

    if xHits > yHits then
        print("Bench orientation: x")
        return "x", xLength, zLevel
    else
        print("Bench orientation: y")
        return "y", yLength, zLevel
    end
end

local function getSittingPositions(bench, orientation, length, zLevel)
    local center = bench.position
    local halfLength = length / 2
    local positions = {}

    if orientation == "x" then
        table.insert(positions, util.vector3(center.x - halfLength / 2, center.y, zLevel))
        table.insert(positions, util.vector3(center.x + halfLength / 2, center.y, zLevel))
    else
        table.insert(positions, util.vector3(center.x, center.y - halfLength / 2, zLevel))
        table.insert(positions, util.vector3(center.x, center.y + halfLength / 2, zLevel))
    end

    return positions
end

local function determineFacingDirection(sitPosition, orientation)
    local directions = {}
    if orientation then
        -- For benches, cast rays perpendicular to the bench direction
        if orientation == "x" then
            table.insert(directions, util.vector3(0, -1, 0))
            table.insert(directions, util.vector3(0, 1, 0))
        else
            table.insert(directions, util.vector3(-1, 0, 0))
            table.insert(directions, util.vector3(1, 0, 0))
        end
    else
        -- For stools, cast 12 rays around the sitting point
        local angleStep = math.pi / 6  -- 12 rays, 360 degrees / 12 = 30 degrees per step
        for i = 0, 11 do
            local angle = i * angleStep
            table.insert(directions, util.vector3(math.cos(angle), math.sin(angle), 0))
        end
    end

    local validDirections = {}
    for _, direction in ipairs(directions) do
        local from = sitPosition + util.vector3(0, 0, 70)
        local to = from + direction * 100
        local result = nearby.castRay(from, to, { collisionType = nearby.COLLISION_TYPE.World })
        if not result.hit then
            table.insert(validDirections, direction)
        end
    end

    if #validDirections > 0 then
        return validDirections[math.random(#validDirections)]
    else
        return util.vector3(1, 0, 0)  -- Default facing direction if no valid direction found
    end
end

local function onSitDownPlease(data)
    stool = data.stool
    local from = stool.position + util.vector3(0, 0, 100)
    local to = stool.position
    local result = nearby.castRay(from, to, { collisionType = nearby.COLLISION_TYPE.World })
    local usable = result.hit and result.hitObject == stool

    if usable and stool.recordId == "furn_de_p_bench_03" then
        local orientation, length, zLevel = determineBenchOrientationAndLength(stool)
        local positions = getSittingPositions(stool, orientation, length, zLevel)
        local sitPosition = positions[math.random(#positions)]
        local facingDirection = determineFacingDirection(sitPosition, orientation)
        core.sendGlobalEvent("StoolCheckResult", { npc = self.object, hitPos = sitPosition, facingDirection = facingDirection, usable = usable })
    else
        local facingDirection = determineFacingDirection(result.hitPos, nil)
        core.sendGlobalEvent("StoolCheckResult", { npc = self.object, hitPos = result.hitPos, facingDirection = facingDirection, usable = usable })
    end
end

return {
    eventHandlers = {
        SitDownPlease = onSitDownPlease
    }
}
