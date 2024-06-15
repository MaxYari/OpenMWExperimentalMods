local omwself = require('openmw.self')
local types = require('openmw.types')
local nearby = require('openmw.nearby')

local gutils = require("utils/gutils")


-- Navigation service handles calculation of a nav path from self to targetPos in an optimised cached manner --
---------------------------------------------------------------------------------------------------------------
local function NavigationService(config)
    if not config then config = {} end

    local NavData = {
        path = nil,
        pathStatus = nil,
        targetPos = nil,
        pathPointIndex = 1,
        nextPathPoint = nil
    }

    function NavData:getPathStatusVerbose()
        if self.pathStatus == nil then return nil end
        return gutils.findField(nearby.FIND_PATH_STATUS, self.pathStatus)
    end

    function NavData:isPathCompleted()
        return self.path and self.pathPointIndex > #self.path
    end

    function NavData:calculatePathLength()
        if not self.path then return 0 end

        local pathLength = 0
        for i = 1, #self.path - 1 do
            -- Calculate the distance between consecutive points
            local segmentLength = (self.path[i + 1] - self.path[i]):length()
            pathLength = pathLength + segmentLength
        end
        return pathLength
    end

    local function findPath()
        NavData.pathStatus, NavData.path = nearby.findPath(omwself.object.position, NavData.targetPos, {
            agentBounds = types.Actor.getPathfindingAgentBounds(omwself),
        })
        NavData.pathPointIndex = 1
        return NavData.pathStatus, NavData.path
    end

    local findPathCached = gutils.cache(findPath, config.cacheDuration)

    function NavData:setTargetPos(pos)
        if not self.targetPos or (self.targetPos - pos):length() > config.targetPosDeadzone then
            self.targetPos = pos
            findPath()
        end
    end

    local function positionReached(pos1, pos2)
        return (pos1 - pos2):length() <= config.pathingDeadzone
    end

    function NavData:run()
        -- Fetching a new path if necessary
        if NavData.targetPos then
            local pathStatus, path, cacheStatus = findPathCached()
        end

        -- Updating path progress
        if NavData.path and NavData.pathPointIndex <= #NavData.path then
            -- Check if the actor reached the current target point
            while NavData.pathPointIndex <= #NavData.path do
                if positionReached(omwself.object.position, NavData.path[NavData.pathPointIndex]) then
                    NavData.pathPointIndex = NavData.pathPointIndex + 1
                else
                    break;
                end
            end
            if NavData.pathPointIndex <= #NavData.path then
                NavData.nextPathPoint = NavData.path[NavData.pathPointIndex]
            else
                NavData.nextPathPoint = nil
                -- Reached path end
            end
        end
    end

    return NavData
end

return NavigationService
