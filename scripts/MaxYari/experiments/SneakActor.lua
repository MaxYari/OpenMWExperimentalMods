local mp = "scripts/MaxYari/experiments/"

local types = require("openmw.types")
local nearby = require("openmw.nearby")
local self = require("openmw.self")
local I = require('openmw.interfaces')


local function onGetFollowTargets(dt)
    for _, player in ipairs(nearby.players) do 
        player:sendEvent("MaxYariUtil_FollowTargets", {actor = self.object, targets = I.AI.getTargets("Follow")})
    end
end


I.Combat.addOnHitHandler(function(a)
    if not a.attacker then return end    
    if types.Player.objectIsInstance(a.attacker) and a.sourceType == I.Combat.ATTACK_SOURCE_TYPES.Melee or a.sourceType == I.Combat.ATTACK_SOURCE_TYPES.Ranged then 
        a.attacker:sendEvent("SneakExclamation_ReportAttack", {attacker = a.attacker, target = self.object})
    end
end)


return {    
    eventHandlers = { MaxYariUtil_GetFollowTargets = onGetFollowTargets }
}