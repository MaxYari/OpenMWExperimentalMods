<img width="385" alt="image" src="https://github.com/MaxYari/OpenMWExperimentalMods/assets/12214398/ffc47f1e-c09c-4aae-9f52-a322c07f3e00">
<img width="385" alt="image" src="https://github.com/MaxYari/OpenMWExperimentalMods/assets/12214398/d3296b67-aea1-47d8-a75c-475fb761156d">

# OpenMW Experimental Mods
Experimental mods for OpenMW, quite often made to test the latest OpenMW developmental features.

## How to install
- Place the contents of this repository into your ".../Morrowind/Data Files" folder.
- For *Mercy: CAO* you have to install [this behaviourtreelua2e dependency](https://github.com/MaxYari/behaviourtreelua2e). Unpack the contents of this repository directly into "...Morrowind/Data Files/scripts/behaviourtreelua2e". I.e repository files should be directly inside that `behaviourtreelua2e` folder.
- After that enable the .omwscript file in "Content Files" tab of the launcher. Since this is a collection of mods - there will be multiple .omwscript files, I'm assuming you already know which mod you want to try/test. Enabling all of them at the same time might break something... or not.

If you dont see the .omwscript file you are looking for - in the launcher - probably i havent moved it outside the scripts folder yet. You have to register my scripts folder in your Data Directorieslike this:
![Data directories](/imgs/datadirectories.png)


Have fun!

## Credit

Physics sound effects by a dear friend https://nimsound.ru/
ElevenLabs-generated voice lines by [vonwolfe](https://next.nexusmods.com/profile/vonwolfe).

## Mods

### reAnimation - v2: Rogue

![reAnimation banner](/imgs/reanim_banner_long.png)

An updtae to reAnimation retouching on 1-handed, bows and daggers. Daggers have unique walk cycles and idles, every retouched weapon has unique sneak idle. 1-handed weapons daggers have alternating attack animations. *Strongly* recommended to be used with "Smooth animation transitions" enabled in the launcher (Launcher -> Settings -> Visual -> Smooth animation transitions, should be present in the latest dev build)

### Mercy: CAO

Mercy: Combat AI Overhaul. 
A significant overhaul of in-combat NPC behavior using custom lua behavior trees library, with new voice lines and animations. Only melee NPCs are affected. New combat voicelines (currently only for dunmer and nord).

#### Extending Mercy: CAO

Mercy can be extended with other behavious via an interface, allowing for multiple mods to implement various behaviour that will seamlessly work together. First of all Mercy script should be in a load order _before_ your extension. Secondly you should use the extension interface before the first onUpdate call, otherwise Mercy will finish its initialisation without acknowledging your extension. It's not possible to extend Mercy in a middle of it's runtime.

Extensions are done using `interfaces.MercyCAO.addExtension(treeName, extensionPointName, extensionObject)`.
Mercy AI is globally split to 2 different behaviour trees (`treeName` argument. And actually its 3 trees, but let's ignore the 3rd one - it's an auxiliary and doesn't have any extension points):
- `Locomotion` - A tree responsible for character movement through space - strafing, chasing, moving around e.t.c
- `Combat` - responsible for attacking - checking range, making quick or long swings, series of attacks e.t.c
Those trees run in parallel.

Furtermore all of the behaviours/branches within those trees are grouped within 4 principal combat AI states (`extensionPointName` argument):
- `STAND_GROUND` - Although technically in a combat state (Combat ai package, in fact Mercy works _only_ when combat package is active) - actor is hesitant to engage, will not rush towards the enemy, will slowly move around a bit, play a warning voice line. If too much time will pass in this state (while enemy is in line of sight) or an enemy will get too close - combat stat will switch to `FIGHT`
- `FIGHT` - Main engagement mode. Actor will run, strafe, chase, fallback, attack e.t.c. If actor's health gets too low - it _might_ switch to `RETREAT` or `MERCY` state.
- `RETREAT` - Checks if there are other actors nearby potentially aggressive towards actors enemy - if so - retreats towards them and waits there. Similarly to `STAND_GROUND` - if enemy gets too close - reingages `FIGHT`
- `MERCY` - Actor asks for mercy, lays down their weapons/items and gets pacified. If Actor is attacked too much during this process - will reingage `FIGHT`

`extensionObject` is a lua table that implements your behaviour, it's structured in a very similar way to behaviour nodes used internally by Mercy. This table supposed to implement a set of methods that will be called by the behaviour tree when the execution flow reached that part of the tree.

At the moment only `Locomotion` tree and `STAND_GROUND` extension point are supported, in the future all trees and state will be available for extension.

Interface use example:
```Lua
local interfaces = require('openmw.interfaces')

interfaces.MercyCAO.addExtension("Locomotion", "STAND_GROUND", {
   name = "My custom extension",
   start = function(task, state)
      print("My custom extension started")
   end,
   run = function(task, state)
      print("My custom extension running!")
      -- task:success() -- Ends this task (extension) with a success state. This will continue execution through the rest of MercyCAO behaviours in this part of the tree.
      task:fail() -- End with a failure state. This will prevent the rest of behaviors in this part of the tree from running.
      -- task:running() -- Return this to signify that your task is still running. run function will start again next frame.
   end,
   finish = function(task, state)
      print("My custom extension is done!")
    end
})
```

`state` argument is a shared behaviour tree's state object (sometimes called a "blackboard" in other behaviour tree libraries/implementations), its a table of properties and functions to which all of the Mercy: CAO behaviour trees have direct access.

There are number of properties you can set on a state object to affect the actor, main ones are:
```Lua
-- Velues below are default values. These properties are reset to their defaults EVERY FRAME before the tree runs, so if you want to keep .movement at a specific value - you need to set it every frame, i.e every run() of your extension!
state.stance = types.Actor.STANCE.Weapon
state.run = true
state.jump = false
state.attack = 0 -- directly maps to self.controls.use
state.movement = 0
state.sideMovement = 0
state.lookDirection = nil -- a global vector from actor toward its look target, actor will be interpolate-rotated towards that, otherwise it will loop at its enemyActor
-- Value below will NOT be reset every frame - you can change it to force Mercy trees to switch into a different combat state
state.combatState = "STAND_GROUND",
-- Below is a current combat package target, you shouldn't change this - but it's useful to know who this actor is fighting against
state.enemyActor
-- current frame's delta time
state.dt

```

If your extension was successfully attached - you should see a `[MercyCAO][...] Found an extension your_extension ...` message printed in the console (f10 lua console or a game process console, not in-game tilda console).

If you are familiar with the concept of behaviour trees here's a visual aid explaining where those extension nodes are injected:
![alt text](/imgs/extension.png)
If you want to read about behaviour trees - see my haphazard writeup and some links (and images!) in [this repository](https://github.com/MaxYari/behaviourtreelua2e).

### PhysicsInteractions

A mod for testing an experimental OpenMW physics branch. 
Grab and drag objects around by holding X in a similar (but not as granular) fashion to Oblivion/Skyrim. Press LMB while holding an object to throw it. Thrown items can damage NPCs. The damage and the throw strength are dependent on your strength stat.

### PlayerMovement

A mod for testing new actor movement lua bindings, also an experimental branch. Press jump in the air to air-dash.




