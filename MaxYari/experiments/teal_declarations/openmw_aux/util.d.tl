--[[
  `openmw_aux.util` defines utility functions that are implemented in Lua rather than in C++.
  Implementation can be found in `resources/vfs/openmw_aux/util.lua`.
  local aux_util = require('openmw_aux.util')
]]

local record util
  --[[
    Works like `tostring` but shows also content of tables.
  ]]
  deepToString: function(
    value: any, --[[The value to convert to string]]
    maxDepth: number
  )
  
  --[[
    Finds the element the minimizes `scoreFn`.
    -- Find the nearest NPC
    local nearestNPC, distToNPC = aux_util.findMinScore(
        nearby.actors,
        function(actor)
            return actor.type == types.NPC and (self.position - actor.position):length()
        end)
  ]]
  findMinScore: function(
    array: table, --[[Any array]]
    scoreFn: function
  ): any, --[[element The element the minimizes `scoreFn`]]
    number, --[[score The output of `scoreFn(element)`]]
    number
  
  --[[
    Computes `scoreFn` for each element of `array` and filters out elements with false and nil results.
    -- Find all NPCs in `nearby.actors`
    local NPCs = aux_util.mapFilter(
        nearby.actors,
        function(actor) return actor.type == types.NPC end)
  ]]
  mapFilter: function(
    array: table, --[[Any array]]
    scoreFn: function
  ): table, --[[Output array]]
    table
  
  --[[
    Filters and sorts `array` by the scores calculated by `scoreFn`.
    The same as `aux_util.mapFilter`, but the result is sorted.
    -- Find all NPCs in `nearby.actors` and sort them by distances
    local NPCs, distances = aux_util.mapFilterSort(
        nearby.actors,
        function(actor)
            return actor.type == types.NPC and (self.position - actor.position):length()
        end)
  ]]
  mapFilterSort: function(
    array: table, --[[Any array]]
    scoreFn: function
  ): table, --[[Output array]]
    table
  
end
return util