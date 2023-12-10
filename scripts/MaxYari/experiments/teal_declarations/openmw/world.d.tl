--[[
  `openmw.world` is an interface to the game world for global scripts.
  Can not be used from local scripts.
  local world = require('openmw.world')
]]

local openmw_core = require("openmw.core")
--[[
  Functions related to MWScript.
]]
global record MWScriptFunctions
  --[[
    Returns global mwscript with given recordId.
    Returns `nil` if the script doesn't exist or is not started.
    Currently there can be only one instance of each mwscript, but in multiplayer it will be possible to have a separate instance per player.
  ]]
  getGlobalScript: function(
    recordId: string,
    player: openmw_core.GameObject
  ): world.MWScript | nil
  
  --[[
    Returns mutable global variables.
    In multiplayer, these may be specific to the provided player.
  ]]
  getGlobalVariables: function(
    player: openmw_core.GameObject
  ): { number }
  
  --[[
    Returns local mwscript on ``object``.
    Returns `nil` if the script doesn't exist or is not started.
  ]]
  getLocalScript: function(
    object: openmw_core.GameObject,
    player: openmw_core.GameObject
  ): world.MWScript | nil
  
end
local record world
  --[[
    List of currently active actors.
  ]]
  activeActors: openmw_core.ObjectList
  
  --[[
    List of all cells
    for i, cell in ipairs(world.cells) do print(cell) end
  ]]
  cells: { openmw_core.Cell }
  
  --[[
    Create a new instance of the given record.
    After creation the object is in the disabled state. Use :teleport to place to the world or :moveInto to put it into a container or an inventory.
    Note that dynamically created creatures, NPCs, and container inventories will not respawn.
     -- put 100 gold on the ground at the position of `actor`
    money = world.createObject('gold_001', 100)
    money:teleport(actor.cell.name, actor.position)
  ]]
  createObject: function(
    recordId: string, --[[Record ID in lowercase]]
    count: number
  ): openmw_core.GameObject
  
  --[[
    Creates a custom record in the world database.
    Eventually meant to support all records, but the current
    set of supported types is limited to:
    
    * @{openmw.types#PotionRecord},
    * @{openmw.types#ArmorRecord},
    * @{openmw.types#BookRecord},
    * @{openmw.types#MiscellaneousRecord},
    * @{openmw.types#ClothingRecord},
    * @{openmw.types#WeaponRecord},
    * @{openmw.types#ActivatorRecord}
  ]]
  createRecord: function(
    record: any
  ): any
  
  --[[
    Loads a named cell
  ]]
  getCellByName: function(
    cellName: string
  ): openmw_core.Cell
  
  --[[
    Loads an exterior cell by grid indices
  ]]
  getExteriorCell: function(
    gridX: number,
    gridY: number,
    cellOrName: any
  ): openmw_core.Cell
  
  --[[
    Game time in seconds.
  ]]
  getGameTime: function(): number
  
  --[[
    The scale of game time relative to simulation time.
  ]]
  getGameTimeScale: function(): number
  
  --[[
    Return an object by RefNum/FormId.
    Note: the function always returns @{openmw.core#GameObject} and doesn't validate that
    the object exists in the game world. If it doesn't exist or not yet loaded to memory),
    then `obj:isValid()` will be `false`.
    local obj = world.getObjectByFormId(core.getFormId('Morrowind.esm', 128964))
  ]]
  getObjectByFormId: function(
    formId: string
  ): openmw_core.GameObject
  
  --[[
    The tags that are currently pausing the game.
  ]]
  getPausedTags: function(): table
  
  --[[
    Simulation time in seconds.
    The number of simulation seconds passed in the game world since starting a new game.
  ]]
  getSimulationTime: function(): number
  
  --[[
    The scale of simulation time relative to real time.
  ]]
  getSimulationTimeScale: function(): number
  
  --[[
    Whether the world is paused (onUpdate doesn't work when the world is paused).
  ]]
  isWorldPaused: function(): boolean
  
  --[[
    Functions related to MWScript (see @{#MWScriptFunctions}).
  ]]
  mwscript: MWScriptFunctions
  
  --[[
    Pause the game starting from the next frame.
  ]]
  pause: function(
    tag: string
  )
  
  --[[
    List of players.
    Currently (since multiplayer is not yet implemented) always has one element.
  ]]
  players: openmw_core.ObjectList
  
  --[[
    Set the ratio of game time speed to simulation time speed.
  ]]
  setGameTimeScale: function(
    ratio: number
  )
  
  --[[
    Set the simulation time scale.
  ]]
  setSimulationTimeScale: function(
    scale: number
  )
  
  --[[
    Remove given tag from the list of pause tags.
    Resume the game starting from the next frame if the list became empty.
  ]]
  unpause: function(
    tag: string
  )
  
  --[[
    for _, script in ipairs(world.mwscript.getLocalScripts(object)) do
      -- print the value of local variable 'something' (0 if there is no such variable)
      print(script.variables.something)
      -- set the variable 'something' (raises an error if there is no such variable)
      script.variables.something = 5
    end
  ]]
  record MWScript
    --[[
      The object the script is attached to.
    ]]
    object: openmw_core.GameObject
    
    --[[
      The player the script refers to.
    ]]
    player: openmw_core.GameObject
    
    --[[
      Id of the script
    ]]
    recordId: string
    
    --[[
      Local variables of the script (mutable)
    ]]
    variables: world.MWScriptVariables
    
  end
  record MWScriptVariables
  end
end
return world