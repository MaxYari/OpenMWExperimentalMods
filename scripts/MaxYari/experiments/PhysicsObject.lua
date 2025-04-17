-- OpenMW Lua Physics - Authors: Maksim Eremenko, GPT-4o (Copilot)

local mp = 'scripts/MaxYari/experiments/'

local core = require('openmw.core')
local util = require('openmw.util')

local nstatus, nearby = pcall(require, "openmw.nearby")
local sstatus, omwself = pcall(require, "openmw.self")
local gutils = require(mp..'scripts/gutils')
local EventsManager = require(mp..'scripts/events_manager')


local Gravity = util.vector3(0, 0, -9.8*72)
local SleepSpeed = 7
local SleepTime = 1
local ImpactTorqueMult = 0.5 -- Multiplier for angular velocity impact
local MaxAngularVelocity = 5000 -- Optional: Maximum angular velocity limit

--if omwself.recordId ~= "food_kwama_egg_02" then return end


-- Utilities ------------------------------------------------------
-------------------------------------------------------------------
-- Calculate sphere position along the ray based on sphere cast hit position
local function calcSpherePosAtHit(from, to, hitPos, radius) 
    local c = hitPos
    local r = radius
    local o = from
    local u = (to - from):normalize()
    local v1 = util.vector3(1, 1, 1)
    local dist = 0

    local Det = 0
    local dist1 = 0
    local dist2 = 0

    if (from - hitPos):length() < radius then        
        dist = 0
        goto out
    end
    
    Det = u:dot(o - c)^2 - (o - c):length()^2 + r * r
    
    if Det < 0 and Det > -0.1 then Det = 0
    elseif Det <= -0.1 then 
        dist = 0 
        goto out
    end

    dist1 = - u:dot(o - c) + math.sqrt(Det)
    dist2 = - u:dot(o - c) - math.sqrt(Det)
    
    if dist1 < 0 and dist2 < 0 then        
        dist = 0
        goto out
    end

    if dist1 < 0 then dist = dist2
    elseif dist2 < 0 then dist = dist1
    else dist = math.min(dist1, dist2) end

    ::out::

    local pos = o + u * dist
    
    return pos
end

-- Custom implementation of slerp for rotations (interpolates all axes)
local function slerpRotation(from, to, t)
    local fZ, fY, fX = from:getAnglesZYX()
    local tZ, tY, tX = to:getAnglesZYX()

    --local lpZ = util.remap(t, 0, 1, fZ, tZ)
    local lpY = util.remap(t, 0, 1, fY, tY)
    local lpX = util.remap(t, 0, 1, fX, tX)
    return util.transform.rotateX(lpX) * util.transform.rotateY(lpY) * util.transform.rotateZ(fZ)
end
----------------------------------------------------------------------------
----------------------------------------------------------------------------


-- PhysicsObject class -----------------------------------------------------
----------------------------------------------------------------------------
local PhysicsObject = {}

function PhysicsObject:new(object, properties)
    local inst = {}
    setmetatable(inst, self)
    self.__index = self

    print("Creating a physics object for: ", object)

    inst:init(object, properties)

    return inst
end

function PhysicsObject:init(object, properties)
    local box = object:getBoundingBox()
    
    local radius = 10
    local largestDimension = radius
    if properties.largestDimension then
        largestDimension = properties.largestDimension
    end
    if properties.radius then
        radius = properties.radius        
    elseif object then
        radius = math.min(box.halfSize.x, box.halfSize.y, box.halfSize.z)
        largestDimension = math.max(box.halfSize.x, box.halfSize.y, box.halfSize.z)
        if radius < 2 then radius = 2 end
        if largestDimension < 2 then largestDimension = 2 end
    end

    local volume = 4/3*math.pi*(radius/72)^3 --In meters^3
    local density = 250 -- In kg/m^3
    local mass = volume * density -- In kg
    print(object.recordId,"Volume: ", volume,"Mass:",mass)
    
    
    
    local origin = util.vector3(0, 0, 0)
    if properties.origin then
        origin = properties.origin
    elseif object then
        origin = object.rotation:inverse():apply(box.center-object.position)
    end
    

    local position = nil
    if properties.position then
        position = properties.position
    elseif object then
        position = object.position + object.rotation:apply(origin)
    end
    

    local rotation = util.transform.identity
    if properties.rotation then
        rotation = properties.rotation
    elseif object then
        rotation = object.rotation
    end   
    
    
    self.object = object
    self.position = position
    self.rotation = rotation
    self.origin = origin
    self.velocity = util.vector3(0, 0, 0)
    self.angularVelocity = util.vector3(0, 0, 0) -- Add angular velocity
    self.lockRotation = properties.lockRotation or false
    self.realignWhenRested = properties.realignWhenRested or false
    self.ignoreWorldCollisions = false
    self.ignorePhysObjectCollisions = false
    self.radius = radius
    self.largestDimension = largestDimension
    self.mass = properties.mass or 1
    self.drag = properties.drag or 0.33
    self.angularDrag = properties.angularDrag or 0.1 
    self.bounce = properties.bounce or 0.5    
    self.isSleeping = properties.isSleeping or false
    self.sleepTimer = 0
    self.onCollision = properties.onCollision or EventsManager:new()
    self.onIntersection = properties.onIntersection or EventsManager:new()
end

function PhysicsObject:reInit()
    print("Reinitialising a physics object for: ", self.object)
    self.position = nil
    self.rotation = nil
    self.origin = nil
    self.radius = nil
    self:init(self.object, self)
end


function PhysicsObject:serialize()
    return {
        object = self.object,
        position = self.position,
        velocity = self.velocity,
        radius = self.radius,
        origin = self.origin,
        rotation = self.rotation,
        isSleeping = self.isSleeping,
        bounce = self.bounce,
        mass = self.mass,
        ignorePhysObjectCollisions = self.ignorePhysObjectCollisions
    }
end

function PhysicsObject:setPositionUnadjusted(position)
    self.position = position + self.rotation:apply(self.origin)
end

function PhysicsObject:wakeUp()
    self.isSleeping = false
    self.sleepTimer = 0 -- Reset sleep timer when waking up
end

function PhysicsObject:applyImpulse(impulse) 
    self.velocity = self.velocity + impulse / self.mass
    self:wakeUp() -- Wake up the object when an impulse is applied
end

function PhysicsObject:isCollidingWith(physObject)
    local distance = (self.position - physObject.position):length()
    return distance < (self.radius + physObject.radius)
end

function PhysicsObject:handleCollision(hitResult)
    local normal = hitResult.hitNormal
    local velocity = self.velocity
    local dot = velocity:dot(normal)    
    
    local newInContact = true
    local newInContactWith = hitResult.hitObject
    local isNewContact = newInContact ~= self.inContact or newInContactWith ~= self.inContactWith
    
    self.inContact = newInContact
    self.inContactWith = newInContactWith

    if dot < 0 then
        -- Run collision callback
        
        if isNewContact then self.onCollision:emit(hitResult) end    

        -- Reflect velocity and apply bounce factor
        self.velocity = -(normal * normal:dot(velocity) * 2 - velocity)
        self.velocity = self.velocity * self.bounce

        -- Apply rotational damping
        self.angularVelocity = self.angularVelocity * ImpactTorqueMult

        -- Calculate torque from collision impact
        local impactPoint = hitResult.hitPos
        local collisionNormal = hitResult.hitNormal
        local relativePosition = impactPoint - self.position
        local torque = relativePosition:cross(-self.velocity)
        local tangVelocity = torque/self.mass
        local angularVeloctiy = tangVelocity/self.largestDimension
        -- 6 is a magic number that makes collistion look fun, essentially its (probably) related to moment of inertia which is not accounted for at all
        self.angularVelocity = self.angularVelocity + angularVeloctiy * 6

        -- Clamp angular velocity to prevent it from growing uncontrollably
        --[[ if self.angularVelocity:length() > MaxAngularVelocity then
            self.angularVelocity = self.angularVelocity:normalize() * MaxAngularVelocity
        end ]]
    else
        -- Run intersection callback
        if isNewContact then self.onIntersection:emit(hitResult) end
    end
end

function PhysicsObject:handlePhysObjectCollision(physObject)
    local data1 = self
    local data2 = physObject

    local normal = (data1.position - data2.position):normalize()
    local relativeVelocity = data1.velocity - data2.velocity
    local dot = relativeVelocity:dot(normal)
    
    if dot < 0 and math.abs(dot) > SleepSpeed then
        -- print("Handling object collision", object1, object2, dot)
        -- Calculate impulse magnitude
        local impulseMagnitude = -(1 + math.min(data1.bounce, data2.bounce)) * dot / (1 / data1.mass + 1 / data2.mass)

        -- Apply impulses to both objects
        local impulse = normal * impulseMagnitude
        data1.velocity = data1.velocity + impulse / data1.mass
        data2.velocity = data2.velocity - impulse / data2.mass

        data1:wakeUp()
        --data2:wakeUp()
    end
end

local frameDt = 0
function PhysicsObject:update(dt)
    frameDt = dt

    if not self.isSleeping then
        --print("Internal Updating physics object: ", self.object)

        -- Apply Gravity
        self.velocity = self.velocity + Gravity * dt

        -- Apply drag
        self.velocity = self.velocity * (1 - self.drag * dt)

        -- Calculate displacement
        local displacement = self.velocity * dt
        
        -- Perform sphere raycast for collision detection with environment
        local rayStart = self.position
        local rayEnd = rayStart + displacement
        
        -- Check for collisions with the environment (sphere)
        local collided = false

        if not self.ignoreWorldCollisions then
            local sphereHitResult = nearby.castRay(rayStart, rayEnd, { radius = self.radius })
            if sphereHitResult.hit then
                self:handleCollision(sphereHitResult)
                self.position = calcSpherePosAtHit(rayStart, rayEnd, sphereHitResult.hitPos, self.radius)
                collided = true
            end
        end

        if not collided then
            self.inContact = false
            self.inContactWith = nil
            self.position = rayEnd
        end

        if not self.lastPosition then self.lastPosition = self.position end
        self.actualVelocity = (self.position - self.lastPosition) / dt

        -- Apply angular drag to angular velocity
        self.angularVelocity = self.angularVelocity * (1 - self.angularDrag * dt)
        if self.lockRotation then self.angularVelocity = self.angularVelocity * 0 end -- Lock rotation if specified
        
        -- Update rotation based on angular velocity
        local angularDisplacement = self.angularVelocity * dt * 0.01
        local rotationDelta = util.transform.rotate(angularDisplacement:length(), angularDisplacement:normalize())
        self.rotation = rotationDelta * self.rotation

        -- Realign when close to rest state
        if self.realignWhenRested then
            -- FIX ME; rest is now based on speed, not anglar speed, so realignment will probably not work as intended
            if not self.rotationInfluence then self.rotationInfluence = 0 end
            local speed = self.actualVelocity:length()
            if speed < SleepSpeed then
                --self.rotationInfluence = 1 - speed / SleepSpeed
                self.rotationInfluence = self.sleepTimer / SleepTime
                if self.rotationInfluence > 0 then
                    self.rotation = slerpRotation(self.rotation, util.transform.identity, self.rotationInfluence)
                end
            else
                self.rotationInfluence = 0
            end
        end
    end

    core.sendGlobalEvent("LuaPhysics_UpdateVisPos", self:serialize())
end

function PhysicsObject:trySleep(dt)
    if self.isSleeping or not self.actualVelocity then return end

    local speed = self.actualVelocity:length()
    if speed < SleepSpeed then        
        self.sleepTimer = self.sleepTimer + dt
        if self.sleepTimer >= SleepTime then
            self.isSleeping = true
        end
    else
        self.sleepTimer = 0 -- Reset sleep timer if velocity or angular velocity exceeds threshold
    end

    self.lastPosition = self.position
end

return PhysicsObject







