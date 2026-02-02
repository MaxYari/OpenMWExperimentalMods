local nearby = require("openmw.nearby")

-- RaycastLoadBalancer class
local RaycastLoadBalancer = {}
RaycastLoadBalancer.__index = RaycastLoadBalancer

-- Constructor
function RaycastLoadBalancer:new(maxRaycastsPerFrame)
    local instance = setmetatable({}, RaycastLoadBalancer)
    
    -- Queue to hold raycast requests in order
    instance.requestQueue = {}
    
    -- Map to quickly find requests by ID (for override functionality)
    instance.requestsById = {}
    
    -- Maximum number of raycasts to process per frame
    instance.maxRaycastsPerFrame = maxRaycastsPerFrame or 1
    
    return instance
end

-- Submit a raycast request with an ID and callback
function RaycastLoadBalancer:submitRequest(id, startPos, endPos, options, callback)
    local request = {
        id = id,
        startPos = startPos,
        endPos = endPos,
        options = options,
        callback = callback
    }
    
    -- Check if a request with this ID already exists
    if self.requestsById[id] then
        -- Override the existing request but keep its position in the queue
        local existingIndex = nil
        for i, queuedRequest in ipairs(self.requestQueue) do
            if queuedRequest.id == id then
                existingIndex = i
                break
            end
        end
        
        if existingIndex then
            -- Update the existing request in the queue
            self.requestQueue[existingIndex] = request
        end
    else
        -- Add new request to the end of the queue
        table.insert(self.requestQueue, request)
    end
    
    -- Update the lookup table
    self.requestsById[id] = request
end

-- Process raycasts (call this every frame)
function RaycastLoadBalancer:onUpdate()
    local processedCount = 0
    
    -- Process up to maxRaycastsPerFrame requests
    while processedCount < self.maxRaycastsPerFrame and #self.requestQueue > 0 do
        -- Take the first request from the queue
        local request = table.remove(self.requestQueue, 1)
        
        -- Perform the raycast
        local result = nearby.castRay(request.startPos, request.endPos, request.options)
        
        -- Call the callback with the result
        request.callback(result)
        
        -- Remove from the lookup table since it's been processed
        self.requestsById[request.id] = nil
        
        processedCount = processedCount + 1
    end
end

return RaycastLoadBalancer