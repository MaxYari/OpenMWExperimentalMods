--[[
  `openmw.storage` contains functions to work with permanent Lua storage.
  local storage = require('openmw.storage')
  local myModData = storage.globalSection('MyModExample')
  myModData:set("someVariable", 1.0)
  myModData:set("anotherVariable", { exampleStr='abc', exampleBool=true })
  local async = require('openmw.async')
  myModData:subscribe(async:callback(function(section, key)
      if key then
          print('Value is changed:', key, '=', myModData:get(key))
      else
          print('All values are changed')
      end
  end))
]]

local openmw_async = require("openmw.async")
local record storage
  --[[
    Get all global sections as a table; can be used by global scripts only.
    Note that adding/removing items to the returned table doesn't create or remove sections.
  ]]
  allGlobalSections: function(): table
  
  --[[
    Get all global sections as a table; can be used by player scripts only.
    Note that adding/removing items to the returned table doesn't create or remove sections.
  ]]
  allPlayerSections: function(): table
  
  --[[
    Get a section of the global storage; can be used by any script, but only global scripts can change values.
    Creates the section if it doesn't exist.
  ]]
  globalSection: function(
    sectionName: string
  ): storage.StorageSection
  
  --[[
    Get a section of the player storage; can be used by player scripts only.
    Creates the section if it doesn't exist.
  ]]
  playerSection: function(
    sectionName: string
  ): storage.StorageSection
  
  --[[
    A map `key -> value` that represents a storage section.
  ]]
  record StorageSection
    --[[
      Copy all values and return them as a table.
    ]]
    asTable: function(
      self: storage.StorageSection
    ): table
    
    --[[
      Get value by a string key; if value is a table makes it readonly.
    ]]
    get: function(
      self: storage.StorageSection,
      key: string
    ): any
    
    --[[
      Get value by a string key; if value is a table returns a copy.
    ]]
    getCopy: function(
      self: storage.StorageSection,
      key: string
    ): any
    
    --[[
      Make the whole section temporary: will be removed on exit or when load a save.
      Temporary sections have the same interface to get/set values, the only difference is they will not
      be saved to the permanent storage on exit.
      This function can not be used for a global storage section from a local script.
    ]]
    removeOnExit: function(
      self: storage.StorageSection
    )
    
    --[[
      Remove all existing values and assign values from given (the arg is optional) table.
      This function can not be used for a global storage section from a local script.
      Note: `section:reset()` removes the section.
    ]]
    reset: function(
      self: storage.StorageSection,
      values: table
    )
    
    --[[
      Set value by a string key; can not be used for global storage from a local script.
    ]]
    set: function(
      self: storage.StorageSection,
      key: string,
      value: any
    )
    
    --[[
      Subscribe to changes in this section.
      First argument of the callback is the name of the section (so one callback can be used for different sections).
      The second argument is the changed key (or `nil` if `reset` was used and all values were changed at the same time)
    ]]
    subscribe: function(
      self: storage.StorageSection,
      callback: openmw_async.Callback
    )
    
  end
end
return storage