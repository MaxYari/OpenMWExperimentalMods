--[[
  `openmw.self` provides full access to the object the script is attached to.
  Can be used only from local scripts. All fields and function of `GameObject` are also available for `openmw.self`.
  local self = require('openmw.self')
  local types = require('openmw.types')
  if self.type == types.Player then  -- All fields and functions of `GameObject` are available.
      self:sendEvent("something", self.position)
  end
]]

local openmw_core = require("openmw.core")
local openmw_util = require("openmw.util")
--[[
  Allows to view and/or modify controls of an actor.
  All fields are mutable.
]]
global record ActorControls
  --[[
    If true - initiate a jump
  ]]
  jump: boolean
  
  --[[
    +1 - move forward, -1 - move backward
  ]]
  movement: number
  
  --[[
    Look down (radians); if negative - look up
  ]]
  pitchChange: number
  
  --[[
    true - run, false - walk
  ]]
  run: boolean
  
  --[[
    +1 - move right, -1 - move left
  ]]
  sideMovement: number
  
  --[[
    If true - sneak
  ]]
  sneak: boolean
  
  --[[
    if 1 - activates the readied weapon/spell. For weapons, keeping at 1 will charge the attack until set to 0.
  ]]
  use: number
  
  --[[
    Turn right (radians); if negative - turn left
  ]]
  yawChange: number
  
end
global record ActorCollisionParams 
  isAffectedByStorm: boolean
  maxWalkableSlope: number
  stepSizeDown: number
  stepSizeUp: number
end
local record self
  --[[
    Movement controls (only for actors)
  ]]
  controls: ActorControls

  --[[
      Moves actor using actor collision logic, accounting for slopes, steps e.t.c.
    ]]    
  setActorWorldVelocity: function(self: self, velocity: openmw_util.Vector3)

  --[[
      Sets actor collision parameters - walkable slopes e.t.c
    ]] 
  setActorCollisionParams: function(self: self, collisionParams: ActorCollisionParams)
  
  --[[
      Resets actor collision parameters to their default values
    ]] 
  resetActorCollisionParams: function(self: self, collisionParams: ActorCollisionParams)

  --[[
      Overrides actor's flying state
    ]]    
  setActorFlying: function(self: self, flying: boolean)

  --[[
    Enables or disables standard AI (enabled by default).
  ]]
  enableAI: function(
    self: self,
    v: boolean
  )
  
  --[[
    Returns true if the script isActive (the object it is attached to is in an active cell).
    If it is not active, then `openmw.nearby` can not be used.
  ]]
  isActive: function(
    self: self
  ): boolean
  
  --[[
    The object the script is attached to (readonly)
  ]]
  object: openmw_core.GameObject
  
  --[[
    Faction who owns the object or `nil` (mutable).
  ]]
  ownerFactionId: string
  
  --[[
    Rank required to be allowed to pick up the object (mutable).
  ]]
  ownerFactionRank: number
  
  --[[
    NPC who owns the object or `nil` (mutable).
  ]]
  ownerRecordId: string
  
end
return self