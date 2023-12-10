--[[
  Basic AI interface
  require('openmw.interfaces').AI
]]

local openmw_core = require("openmw.core")
local openmw_util = require("openmw.util")
local record AI
  --[[
    Iterate over all packages starting from the active one and remove those where `filterCallback` returns false.
  ]]
  filterPackages: function(
    filterCallback: function
  )
  
  --[[
    Iterate over all packages and run `callback` for each starting from the active one.
    The same as `filterPackage`, but without removal.
  ]]
  forEachPackage: function(
    callback: function
  )
  
  --[[
    Return the currently active AI package (or `nil` if there are no AI packages).
  ]]
  getActivePackage: function(): AI.Package
  
  --[[
    Return the target of the active package if the package has given type
  ]]
  getActiveTarget: function(
    packageType: string
  ): openmw_core.GameObject
  
  --[[
    Get list of targets of all packages of the given type.
  ]]
  getTargets: function(
    packageType: string
  ): { openmw_core.GameObject }
  
  --[[
    Remove packages of given type (remove all packages if the type is not specified).
  ]]
  removePackages: function(
    packageType: string
  )
  
  --[[
    Start new AI package.
  ]]
  startPackage: function(
    options: table
  )
  
  --[[
    Interface version
  ]]
  version: number
  
  --[[
    AI Package
  ]]
  record Package
    --[[
      Destination point of the AI package.
    ]]
    destPosition: openmw_util.Vector3
    
    --[[
      Whether to help the target in combat (true or false).
    ]]
    sideWithTarget: boolean
    
    --[[
      Target (usually an actor) of the AI package (can be nil).
    ]]
    target: openmw_core.GameObject
    
    --[[
      Type of the AI package.
    ]]
    type: string
    
  end
end
return AI