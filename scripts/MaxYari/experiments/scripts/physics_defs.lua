local prefix = "LuaPhysics_"

return {
    GUtoM = 69.99,
    e = {
        UpdateVisPos = prefix.."UpdateVisPos",
        SpawnCollilsionEffects = prefix.."SpawnCollilsionEffects",
        SpawnMaterialEffect = prefix.."SpawnMaterialEffect",
        PlayCollisionSounds = prefix.."PlayCollisionSounds",
        PlayCrashSound = prefix.."PlayCrashSound",
        PlayWaterSplashSound = prefix.."PlayWaterSplashSound",
        WhatIsMyPhysicsData = prefix.."WhatIsMyPhysicsData",
        FractureMe = prefix.."FractureMe",
        HeldBy = prefix.."HeldBy",
        MoveTo = prefix.."MoveTo",
        ApplyImpulse = prefix.."ApplyImpulse",
        SetPhysicsProperties = prefix.."SetPhysicsProperties",
        SetMaterial = prefix.."SetMaterial",
        SetPositionUnadjusted = prefix.."SetPositionUnadjusted",
        CollidingWithPhysObj = prefix.."CollidingWithPhysObj",
        DestructibleHit = prefix.."DestructibleHit",
        ObjectFenagled = prefix .. "ObjectFenagled",
        DetectCulprit = prefix .. "DetectCulprit",
        DetectCulpritResult = prefix .. "DetectCulpritResult"
    }
}