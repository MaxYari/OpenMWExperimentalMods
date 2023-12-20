local self = require('openmw.self')
local core = require('openmw.core')
local types = require('openmw.types')
local util = require('openmw.util')
local nearby = require('openmw.nearby')
local BehaviourTree = require('behaviourtree/behaviour_tree')

local usePeriod: number = 2;
local lastUse: number = 0;
local useState: number = 0;

local function onUpdate(dt: number)
    local now = core.getRealTime()

    if now - lastUse > usePeriod then
        if useState == 1 then
            useState = 0
        else
            useState = 1
        end   
        lastUse = now;     
    end

    self.controls.use = useState
    self.controls.movement = 1
    
    self.controls.sideMovement = -1
end

return {
    engineHandlers = {
        onUpdate = onUpdate
    }
}