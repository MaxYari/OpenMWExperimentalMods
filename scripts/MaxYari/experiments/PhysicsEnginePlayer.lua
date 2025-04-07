local core = require('openmw.core')
local util = require('openmw.util')
local nearby = require('openmw.nearby')
local ui = require('openmw.ui')
local camera = require('openmw.camera')
local omwself = require('openmw.self')

local physicsObjects = {}
local Gravity = util.vector3(0, 0, -9.8*72)
local SleepSpeed = 1
local SleepTime = 1
local RotationalDamping = 0.5 -- Damping factor for angular velocity
local ImpactTorqueMult = 0.5 -- Multiplier for angular velocity impact
local MaxAngularVelocity = 5000 -- Optional: Maximum angular velocity limit
local RotationOverrideThreshold = 5 -- Ceiling for rotation override influence

local function applyImpulse(object, impulse)
    if not physicsObjects[object.id] then return end
    local data = physicsObjects[object.id]
    data.velocity = data.velocity + impulse / data.mass
    data.isSleeping = false
    data.sleepTimer = 0 -- Reset sleep timer when an impulse is applied
end

local function markAsPhysicsEnabled(object, properties)
    if physicsObjects[object.id] then return end
    print("Marking object as physics enabled: ")
    print(object)
    physicsObjects[object.id] = {
        object = object,
        velocity = util.vector3(0, 0, 0),
        angularVelocity = util.vector3(0, 0, 0), -- Add angular velocity
        radius = properties.radius or 20,
        mass = properties.mass or 1,
        drag = properties.drag or 0.1,
        bounce = properties.bounce or 0.5,
        isSleeping = false
    }
end

local function handleCollision(object, data, hitResult)
    local normal = hitResult.hitNormal
    local velocity = data.velocity
    local dot = velocity:dot(normal)
    if dot < 0 then
        -- Reflect velocity and apply bounce factor
        data.velocity = -(normal * normal:dot(velocity) * 2 - velocity)
        data.velocity = data.velocity * data.bounce

        -- Apply rotational damping
        data.angularVelocity = data.angularVelocity * RotationalDamping

        -- Calculate torque from collision impact
        local impactPoint = hitResult.hitPos
        local collisionNormal = hitResult.hitNormal
        local relativePosition = impactPoint - data.position
        local torque = relativePosition:cross(-data.velocity)
        data.angularVelocity = data.angularVelocity + torque / data.mass * ImpactTorqueMult

        -- Clamp angular velocity to prevent it from growing uncontrollably
        if data.angularVelocity:length() > MaxAngularVelocity then
            data.angularVelocity = data.angularVelocity:normalize() * MaxAngularVelocity
        end

        
    end
end

local function handleObjectCollision(object1, data1, object2, data2)
    print("Handling object collision",object1, object2)
    local normal = (object2.position - object1.position):normalize()
    local relativeVelocity = data1.velocity - data2.velocity
    local dot = relativeVelocity:dot(normal)

    if dot < 0 then
        -- Calculate impulse magnitude
        local impulseMagnitude = -(1 + math.min(data1.bounce, data2.bounce)) * dot / (1 / data1.mass + 1 / data2.mass)

        -- Apply impulses to both objects
        local impulse = normal * impulseMagnitude
        data1.velocity = data1.velocity + impulse / data1.mass
        data2.velocity = data2.velocity - impulse / data2.mass
    end
end

local function updatePhysicsObject(object, data, dt)
    if data.isSleeping then return end

    -- Apply Gravity
    data.velocity = data.velocity + Gravity * dt

    -- Apply drag
    data.velocity = data.velocity * (1 - data.drag * dt)

    -- Calculate displacement
    local displacement = data.velocity * dt

    -- Check for collisions with other physics-enabled objects
    for otherId, otherData in pairs(physicsObjects) do
        local otherObject = otherData.object
        if otherObject.id ~= object.id and otherObject:isValid() then
            local distance = (object.position - otherObject.position):length()
            if distance < (data.radius + otherData.radius) then
                handleObjectCollision(object, data, otherObject, otherData)
            end
        end
    end

    -- Perform raycast for collision detection with environment
    if not data.position then data.position = object.position end
    if not data.lastPosition then data.lastPosition = data.position end
    if not data.rotation then data.rotation = object.rotation end
    local rayStart = data.position
    local rayEnd = rayStart + displacement
    local hitResult = nearby.castRay(rayStart, rayEnd, { radius = data.radius })

    -- Check for collisions with the environment
    if hitResult.hit then
        handleCollision(object, data, hitResult)

        
    else
        data.position = rayEnd
        core.sendGlobalEvent("TeleportRequest", {
            object = object,
            position = data.position,
            rotation = data.rotation,
        })
    end
   

    -- Update rotation based on angular velocity
    local angularDisplacement = data.angularVelocity * dt * 0.01
    local rotationDelta = util.transform.rotate(angularDisplacement:length(), angularDisplacement:normalize())
    data.rotation = rotationDelta * data.rotation

    -- Transition rotation to zero rotation based on speed
    --[[ local speed = data.velocity:length()
    if speed < RotationOverrideThreshold then
        local influence = math.max(0, (RotationOverrideThreshold - speed) / (RotationOverrideThreshold - SleepSpeed))
        data.rotation = util.transform.slerp(data.rotation, util.transform.identity(), influence * dt)
    end ]]

    -- Check if object should go to sleep
    local actualVelocity = (data.position - data.lastPosition) / dt
    if actualVelocity:length() < SleepSpeed and data.angularVelocity:length() < SleepSpeed then
        if not data.sleepTimer then
            data.sleepTimer = 0
        end
        data.sleepTimer = data.sleepTimer + dt
        if data.sleepTimer >= SleepTime then
            data.isSleeping = true
        end
    else
        data.sleepTimer = 0 -- Reset sleep timer if velocity or angular velocity exceeds threshold
    end

    data.lastPosition = data.position
end

local function findPhysicsObjects()
    for _, obj in ipairs(nearby.items) do
        if obj.recordId == "p_restore_health_s" then
            markAsPhysicsEnabled(obj, { radius = 15, mass = 1, drag = 0.1, bounce = 0.75 })
        end
    end
end

local function onUpdate(dt)
    -- Find and setup hardcoded physics objects
    findPhysicsObjects()

    -- Update all physics objects
    for id, data in pairs(physicsObjects) do
        if data.object and data.object:isValid() then
            updatePhysicsObject(data.object, data, dt)
        else
            print("Removing invalid object:", id)
            physicsObjects[id] = nil -- Remove invalid objects
        end
    end
end

local grabDistance = 200;
local maxDragImpulse = 300;
local throwImpulse = 500.0;

local activeObject;
local holdDistance;
local holdOffset;

local function GrabObject()
   local position = camera.getPosition()
   local direction = camera.viewportToWorldVector(util.vector2(0.5, 0.5)):normalize()
   local pickupDistance = grabDistance
   local castResult = nearby.castRenderingRay(position, position + direction * pickupDistance)
   local object = castResult.hitObject

   if not object then return end

   activeObject = object
   holdDistance = (castResult.hitPos - position):length()
   holdOffset = castResult.hitPos - activeObject.position

   ui.showMessage("Pow! " .. activeObject.recordId)

   activeObject:sendEvent('GrabbedBy', { actor = omwself.object });

   applyImpulse(activeObject, direction * throwImpulse)

end

local function DropObject()
   activeObject = nil
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onKeyPress = function(key)
            if key.symbol == 'x' then
               GrabObject()
            end
         end,
         onKeyRelease = function(key)
            if key.symbol == 'x' then
               DropObject()
            end
         end,
    },
    interfaceName = "PhysicsEnginePlayer",
    interface = {
        markAsPhysicsEnabled = markAsPhysicsEnabled,
        applyImpulse = applyImpulse
    },
    
}
