--[[
  `openmw.types` defines functions for specific types of game objects.
  local types = require('openmw.types')
]]

local openmw_core = require("openmw.core")
local openmw_util = require("openmw.util")
global record Activator
  --[[
    Creates a @{#ActivatorRecord} without adding it to the world database.
    Use @{openmw_world#(world).createRecord} to add the record to the world.
  ]]
  createRecordDraft: function(
    activator: types.ActivatorRecord
  ): types.ActivatorRecord
  
  --[[
    Whether the object is an Activator.
  ]]
  objectIsInstance: function(
    object: openmw_core.GameObject
  ): boolean
  
  --[[
    Returns the read-only @{#ActivatorRecord} of an activator
  ]]
  record: function(
    objectOrRecordId: any
  ): types.ActivatorRecord
  
  --[[
    A read-only list of all @{#ActivatorRecord}s in the world database.
  ]]
  records: { types.ActivatorRecord }
  
end
--[[
  Common functions for Creature, NPC, and Player.
]]
global record Actor
  --[[
    Available @{#EQUIPMENT_SLOT} values.
    Used in `Actor.equipment(obj)` and `Actor.setEquipment(obj, eqp)`.
  ]]
  EQUIPMENT_SLOT: types.EQUIPMENT_SLOT
  
  --[[
    @{#STANCE}
  ]]
  STANCE: types.STANCE
  
  --[[
    Return the active magic effects (@{#ActorActiveEffects}) currently affecting the given actor.
  ]]
  activeEffects: function(
    actor: openmw_core.GameObject
  ): types.ActorActiveEffects
  
  --[[
    Return the active spells (@{#ActorActiveSpells}) currently affecting the given actor.
  ]]
  activeSpells: function(
    actor: openmw_core.GameObject
  ): types.ActorActiveSpells
  
  --[[
    Returns true if the object is an actor and is able to move.
    For dead, paralyzed,
    or knocked down actors it returns false.
  ]]
  canMove: function(
    object: openmw_core.GameObject
  ): boolean
  
  --[[
    Clears the actor's selected castable(spell or enchanted item)
  ]]
  clearSelectedCastable: function(
    actor: openmw_core.GameObject
  )
  
  --[[
    Current speed.
  ]]
  getCurrentSpeed: function(
    actor: openmw_core.GameObject
  ): number

  --[[
    Damage actor.
  ]]
  hit: function(
    target: openmw_core.GameObject, 
    damage: number,
    ishealth: boolean, 
    weapon: openmw_core.GameObject,
    attacker: openmw_core.GameObject,
    hitPosition: openmw_util.Vector3,
    successful: boolean
  )
  
  --[[
    Get the total weight of everything the actor is carrying, plus modifications from magic effects.
  ]]
  getEncumbrance: function(
    actor: openmw_core.GameObject
  ): number
  
  --[[
    Get equipment.
    Has two overloads:
    
      * With a single argument: returns a table `slot` -> @{openmw.core#GameObject} of currently equipped items.
    See @{#EQUIPMENT_SLOT}. Returns empty table if the actor doesn't have equipment slots.
      * With two arguments: returns an item equipped to the given slot.
  ]]
  getEquipment: function(
    actor: openmw_core.GameObject,
    slot: number
  ): types.EquipmentTable | openmw_core.GameObject
  
  --[[
    Agent bounds to be used for pathfinding functions.
  ]]
  getPathfindingAgentBounds: function(
    actor: openmw_core.GameObject
  ): table
  
  --[[
    Speed of running.
    For dead actors it still returns a positive value.
  ]]
  getRunSpeed: function(
    actor: openmw_core.GameObject
  ): number
  
  --[[
    Get currently selected enchanted item
  ]]
  getSelectedEnchantedItem: function(
    actor: openmw_core.GameObject
  ): any
  
  --[[
    Get currently selected spell
  ]]
  getSelectedSpell: function(
    actor: openmw_core.GameObject
  ): any
  
  --[[
    Returns the current stance (whether a weapon/spell is readied), see the list of @{#STANCE} values.
  ]]
  getStance: function(
    actor: openmw_core.GameObject
  ): number
  
  --[[
    Speed of walking.
    For dead actors it still returns a positive value.
  ]]
  getWalkSpeed: function(
    actor: openmw_core.GameObject
  ): number
  
  --[[
    Returns `true` if the item is equipped on the actor.
  ]]
  hasEquipped: function(
    actor: openmw_core.GameObject,
    item: openmw_core.GameObject
  ): boolean
  
  --[[
    Actor inventory.
  ]]
  inventory: function(
    actor: openmw_core.GameObject
  ): openmw_core.Inventory
  
  --[[
    Check if given actor is in the actors processing range.
  ]]
  isInActorsProcessingRange: function(
    actor: openmw_core.GameObject
  ): boolean
  
  --[[
    Is the actor standing on ground.
    Can be called only from a local script.
  ]]
  isOnGround: function(
    actor: openmw_core.GameObject
  ): boolean
  
  --[[
    Is the actor in water.
    Can be called only from a local script.
  ]]
  isSwimming: function(
    actor: openmw_core.GameObject
  ): boolean
  
  --[[
    Whether the object is an actor.
  ]]
  objectIsInstance: function(
    object: openmw_core.GameObject
  ): boolean
  
  --[[
    Set equipment.
    Keys in the table are equipment slots (see @{#EQUIPMENT_SLOT}). Each
    value can be either a `GameObject` or recordId. Raises an error if
    the actor doesn't have equipment slots and table is not empty. Can be
    used only in local scripts and only on self.
    local self = require('openmw.self')
    local Actor = require('openmw.types').Actor
    Actor.setEquipment(self, {}) -- unequip all
  ]]
  setEquipment: function(
    actor: openmw_core.GameObject,
    equipment: types.EquipmentTable
  )
  
  --[[
    Set currently selected enchanted item, equipping it if applicable
  ]]
  setSelectedEnchantedItem: function(
    actor: openmw_core.GameObject,
    item: openmw_core.GameObject
  )
  
  --[[
    Set selected spell
  ]]
  setSelectedSpell: function(
    actor: openmw_core.GameObject,
    spell: openmw_core.Spell
  )
  
  --[[
    Sets the current stance (whether a weapon/spell is readied), see the list of @{#STANCE} values.
    Can be used only in local scripts on self.
  ]]
  setStance: function(
    actor: openmw_core.GameObject,
    stance: number
  )
  
  --[[
    Return the spells (@{#ActorSpells}) of the given actor.
  ]]
  spells: function(
    actor: openmw_core.GameObject
  ): types.ActorSpells
  
  --[[
    The actor's stats.
  ]]
  stats: types.ActorStats
  
end
global record Apparatus
  --[[
    @{#ApparatusTYPE}
  ]]
  TYPE: types.ApparatusTYPE
  
  --[[
    @{#Item}
  ]]
  baseType: Item
  
  --[[
    Whether the object is an Apparatus.
  ]]
  objectIsInstance: function(
    object: openmw_core.GameObject
  ): boolean
  
  --[[
    Returns the read-only @{#ApparatusRecord} of an apparatus
  ]]
  record: function(
    objectOrRecordId: any
  ): types.ApparatusRecord
  
  --[[
    A read-only list of all @{#ApparatusRecord}s in the world database.
  ]]
  records: { types.ApparatusRecord }
  
end
global record Armor
  --[[
    @{#ArmorTYPE}
  ]]
  TYPE: types.ArmorTYPE
  
  --[[
    @{#Item}
  ]]
  baseType: Item
  
  --[[
    Creates a @{#ArmorRecord} without adding it to the world database, for the armor to appear correctly on the body, make sure to use a template as described below.
    Use @{openmw_world#(world).createRecord} to add the record to the world.
    local armorTemplate = types.Armor.record('orcish_cuirass')
    local armorTable = {name = "Better Orcish Cuirass",template = armorTemplate,baseArmor = armorTemplate.baseArmor + 10} 
     --This is the new record we want to create, with a record provided as a template.
    local recordDraft = types.Armor.createRecordDraft(armorTable)--Need to convert the table into the record draft
    local newRecord = world.createRecord(recordDraft)--This creates the actual record
    world.createObject(newRecord):moveInto(playerActor)--Create an instance of this object, and move it into the player's inventory
  ]]
  createRecordDraft: function(
    armor: types.ArmorRecord
  ): types.ArmorRecord
  
  --[[
    Whether the object is an Armor.
  ]]
  objectIsInstance: function(
    object: openmw_core.GameObject
  ): boolean
  
  --[[
    Returns the read-only @{#ArmorRecord} of an Armor
  ]]
  record: function(
    objectOrRecordId: any
  ): types.ArmorRecord
  
  --[[
    A read-only list of all @{#ArmorRecord}s in the world database.
  ]]
  records: { types.ArmorRecord }
  
end
global record Book
  --[[
    DEPRECATED, use @{openmw.core#Skill}
  ]]
  SKILL: types.BookSKILL
  
  --[[
    @{#Item}
  ]]
  baseType: Item
  
  --[[
    Creates a @{#BookRecord} without adding it to the world database.
    Use @{openmw_world#(world).createRecord} to add the record to the world.
  ]]
  createRecordDraft: function(
    book: types.BookRecord
  ): types.BookRecord
  
  --[[
    Whether the object is a Book.
  ]]
  objectIsInstance: function(
    object: openmw_core.GameObject
  ): boolean
  
  --[[
    Returns the read-only @{#BookRecord} of a book
  ]]
  record: function(
    objectOrRecordId: any
  ): types.BookRecord
  
  --[[
    A read-only list of all @{#BookRecord}s in the world database.
  ]]
  records: { types.BookRecord }
  
end
global record Clothing
  --[[
    @{#ClothingTYPE}
  ]]
  TYPE: types.ClothingTYPE
  
  --[[
    @{#Item}
  ]]
  baseType: Item
  
  --[[
    Creates a @{#ClothingRecord} without adding it to the world database, for the clothing to appear correctly on the body, make sure to use a template as described below.
    Use @{openmw_world#(world).createRecord} to add the record to the world.
    local clothingTemplate = types.Clothing.record('exquisite_robe_01')
    local clothingTable = {name = "Better Exquisite Robe",template = clothingTemplate,enchantCapacity = clothingTemplate.enchantCapacity + 10} 
     --This is the new record we want to create, with a record provided as a template.
    local recordDraft = types.Clothing.createRecordDraft(clothingTable)--Need to convert the table into the record draft
    local newRecord = world.createRecord(recordDraft)--This creates the actual record
    world.createObject(newRecord):moveInto(playerActor)--Create an instance of this object, and move it into the player's inventory
  ]]
  createRecordDraft: function(
    clothing: types.ClothingRecord
  ): types.ClothingRecord
  
  --[[
    Whether the object is a Clothing.
  ]]
  objectIsInstance: function(
    object: openmw_core.GameObject
  ): boolean
  
  --[[
    Returns the read-only @{#ClothingRecord} of a Clothing
  ]]
  record: function(
    objectOrRecordId: any
  ): types.ClothingRecord
  
  --[[
    A read-only list of all @{#ClothingRecord}s in the world database.
  ]]
  records: { types.ClothingRecord }
  
end
global record Container
  --[[
    @{#Lockable}
  ]]
  baseType: Lockable
  
  --[[
    Container content.
  ]]
  content: function(
    object: openmw_core.GameObject
  ): openmw_core.Inventory
  
  --[[
    Returns the capacity of a container
  ]]
  getCapacity: function(
    object: openmw_core.GameObject
  ): number
  
  --[[
    Returns the total weight of everything in a container
  ]]
  getEncumbrance: function(
    object: openmw_core.GameObject
  ): number
  
  --[[
    Container content (same as `Container.content`, added for consistency with `Actor.inventory`).
  ]]
  inventory: function(
    object: openmw_core.GameObject
  ): openmw_core.Inventory
  
  --[[
    Whether the object is a Container.
  ]]
  objectIsInstance: function(
    object: openmw_core.GameObject
  ): boolean
  
  --[[
    Returns the read-only @{#ContainerRecord} of a container
  ]]
  record: function(
    objectOrRecordId: any
  ): types.ContainerRecord
  
  --[[
    A read-only list of all @{#ContainerRecord}s in the world database.
  ]]
  records: { types.ContainerRecord }
  
end
global record Creature
  --[[
    @{#CreatureTYPE}
  ]]
  TYPE: types.CreatureTYPE
  
  --[[
    @{#Actor}
  ]]
  baseType: Actor
  
  --[[
    Whether the object is a creature.
  ]]
  objectIsInstance: function(
    object: openmw_core.GameObject
  ): boolean
  
  --[[
    Returns the read-only @{#CreatureRecord} of a creature
  ]]
  record: function(
    objectOrRecordId: any
  ): types.CreatureRecord
  
  --[[
    A read-only list of all @{#CreatureRecord}s in the world database.
  ]]
  records: { types.CreatureRecord }
  
end
global record CreatureLevelledList
  --[[
    Whether the object is a CreatureLevelledList.
  ]]
  objectIsInstance: function(
    object: openmw_core.GameObject
  ): boolean
  
  --[[
    Returns the read-only @{#CreatureLevelledListRecord} of a levelled creature
  ]]
  record: function(
    objectOrRecordId: any
  ): types.CreatureLevelledListRecord
  
  --[[
    A read-only list of all @{#CreatureLevelledListRecord}s in the world database.
  ]]
  records: { types.CreatureLevelledListRecord }
  
end
global record Door
  --[[
    @{#Lockable}
  ]]
  baseType: Lockable
  
  --[[
    Destination cell (only if a teleport door).
  ]]
  destCell: function(
    object: openmw_core.GameObject
  ): openmw_core.Cell
  
  --[[
    Destination (only if a teleport door).
  ]]
  destPosition: function(
    object: openmw_core.GameObject
  ): openmw_util.Vector3
  
  --[[
    Destination rotation (only if a teleport door).
  ]]
  destRotation: function(
    object: openmw_core.GameObject
  ): openmw_util.Transform
  
  --[[
    Whether the door is a teleport.
  ]]
  isTeleport: function(
    object: openmw_core.GameObject
  ): boolean
  
  --[[
    Whether the object is a Door.
  ]]
  objectIsInstance: function(
    object: openmw_core.GameObject
  ): boolean
  
  --[[
    Returns the read-only @{#DoorRecord} of a door
  ]]
  record: function(
    objectOrRecordId: any
  ): types.DoorRecord
  
  --[[
    A read-only list of all @{#DoorRecord}s in the world database.
  ]]
  records: { types.DoorRecord }
  
end
global record ESM4Activator
end
global record ESM4Ammunition
end
global record ESM4Armor
end
global record ESM4Book
end
global record ESM4Clothing
end
global record ESM4Door
  --[[
    @{#Lockable}
  ]]
  baseType: Lockable
  
  --[[
    Destination cell (only if a teleport door).
  ]]
  destCell: function(
    object: openmw_core.GameObject
  ): openmw_core.Cell
  
  --[[
    Destination (only if a teleport door).
  ]]
  destPosition: function(
    object: openmw_core.GameObject
  ): openmw_util.Vector3
  
  --[[
    Destination rotation (only if a teleport door).
  ]]
  destRotation: function(
    object: openmw_core.GameObject
  ): openmw_util.Transform
  
  --[[
    Whether the door is a teleport.
  ]]
  isTeleport: function(
    object: openmw_core.GameObject
  ): boolean
  
  --[[
    Whether the object is a ESM4Door.
  ]]
  objectIsInstance: function(
    object: openmw_core.GameObject
  ): boolean
  
  --[[
    Returns the read-only @{#ESM4DoorRecord} of a door
  ]]
  record: function(
    objectOrRecordId: any
  ): types.ESM4DoorRecord
  
  --[[
    Returns a read-only list of all @{#ESM4DoorRecord}s in the world database.
  ]]
  records: function(): { types.ESM4DoorRecord }
  
end
global record ESM4Flora
end
global record ESM4Ingredient
end
global record ESM4Light
end
global record ESM4Miscellaneous
end
global record ESM4MovableStatic
end
global record ESM4Potion
end
global record ESM4Static
end
global record ESM4Terminal
  --[[
    Whether the object is a ESM4Terminal.
  ]]
  objectIsInstance: function(
    object: openmw_core.GameObject
  ): boolean
  
  --[[
    Returns the read-only @{#ESM4TerminalRecord} of a terminal
  ]]
  record: function(
    objectOrRecordId: any
  ): types.ESM4TerminalRecord
  
  --[[
    A read-only list of all @{#ESM4TerminalRecord}s in the world database.
  ]]
  records: { types.ESM4TerminalRecord }
  
end
global record ESM4Weapon
end
global record Ingredient
  --[[
    @{#Item}
  ]]
  baseType: Item
  
  --[[
    Whether the object is an Ingredient.
  ]]
  objectIsInstance: function(
    object: openmw_core.GameObject
  ): boolean
  
  --[[
    Returns the read-only @{#IngredientRecord} of a Ingredient
  ]]
  record: function(
    objectOrRecordId: any
  ): types.IngredientRecord
  
  --[[
    A read-only list of all @{#IngredientRecord}s in the world database.
  ]]
  records: { types.IngredientRecord }
  
end
--[[
  Functions for items that can be placed to an inventory or container
]]
global record Item
  --[[
    Get this item's current enchantment charge.
  ]]
  getEnchantmentCharge: function(
    item: openmw_core.GameObject
  ): number
  
  --[[
    Whether the object is supposed to be carriable.
    It is true for all items except
    lights without the Carry flag. Non-carriable lights can still be put into
    an inventory with an explicit `object:moveInto` call.
  ]]
  isCarriable: function(
    object: openmw_core.GameObject
  ): boolean
  
  --[[
    Checks if the item restocks.
    Returns true if the object restocks, and false otherwise.
  ]]
  isRestocking: function(
    item: openmw_core.GameObject
  ): boolean
  
  --[[
    Whether the object is an item.
  ]]
  objectIsInstance: function(
    object: openmw_core.GameObject
  ): boolean
  
  --[[
    Set this item's enchantment charge.
  ]]
  setEnchantmentCharge: function(
    item: openmw_core.GameObject,
    charge: number
  )
  
end
global record Light
  --[[
    @{#Item}
  ]]
  baseType: Item
  
  --[[
    Whether the object is a Light.
  ]]
  objectIsInstance: function(
    object: openmw_core.GameObject
  ): boolean
  
  --[[
    Returns the read-only @{#LightRecord} of a Light
  ]]
  record: function(
    objectOrRecordId: any
  ): types.LightRecord
  
  --[[
    A read-only list of all @{#LightRecord}s in the world database.
  ]]
  records: { types.LightRecord }
  
end
global record Lockable
  --[[
    Returns the key record of a lockable object(door, container)
  ]]
  getKeyRecord: function(
    object: openmw_core.GameObject
  ): types.MiscellaneousRecord
  
  --[[
    Returns the lock level of a lockable object(door, container).
    Does not determine if an object is locked or not, if an object is locked while this is set above 0, this value will be used if no other value is specified.
  ]]
  getLockLevel: function(
    object: openmw_core.GameObject
  ): number
  
  --[[
    Returns the trap spell of a lockable object(door, container)
  ]]
  getTrapSpell: function(
    object: openmw_core.GameObject
  ): openmw_core.Spell
  
  --[[
    Returns true if the lockable object is locked, and false if it is not.
  ]]
  isLocked: function(
    object: openmw_core.GameObject
  ): boolean
  
  --[[
    Sets the lock level level of a lockable object(door, container);Locks if not already locked; Must be used in a global script.
  ]]
  lock: function(
    object: openmw_core.GameObject,
    lockLevel: number
  )
  
  --[[
    Sets the key of a lockable object(door, container); removes it if empty string is provided.
    Must be used in a global script.
  ]]
  setKeyRecord: function(
    object: openmw_core.GameObject,
    miscOrId: any
  )
  
  --[[
    Sets the trap spell of a lockable object(door, container); removes it if empty string is provided.
    Must be used in a global script.
  ]]
  setTrapSpell: function(
    object: openmw_core.GameObject,
    spellOrId: any
  )
  
  --[[
    Unlocks the lockable object.
    Does not change the lock level, it can be kept for future use.
  ]]
  unlock: function(
    object: openmw_core.GameObject
  )
  
end
global record Lockpick
  --[[
    @{#Item}
  ]]
  baseType: Item
  
  --[[
    Whether the object is a Lockpick.
  ]]
  objectIsInstance: function(
    object: openmw_core.GameObject
  ): boolean
  
  --[[
    Returns the read-only @{#LockpickRecord} of a lockpick
  ]]
  record: function(
    objectOrRecordId: any
  ): types.LockpickRecord
  
  --[[
    A read-only list of all @{#LockpickRecord}s in the world database.
  ]]
  records: { types.LockpickRecord }
  
end
global record Miscellaneous
  --[[
    @{#Item}
  ]]
  baseType: Item
  
  --[[
    Creates a @{#MiscellaneousRecord} without adding it to the world database.
    Use @{openmw_world#(world).createRecord} to add the record to the world.
  ]]
  createRecordDraft: function(
    miscellaneous: types.MiscellaneousRecord
  ): types.MiscellaneousRecord
  
  --[[
    Returns the read-only soul of a miscellaneous item
  ]]
  getSoul: function(
    object: openmw_core.GameObject
  ): string
  
  --[[
    Whether the object is a Miscellaneous.
  ]]
  objectIsInstance: function(
    object: openmw_core.GameObject
  ): boolean
  
  --[[
    Returns the read-only @{#MiscellaneousRecord} of a miscellaneous item
  ]]
  record: function(
    objectOrRecordId: any
  ): types.MiscellaneousRecord
  
  --[[
    A read-only list of all @{#MiscellaneousRecord}s in the world database.
  ]]
  records: { types.MiscellaneousRecord }
  
  --[[
    Sets the soul of a miscellaneous item, intended for soul gem objects; Must be used in a global script.
  ]]
  setSoul: function(
    object: openmw_core.GameObject,
    soulId: string
  )
  
end
global record NPC
  --[[
    @{#Actor}
  ]]
  baseType: Actor
  
  --[[
    Clear expelling of NPC from given faction.
    Throws an exception if there is no such faction.
    local NPC = require('openmw.types').NPC;
    NPC.clearExpell(player, "mages guild");
  ]]
  clearExpelled: function(
    actor: openmw_core.GameObject, --[[NPC object]]
    faction: string
  )
  
  --[[
    Expell NPC from given faction.
    Throws an exception if there is no such faction.
    Note: expelled NPC still keeps his rank and reputation in faction, he just get an additonal flag for given faction.
    local NPC = require('openmw.types').NPC;
    NPC.expell(player, "mages guild");
  ]]
  expell: function(
    actor: openmw_core.GameObject, --[[NPC object]]
    faction: string
  )
  
  --[[
    Get the total weight that the actor can carry.
  ]]
  getCapacity: function(
    actor: openmw_core.GameObject
  ): number
  
  --[[
    Returns the current disposition of the provided NPC.
    This is their derived disposition, after modifiers such as personality and faction relations are taken into account.
  ]]
  getDisposition: function(
    object: openmw_core.GameObject,
    player: openmw_core.GameObject
  ): number
  
  --[[
    Get rank of given NPC in given faction.
    Throws an exception if there is no such faction.
    Note: this function does not take in account an expelling state.
    local NPC = require('openmw.types').NPC;
    print(NPC.getFactionRank(player, "mages guild");
  ]]
  getFactionRank: function(
    actor: openmw_core.GameObject, --[[NPC object]]
    faction: string
  ): number
  
  --[[
    Get reputation of given actor in given faction.
    Throws an exception if there is no such faction.
    local NPC = require('openmw.types').NPC;
    print(NPC.getFactionReputation(player, "mages guild"));
  ]]
  getFactionReputation: function(
    actor: openmw_core.GameObject, --[[NPC object]]
    faction: string
  ): number
  
  --[[
    Get all factions in which NPC has a membership.
    Note: this function does not take in account an expelling state.
    local NPC = require('openmw.types').NPC;
    for _, factionId in pairs(types.NPC.getFactions(actor)) do
        print(factionId);
    end
  ]]
  getFactions: function(
    actor: openmw_core.GameObject
  ): { string }
  
  --[[
    Check if NPC is expelled from given faction.
    Throws an exception if there is no such faction.
    local NPC = require('openmw.types').NPC;
    local result = NPC.isExpelled(player, "mages guild");
  ]]
  isExpelled: function(
    actor: openmw_core.GameObject, --[[NPC object]]
    faction: string
  ): types.bool
  
  --[[
    Whether the NPC or player is in the werewolf form at the moment.
  ]]
  isWerewolf: function(
    actor: openmw_core.GameObject
  ): boolean
  
  --[[
    Add given actor to given faction.
    Throws an exception if there is no such faction or target actor is not player.
    Function does nothing if valid target actor is already a member of target faction.
    local NPC = require('openmw.types').NPC;
    NPC.joinFaction(player, "mages guild");
  ]]
  joinFaction: function(
    actor: openmw_core.GameObject, --[[NPC object]]
    faction: string
  )
  
  --[[
    Remove given actor from given faction.
    Function removes rank data and expelling state, but keeps a reputation in target faction.
    Throws an exception if there is no such faction or target actor is not player.
    Function does nothing if valid target actor is already not member of target faction.
    local NPC = require('openmw.types').NPC;
    NPC.leaveFaction(player, "mages guild");
  ]]
  leaveFaction: function(
    actor: openmw_core.GameObject, --[[NPC object]]
    faction: string
  )
  
  --[[
    Adjust rank of given NPC in given faction.
    Throws an exception if there is no such faction or actor is not a member of given faction.
    For NPCs faction also should be an NPC's primary faction.
    Notes:
    
      * If rank should become <= 0 after modification, function set rank to lowest available rank.
      * If rank should become > 0 after modification, but target rank does not exist, function set rank to the highest valid rank.
    local NPC = require('openmw.types').NPC;
    NPC.modifyFactionRank(player, "mages guild", 1);
  ]]
  modifyFactionRank: function(
    actor: openmw_core.GameObject, --[[NPC object]]
    faction: string, --[[Faction ID]]
    value: number
  )
  
  --[[
    Adjust reputation of given actor in given faction.
    Throws an exception if there is no such faction.
    local NPC = require('openmw.types').NPC;
    NPC.modifyFactionReputation(player, "mages guild", 5);
  ]]
  modifyFactionReputation: function(
    actor: openmw_core.GameObject, --[[NPC object]]
    faction: string, --[[Faction ID]]
    value: number
  )
  
  --[[
    Whether the object is an NPC or a Player.
  ]]
  objectIsInstance: function(
    object: openmw_core.GameObject
  ): boolean
  
  --[[
    Returns the read-only @{#NpcRecord} of an NPC
  ]]
  record: function(
    objectOrRecordId: any
  ): types.NpcRecord
  
  --[[
    A read-only list of all @{#NpcRecord}s in the world database.
  ]]
  records: { types.NpcRecord }
  
  --[[
    Set rank of given NPC in given faction.
    Throws an exception if there is no such faction, target rank does not exist or actor is not a member of given faction.
    For NPCs faction also should be an NPC's primary faction.
    local NPC = require('openmw.types').NPC;
    NPC.setFactionRank(player, "mages guild", 6);
  ]]
  setFactionRank: function(
    actor: openmw_core.GameObject, --[[NPC object]]
    faction: string, --[[Faction ID]]
    value: number
  )
  
  --[[
    Set reputation of given actor in given faction.
    Throws an exception if there is no such faction.
    local NPC = require('openmw.types').NPC;
    NPC.setFactionReputation(player, "mages guild", 100);
  ]]
  setFactionReputation: function(
    actor: openmw_core.GameObject, --[[NPC object]]
    faction: string, --[[Faction ID]]
    value: number
  )
  
  stats: types.NpcStats
  
end
global record Player
  --[[
    Values that can be used with getControlSwitch/setControlSwitch.
  ]]
  CONTROL_SWITCH: types.CONTROL_SWITCH
  
  --[[
    @{#NPC}
  ]]
  baseType: NPC
  
  --[[
    Get state of a control switch.
    I.e. is the player able to move/fight/jump/etc.
  ]]
  getControlSwitch: function(
    player: openmw_core.GameObject,
    key: types.ControlSwitch
  ): boolean
  
  --[[
    Returns the bounty or crime level of the player
  ]]
  getCrimeLevel: function(
    player: openmw_core.GameObject
  ): number
  
  --[[
    Whether the character generation for this player is finished.
  ]]
  isCharGenFinished: function(
    player: openmw_core.GameObject
  ): boolean
  
  --[[
    Whether teleportation for this player is enabled.
  ]]
  isTeleportingEnabled: function(
    player: openmw_core.GameObject,
    player: boolean
  ): boolean
  
  --[[
    Whether the object is a player.
  ]]
  objectIsInstance: function(
    object: openmw_core.GameObject
  ): boolean
  
  --[[
    Returns a list containing quests @{#PlayerQuest} for the specified player, indexed by quest ID.
    -- Get stage of a specific quest
    stage = types.Player.quests(player)["ms_fargothring"].stage
  ]]
  quests: function(
    player: openmw_core.GameObject
  ): { types.PlayerQuest }
  
  --[[
    Set state of a control switch.
    I.e. forbid or allow the player to move/fight/jump/etc.
    Can be used only in global or player scripts.
  ]]
  setControlSwitch: function(
    player: openmw_core.GameObject,
    key: types.ControlSwitch, --[[Control type (see @{openmw.types#CONTROL_SWITCH})]]
    value: boolean
  )
  
  --[[
    Enables or disables teleportation for this player.
  ]]
  setTeleportingEnabled: function(
    player: openmw_core.GameObject,
    state: boolean
  )
  
end
global record Potion
  --[[
    @{#Item}
  ]]
  baseType: Item
  
  --[[
    Creates a @{#PotionRecord} without adding it to the world database.
    Use @{openmw_world#(world).createRecord} to add the record to the world.
  ]]
  createRecordDraft: function(
    potion: types.PotionRecord
  ): types.PotionRecord
  
  --[[
    Whether the object is a Potion.
  ]]
  objectIsInstance: function(
    object: openmw_core.GameObject
  ): boolean
  
  --[[
    Returns the read-only @{#PotionRecord} of a potion
  ]]
  record: function(
    objectOrRecordId: any
  ): types.PotionRecord
  
  --[[
    A read-only list of all @{#PotionRecord}s in the world database.
  ]]
  records: { types.PotionRecord }
  
end
global record Probe
  --[[
    @{#Item}
  ]]
  baseType: Item
  
  --[[
    Whether the object is a Probe.
  ]]
  objectIsInstance: function(
    object: openmw_core.GameObject
  ): boolean
  
  --[[
    Returns the read-only @{#ProbeRecord} of a probe
  ]]
  record: function(
    objectOrRecordId: any
  ): types.ProbeRecord
  
  --[[
    A read-only list of all @{#ProbeRecord}s in the world database.
  ]]
  records: { types.ProbeRecord }
  
end
global record Repair
  --[[
    @{#Item}
  ]]
  baseType: Item
  
  --[[
    Whether the object is a Repair.
  ]]
  objectIsInstance: function(
    object: openmw_core.GameObject
  ): boolean
  
  --[[
    Returns the read-only @{#RepairRecord} of a repair tool
  ]]
  record: function(
    objectOrRecordId: any
  ): types.RepairRecord
  
  --[[
    A read-only list of all @{#RepairRecord}s in the world database.
  ]]
  records: { types.RepairRecord }
  
end
global record Static
  --[[
    Whether the object is a Static.
  ]]
  objectIsInstance: function(
    object: openmw_core.GameObject
  ): boolean
  
  --[[
    Returns the read-only @{#StaticRecord} of a Static
  ]]
  record: function(
    objectOrRecordId: any
  ): types.StaticRecord
  
  --[[
    A read-only list of all @{#StaticRecord}s in the world database.
  ]]
  records: { types.StaticRecord }
  
end
global record Weapon
  --[[
    @{#WeaponTYPE}
  ]]
  TYPE: types.WeaponTYPE
  
  --[[
    @{#Item}
  ]]
  baseType: Item
  
  --[[
    Creates a @{#WeaponRecord} without adding it to the world database.
    Use @{openmw_world#(world).createRecord} to add the record to the world.
  ]]
  createRecordDraft: function(
    weapon: types.WeaponRecord
  ): types.WeaponRecord
  
  --[[
    Whether the object is a Weapon.
  ]]
  objectIsInstance: function(
    object: openmw_core.GameObject
  ): boolean
  
  --[[
    Returns the read-only @{#WeaponRecord} of a weapon
  ]]
  record: function(
    objectOrRecordId: any
  ): types.WeaponRecord
  
  --[[
    A read-only list of all @{#WeaponRecord}s in the world database.
  ]]
  records: { types.WeaponRecord }
  
end
local record types
  --[[
    @{#Activator} functions
  ]]
  Activator: Activator
  
  --[[
    Common @{#Actor} functions for Creature, NPC, and Player.
  ]]
  Actor: Actor
  
  --[[
    @{#Apparatus} functions
  ]]
  Apparatus: Apparatus
  
  --[[
    @{#Armor} functions
  ]]
  Armor: Armor
  
  --[[
    @{#Book} functions
  ]]
  Book: Book
  
  --[[
    @{#Clothing} functions
  ]]
  Clothing: Clothing
  
  --[[
    @{#Container} functions
  ]]
  Container: Container
  
  --[[
    @{#Creature} functions
  ]]
  Creature: Creature
  
  --[[
    @{#Door} functions
  ]]
  Door: Door
  
  --[[
    Functions for @{#ESM4Activator} objects
  ]]
  ESM4Activator: ESM4Activator
  
  --[[
    Functions for @{#ESM4Ammunition} objects
  ]]
  ESM4Ammunition: ESM4Ammunition
  
  --[[
    Functions for @{#ESM4Armor} objects
  ]]
  ESM4Armor: ESM4Armor
  
  --[[
    Functions for @{#ESM4Book} objects
  ]]
  ESM4Book: ESM4Book
  
  --[[
    Functions for @{#ESM4Clothing} objects
  ]]
  ESM4Clothing: ESM4Clothing
  
  --[[
    Functions for @{#ESM4Door} objects
  ]]
  ESM4Door: ESM4Door
  
  --[[
    Functions for @{#ESM4Flora} objects
  ]]
  ESM4Flora: ESM4Flora
  
  --[[
    Functions for @{#ESM4Ingredient} objects
  ]]
  ESM4Ingredient: ESM4Ingredient
  
  --[[
    Functions for @{#ESM4Light} objects
  ]]
  ESM4Light: ESM4Light
  
  --[[
    Functions for @{#ESM4Miscellaneous} objects
  ]]
  ESM4Miscellaneous: ESM4Miscellaneous
  
  --[[
    Functions for @{#ESM4MovableStatic} objects
  ]]
  ESM4MovableStatic: ESM4MovableStatic
  
  --[[
    Functions for @{#ESM4Potion} objects
  ]]
  ESM4Potion: ESM4Potion
  
  --[[
    Functions for @{#ESM4Static} objects
  ]]
  ESM4Static: ESM4Static
  
  --[[
    Functions for @{#ESM4Terminal} objects
  ]]
  ESM4Terminal: ESM4Terminal
  
  --[[
    Functions for @{#ESM4Weapon} objects
  ]]
  ESM4Weapon: ESM4Weapon
  
  --[[
    @{#Ingredient} functions
  ]]
  Ingredient: Ingredient
  
  --[[
    @{#Item} functions (all items that can be placed to an inventory or container)
  ]]
  Item: Item
  
  --[[
    @{#CreatureLevelledList} functions
  ]]
  LevelledCreature: CreatureLevelledList
  
  --[[
    @{#Light} functions
  ]]
  Light: Light
  
  --[[
    @{#Lockable} functions
  ]]
  Lockable: Lockable
  
  --[[
    @{#Lockpick} functions
  ]]
  Lockpick: Lockpick
  
  --[[
    Functions for @{#Miscellaneous} objects
  ]]
  Miscellaneous: Miscellaneous
  
  --[[
    @{#NPC} functions
  ]]
  NPC: NPC
  
  --[[
    @{#Player} functions
  ]]
  Player: Player
  
  --[[
    @{#Potion} functions
  ]]
  Potion: Potion
  
  --[[
    @{#Probe} functions
  ]]
  Probe: Probe
  
  --[[
    @{#Repair} functions
  ]]
  Repair: Repair
  
  --[[
    Functions for @{#Static} objects
  ]]
  Static: Static
  
  --[[
    @{#Weapon} functions
  ]]
  Weapon: Weapon
  
  record ActivatorRecord
    --[[
      Record id
    ]]
    id: string
    
    --[[
      VFS path to the model
    ]]
    model: string
    
    --[[
      MWScript on this activator (can be empty)
    ]]
    mwscript: string
    
    --[[
      Human-readable name
    ]]
    name: string
    
  end
  --[[
    Read-only list of effects currently affecting the actor.
    -- print active effects
    for _, effect in pairs(Actor.activeEffects(self)) do
        print('Active Effect: '..effect.id..', attribute='..tostring(effect.affectedAttribute)..', skill='..tostring(effect.affectedSkill)..', magnitude='..tostring(effect.magnitude))
    end
  ]]
  record ActorActiveEffects
    --[[
      Get a specific active effect on the actor.
    ]]
    getEffect: function(
      self: types.ActorActiveEffects,
      effectId: string, --[[effect ID]]
      extraParam: string
    ): openmw_core.ActiveEffect
    
    --[[
      Permanently modifies the magnitude of an active effect by increasing it by the provided value.
      This adds the effect to the list of active effects if not already active.
    ]]
    modify: function(
      self: types.ActorActiveEffects,
      value: number,
      effectId: string, --[[effect ID]]
      extraParam: string
    )
    
    --[[
      Completely removes the active effect from the actor.
    ]]
    remove: function(
      self: types.ActorActiveEffects,
      effectId: string, --[[effect ID]]
      extraParam: string
    )
    
    --[[
      Permanently modifies the magnitude of an active effect to be exactly equal to the provided value.
      This adds the effect to the list of active effects if not already active.
      Note that although the modification is permanent, the magnitude will not stay equal to the value if any active spells with this effects are added/removed.
    ]]
    set: function(
      self: types.ActorActiveEffects,
      value: number,
      effectId: string, --[[effect ID]]
      extraParam: string
    )
    
  end
  --[[
    Read-only list of spells currently affecting the actor.
    Can be iterated over for a list of @{openmw.core#ActiveSpell}
    -- print active spells
    for _, spell in pairs(Actor.activeSpells(self)) do
        print('Active Spell: '..tostring(spell))
    end
  ]]
  record ActorActiveSpells
    --[[
      Get whether a specific spell is active on the actor.
    ]]
    isSpellActive: function(
      self: types.ActorActiveSpells,
      recordOrId: any
    ): any
    
    --[[
      Remove the given spell and all its effects from the given actor's active spells.
    ]]
    remove: function(
      self: types.ActorActiveSpells,
      spellOrId: any
    )
    
  end
  --[[
    List of spells with additional functions add/remove/clear (modification are allowed only in global scripts or on self).
    -- print available spells
    local mySpells = types.Actor.spells(self)
    for _, spell in pairs(mySpells) do print(spell.id) end
  ]]
  record ActorSpells
    --[[
      Add spell (only in global scripts or on self).
    ]]
    add: function(
      self: types.ActorSpells,
      spellOrId: any
    )
    
    --[[
      Remove all spells (only in global scripts or on self).
    ]]
    clear: function(
      self: types.ActorSpells
    )
    
    --[[
      Remove spell (only in global scripts or on self).
    ]]
    remove: function(
      self: types.ActorSpells,
      spellOrId: any
    )
    
  end
  record ActorStats
    attributes: types.AttributeStats
    
    dynamic: types.DynamicStats
    
    --[[
      Level (returns @{#LevelStat})
    ]]
    level: function(
      actor: openmw_core.GameObject
    ): types.LevelStat
    
  end
  record ApparatusRecord
    --[[
      VFS path to the icon
    ]]
    icon: string
    
    --[[
      The record ID of the apparatus
    ]]
    id: string
    
    --[[
      VFS path to the model
    ]]
    model: string
    
    --[[
      MWScript on this apparatus (can be empty)
    ]]
    mwscript: string
    
    --[[
      The name of the apparatus
    ]]
    name: string
    
    --[[
      The quality of the apparatus
    ]]
    quality: number
    
    --[[
      The type of apparatus. See @{#Apparatus.TYPE}
    ]]
    type: number
    
    value: number
    
    weight: number
    
  end
  --[[
    Apparatus.TYPE
  ]]
  record ApparatusTYPE
    Alembic: number
    
    Calcinator: number
    
    MortarPestle: number
    
    Retort: number
    
  end
  record ArmorRecord
    --[[
      The base armor rating of this armor
    ]]
    baseArmor: number
    
    --[[
      The enchantment ID of this armor (can be empty)
    ]]
    enchant: string
    
    enchantCapacity: number
    
    health: number
    
    --[[
      VFS path to the icon
    ]]
    icon: string
    
    --[[
      Record id
    ]]
    id: string
    
    --[[
      VFS path to the model
    ]]
    model: string
    
    --[[
      MWScript on this armor (can be empty)
    ]]
    mwscript: string
    
    --[[
      Human-readable name
    ]]
    name: string
    
    --[[
      See @{#Armor.TYPE}
    ]]
    type: number
    
    value: number
    
    weight: number
    
  end
  --[[
    Armor.TYPE
  ]]
  record ArmorTYPE
    Boots: number
    
    Cuirass: number
    
    Greaves: number
    
    Helmet: number
    
    LBracer: number
    
    LGauntlet: number
    
    LPauldron: number
    
    RBracer: number
    
    RGauntlet: number
    
    RPauldron: number
    
    Shield: number
    
  end
  record AttributeStat
    --[[
      The actor's base attribute value.
    ]]
    base: number
    
    --[[
      The amount the attribute has been damaged.
    ]]
    damage: number
    
    --[[
      The actor's current attribute value (read-only.)
    ]]
    modified: number
    
    --[[
      The attribute's modifier.
    ]]
    modifier: number
    
  end
  record AttributeStats
    --[[
      Agility (returns @{#AttributeStat})
    ]]
    agility: function(
      actor: openmw_core.GameObject
    ): types.AttributeStat
    
    --[[
      Endurance (returns @{#AttributeStat})
    ]]
    endurance: function(
      actor: openmw_core.GameObject
    ): types.AttributeStat
    
    --[[
      Intelligence (returns @{#AttributeStat})
    ]]
    intelligence: function(
      actor: openmw_core.GameObject
    ): types.AttributeStat
    
    --[[
      Luck (returns @{#AttributeStat})
    ]]
    luck: function(
      actor: openmw_core.GameObject
    ): types.AttributeStat
    
    --[[
      Personality (returns @{#AttributeStat})
    ]]
    personality: function(
      actor: openmw_core.GameObject
    ): types.AttributeStat
    
    --[[
      Speed (returns @{#AttributeStat})
    ]]
    speed: function(
      actor: openmw_core.GameObject
    ): types.AttributeStat
    
    --[[
      Strength (returns @{#AttributeStat})
    ]]
    strength: function(
      actor: openmw_core.GameObject
    ): types.AttributeStat
    
    --[[
      Willpower (returns @{#AttributeStat})
    ]]
    willpower: function(
      actor: openmw_core.GameObject
    ): types.AttributeStat
    
  end
  record BookRecord
    --[[
      The enchantment ID of this book (can be empty)
    ]]
    enchant: string
    
    enchantCapacity: number
    
    --[[
      VFS path to the icon
    ]]
    icon: string
    
    --[[
      The record ID of the book
    ]]
    id: string
    
    isScroll: boolean
    
    --[[
      VFS path to the model
    ]]
    model: string
    
    --[[
      MWScript on this book (can be empty)
    ]]
    mwscript: string
    
    --[[
      Name of the book
    ]]
    name: string
    
    --[[
      The skill that this book teaches. See @{openmw.core#SKILL}
    ]]
    skill: string
    
    --[[
      The text content of the book
    ]]
    text: string
    
    value: number
    
    weight: number
    
  end
  --[[
    Book.SKILL
  ]]
  record BookSKILL
    --[[
      "acrobatics"
    ]]
    acrobatics: string
    
    --[[
      "alchemy"
    ]]
    alchemy: string
    
    --[[
      "alteration"
    ]]
    alteration: string
    
    --[[
      "armorer"
    ]]
    armorer: string
    
    --[[
      "athletics"
    ]]
    athletics: string
    
    --[[
      "axe"
    ]]
    axe: string
    
    --[[
      "block"
    ]]
    block: string
    
    --[[
      "bluntweapon"
    ]]
    bluntWeapon: string
    
    --[[
      "conjuration"
    ]]
    conjuration: string
    
    --[[
      "destruction"
    ]]
    destruction: string
    
    --[[
      "enchant"
    ]]
    enchant: string
    
    --[[
      "handtohand"
    ]]
    handToHand: string
    
    --[[
      "heavyarmor"
    ]]
    heavyArmor: string
    
    --[[
      "illusion"
    ]]
    illusion: string
    
    --[[
      "lightarmor"
    ]]
    lightArmor: string
    
    --[[
      "longblade"
    ]]
    longBlade: string
    
    --[[
      "marksman"
    ]]
    marksman: string
    
    --[[
      "mediumarmor"
    ]]
    mediumArmor: string
    
    --[[
      "mercantile"
    ]]
    mercantile: string
    
    --[[
      "mysticism"
    ]]
    mysticism: string
    
    --[[
      "restoration"
    ]]
    restoration: string
    
    --[[
      "security"
    ]]
    security: string
    
    --[[
      "shortblade"
    ]]
    shortBlade: string
    
    --[[
      "sneak"
    ]]
    sneak: string
    
    --[[
      "spear"
    ]]
    spear: string
    
    --[[
      "speechcraft"
    ]]
    speechcraft: string
    
    --[[
      "unarmored"
    ]]
    unarmored: string
    
  end
  record CONTROL_SWITCH
    --[[
      Ability to move
    ]]
    Controls: types.ControlSwitch
    
    --[[
      Ability to attack
    ]]
    Fighting: types.ControlSwitch
    
    --[[
      Ability to jump
    ]]
    Jumping: types.ControlSwitch
    
    --[[
      Ability to change view direction
    ]]
    Looking: types.ControlSwitch
    
    --[[
      Ability to use magic
    ]]
    Magic: types.ControlSwitch
    
    --[[
      Vanity view if player doesn't touch controls for a long time
    ]]
    VanityMode: types.ControlSwitch
    
    --[[
      Ability to toggle 1st/3rd person view
    ]]
    ViewMode: types.ControlSwitch
    
  end
  record ClothingRecord
    --[[
      The enchantment ID of this clothing (can be empty)
    ]]
    enchant: string
    
    enchantCapacity: number
    
    --[[
      VFS path to the icon
    ]]
    icon: string
    
    --[[
      Record id
    ]]
    id: string
    
    --[[
      VFS path to the model
    ]]
    model: string
    
    --[[
      MWScript on this clothing (can be empty)
    ]]
    mwscript: string
    
    --[[
      Name of the clothing
    ]]
    name: string
    
    --[[
      See @{#Clothing.TYPE}
    ]]
    type: number
    
    value: number
    
    weight: number
    
  end
  --[[
    Clothing.TYPE
  ]]
  record ClothingTYPE
    Amulet: number
    
    Belt: number
    
    LGlove: number
    
    Pants: number
    
    RGlove: number
    
    Ring: number
    
    Robe: number
    
    Shirt: number
    
    Shoes: number
    
    Skirt: number
    
  end
  record ContainerRecord
    --[[
      Record id
    ]]
    id: string
    
    --[[
      VFS path to the model
    ]]
    model: string
    
    --[[
      MWScript on this container (can be empty)
    ]]
    mwscript: string
    
    --[[
      Human-readable name
    ]]
    name: string
    
    --[[
      capacity of this container
    ]]
    weight: number
    
  end
  --[[
    String id of a @{#CONTROL_SWITCH}
  ]]
  record ControlSwitch
  end
  record CreatureLevelledListRecord
    --[[
      Calculate from all levels <= player level, not just the closest below player
    ]]
    calculateFromAllLevels: boolean
    
    --[[
      Chance this list won't spawn anything [0-1]
    ]]
    chanceNone: number
    
    creatures: { types.LevelledListItem }
    
    --[[
      Picks a random id from the levelled list.
    ]]
    getRandomId: function(
      listRecord: types.CreatureLevelledListRecord, --[[The list]]
      MaxLvl: number
    ): string
    
    --[[
      Record id
    ]]
    id: string
    
  end
  record CreatureRecord
    --[[
      Record id of a base creature, which was modified to create this one
    ]]
    baseCreature: string
    
    --[[
      The base barter gold of the creature
    ]]
    baseGold: number
    
    --[[
      The record ID of the creature
    ]]
    id: string
    
    --[[
      VFS path to the creature's model
    ]]
    model: string
    
    mwscript: string
    
    name: string
    
    --[[
      The services of the creature, in a table. Value is if the service is provided or not, and they are indexed by: Spells, Spellmaking, Enchanting, Training, Repair, Barter, Weapon, Armor, Clothing, Books, Ingredients, Picks, Probes, Lights, Apparatus, RepairItems, Misc, Potions, MagicItems, Travel.
    ]]
    servicesOffered: { string }
    
    --[[
      The soul value of the creature record
    ]]
    soulValue: number
    
    --[[
      The @{#Creature.TYPE} of the creature
    ]]
    type: number
    
  end
  --[[
    Creature.TYPE
  ]]
  record CreatureTYPE
    Creatures: number
    
    Daedra: number
    
    Humanoid: number
    
    Undead: number
    
  end
  record DoorRecord
    --[[
      VFS path to the sound of closing
    ]]
    closeSound: string
    
    --[[
      Record id
    ]]
    id: string
    
    --[[
      VFS path to the model
    ]]
    model: string
    
    --[[
      MWScript on this door (can be empty)
    ]]
    mwscript: string
    
    --[[
      Human-readable name
    ]]
    name: string
    
    --[[
      VFS path to the sound of opening
    ]]
    openSound: string
    
  end
  record DynamicStat
    base: number
    
    current: number
    
    modifier: number
    
  end
  record DynamicStats
    --[[
      Fatigue (returns @{#DynamicStat})
    ]]
    fatigue: function(
      actor: openmw_core.GameObject
    ): types.DynamicStat
    
    --[[
      Health (returns @{#DynamicStat})
    ]]
    health: function(
      actor: openmw_core.GameObject
    ): types.DynamicStat
    
    --[[
      Magicka (returns @{#DynamicStat})
    ]]
    magicka: function(
      actor: openmw_core.GameObject
    ): types.DynamicStat
    
  end
  record EQUIPMENT_SLOT
    Ammunition: number
    
    Amulet: number
    
    Belt: number
    
    Boots: number
    
    CarriedLeft: number
    
    CarriedRight: number
    
    Cuirass: number
    
    Greaves: number
    
    Helmet: number
    
    LeftGauntlet: number
    
    LeftPauldron: number
    
    LeftRing: number
    
    Pants: number
    
    RightGauntlet: number
    
    RightPauldron: number
    
    RightRing: number
    
    Robe: number
    
    Shirt: number
    
    Skirt: number
    
  end
  record ESM4DoorRecord
    --[[
      Record id
    ]]
    id: string
    
    --[[
      VFS path to the model
    ]]
    model: string
    
    --[[
      Human-readable name
    ]]
    name: string
    
  end
  record ESM4TerminalRecord
    --[[
      Human-readable ID
    ]]
    editorId: string
    
    --[[
      Record id (Form ID)
    ]]
    id: string
    
    --[[
      VFS path to the model
    ]]
    model: string
    
    --[[
      Human-readable name
    ]]
    name: string
    
    --[[
      Result text of the terminal record
    ]]
    resultText: string
    
    --[[
      Text body of the terminal record
    ]]
    text: string
    
  end
  --[[
    Map from values of @{#EQUIPMENT_SLOT} to items @{openmw.core#GameObject}s
  ]]
  record EquipmentTable
    metamethod __index: function(self: types.EquipmentTable, index: number): openmw_core.GameObject
  end
  record IngredientRecord
    --[[
      The effects (@{#list<openmw.core#MagicEffectWithParams>}) of the ingredient
    ]]
    effects: { openmw_core.MagicEffectWithParams }
    
    --[[
      VFS path to the icon
    ]]
    icon: string
    
    --[[
      Record id
    ]]
    id: string
    
    --[[
      VFS path to the model
    ]]
    model: string
    
    --[[
      MWScript on this potion (can be empty)
    ]]
    mwscript: string
    
    --[[
      Human-readable name
    ]]
    name: string
    
    value: number
    
    weight: number
    
  end
  record LevelStat
    --[[
      The actor's current level.
    ]]
    current: number
    
    --[[
      The NPC's level progress (read-only.)
    ]]
    progress: number
    
  end
  record LevelledListItem
    --[[
      Item id
    ]]
    id: string
    
    --[[
      The minimum player level at which this item can occur
    ]]
    level: number
    
  end
  record LightRecord
    color: number
    
    duration: number
    
    --[[
      VFS path to the icon
    ]]
    icon: string
    
    --[[
      Record id
    ]]
    id: string
    
    isCarriable: boolean
    
    --[[
      VFS path to the model
    ]]
    model: string
    
    --[[
      MWScript on this light (can be empty)
    ]]
    mwscript: string
    
    --[[
      Human-readable name
    ]]
    name: string
    
    radius: number
    
    --[[
      VFS path to the sound
    ]]
    sound: string
    
    value: number
    
    weight: number
    
  end
  record LockpickRecord
    --[[
      VFS path to the icon
    ]]
    icon: string
    
    --[[
      The record ID of the lockpick
    ]]
    id: string
    
    --[[
      The maximum number of uses of this lockpick
    ]]
    maxCondition: number
    
    --[[
      VFS path to the model
    ]]
    model: string
    
    --[[
      MWScript on this lockpick (can be empty)
    ]]
    mwscript: string
    
    --[[
      The name of the lockpick
    ]]
    name: string
    
    --[[
      The quality of the lockpick
    ]]
    quality: number
    
    value: number
    
    weight: number
    
  end
  record MiscellaneousRecord
    --[[
      VFS path to the icon
    ]]
    icon: string
    
    --[[
      The record ID of the miscellaneous item
    ]]
    id: string
    
    isKey: boolean
    
    --[[
      VFS path to the model
    ]]
    model: string
    
    --[[
      MWScript on this miscellaneous item (can be empty)
    ]]
    mwscript: string
    
    --[[
      The name of the miscellaneous item
    ]]
    name: string
    
    value: number
    
    weight: number
    
  end
  record NpcRecord
    --[[
      NPC's starting disposition
    ]]
    baseDisposition: number
    
    --[[
      The base barter gold of the NPC
    ]]
    baseGold: number
    
    --[[
      Name of the NPC's class (e. g. Acrobat)
    ]]
    class: string
    
    --[[
      Path to the hair body part model
    ]]
    hair: string
    
    --[[
      Path to the head body part model
    ]]
    head: string
    
    --[[
      The record ID of the NPC
    ]]
    id: string
    
    --[[
      The gender setting of the NPC
    ]]
    isMale: types.bool
    
    --[[
      MWScript that is attached to this NPC
    ]]
    mwscript: string
    
    name: string
    
    race: string
    
    --[[
      The services of the NPC, in a table. Value is if the service is provided or not, and they are indexed by: Spells, Spellmaking, Enchanting, Training, Repair, Barter, Weapon, Armor, Clothing, Books, Ingredients, Picks, Probes, Lights, Apparatus, RepairItems, Misc, Potions, MagicItems, Travel.
    ]]
    servicesOffered: { string }
    
  end
  record NpcStats
    skills: types.SkillStats
    
  end
  record PlayerQuest
    --[[
      Sets the quest stage for the given quest, on the given player, and adds the entry to the journal, if there is an entry at the specified stage.
      Can only be used in global or player scripts.
    ]]
    addJournalEntry: function(
      self: types.PlayerQuest,
      stage: number, --[[Quest stage]]
      actor: openmw_core.GameObject
    )
    
    --[[
      Whether the quest is finished (global and player scripts can change it).
    ]]
    finished: types.bool
    
    --[[
      The quest id.
    ]]
    id: string
    
    --[[
      The quest stage (global and player scripts can change it). Changing the stage starts the quest if it wasn't started.
    ]]
    stage: number
    
    --[[
      Whether the quest is started.
    ]]
    started: types.bool
    
  end
  record PotionRecord
    --[[
      The effects (@{#list<openmw.core#MagicEffectWithParams>}) of the potion
    ]]
    effects: { openmw_core.MagicEffectWithParams }
    
    --[[
      VFS path to the icon
    ]]
    icon: string
    
    --[[
      Record id
    ]]
    id: string
    
    --[[
      VFS path to the model
    ]]
    model: string
    
    --[[
      MWScript on this potion (can be empty)
    ]]
    mwscript: string
    
    --[[
      Human-readable name
    ]]
    name: string
    
    value: number
    
    weight: number
    
  end
  record ProbeRecord
    --[[
      VFS path to the icon
    ]]
    icon: string
    
    --[[
      The record ID of the probe
    ]]
    id: string
    
    --[[
      The maximum number of uses of this probe
    ]]
    maxCondition: number
    
    --[[
      VFS path to the model
    ]]
    model: string
    
    --[[
      MWScript on this probe (can be empty)
    ]]
    mwscript: string
    
    --[[
      The name of the probe
    ]]
    name: string
    
    --[[
      The quality of the probe
    ]]
    quality: number
    
    value: number
    
    weight: number
    
  end
  record RepairRecord
    --[[
      VFS path to the icon
    ]]
    icon: string
    
    --[[
      The record ID of the repair tool
    ]]
    id: string
    
    --[[
      The maximum number of uses of this repair tool
    ]]
    maxCondition: number
    
    --[[
      VFS path to the model
    ]]
    model: string
    
    --[[
      MWScript on this repair tool (can be empty)
    ]]
    mwscript: string
    
    --[[
      The name of the repair tool
    ]]
    name: string
    
    --[[
      The quality of the repair tool
    ]]
    quality: number
    
    value: number
    
    weight: number
    
  end
  record STANCE
    --[[
      Default stance
    ]]
    Nothing: number
    
    --[[
      Magic stance
    ]]
    Spell: number
    
    --[[
      Weapon stance
    ]]
    Weapon: number
    
  end
  record SkillStat
    --[[
      The NPC's base skill value.
    ]]
    base: number
    
    --[[
      The amount the skill has been damaged.
    ]]
    damage: number
    
    --[[
      The NPC's current skill value (read-only.)
    ]]
    modified: number
    
    --[[
      The skill's modifier.
    ]]
    modifier: number
    
    --[[
      [0-1] The NPC's skill progress.
    ]]
    progress: number
    
  end
  record SkillStats
    --[[
      Acrobatics (returns @{#SkillStat})
    ]]
    acrobatics: function(
      actor: openmw_core.GameObject
    ): types.SkillStat
    
    --[[
      Alchemy (returns @{#SkillStat})
    ]]
    alchemy: function(
      actor: openmw_core.GameObject
    ): types.SkillStat
    
    --[[
      Alteration (returns @{#SkillStat})
    ]]
    alteration: function(
      actor: openmw_core.GameObject
    ): types.SkillStat
    
    --[[
      Armorer (returns @{#SkillStat})
    ]]
    armorer: function(
      actor: openmw_core.GameObject
    ): types.SkillStat
    
    --[[
      Athletics (returns @{#SkillStat})
    ]]
    athletics: function(
      actor: openmw_core.GameObject
    ): types.SkillStat
    
    --[[
      Axe (returns @{#SkillStat})
    ]]
    axe: function(
      actor: openmw_core.GameObject
    ): types.SkillStat
    
    --[[
      Block (returns @{#SkillStat})
    ]]
    block: function(
      actor: openmw_core.GameObject
    ): types.SkillStat
    
    --[[
      Blunt Weapon (returns @{#SkillStat})
    ]]
    bluntweapon: function(
      actor: openmw_core.GameObject
    ): types.SkillStat
    
    --[[
      Conjuration (returns @{#SkillStat})
    ]]
    conjuration: function(
      actor: openmw_core.GameObject
    ): types.SkillStat
    
    --[[
      Destruction (returns @{#SkillStat})
    ]]
    destruction: function(
      actor: openmw_core.GameObject
    ): types.SkillStat
    
    --[[
      Enchant (returns @{#SkillStat})
    ]]
    enchant: function(
      actor: openmw_core.GameObject
    ): types.SkillStat
    
    --[[
      Hand To Hand (returns @{#SkillStat})
    ]]
    handtohand: function(
      actor: openmw_core.GameObject
    ): types.SkillStat
    
    --[[
      Heavy Armor (returns @{#SkillStat})
    ]]
    heavyarmor: function(
      actor: openmw_core.GameObject
    ): types.SkillStat
    
    --[[
      Illusion (returns @{#SkillStat})
    ]]
    illusion: function(
      actor: openmw_core.GameObject
    ): types.SkillStat
    
    --[[
      Light Armor (returns @{#SkillStat})
    ]]
    lightarmor: function(
      actor: openmw_core.GameObject
    ): types.SkillStat
    
    --[[
      Long Blade (returns @{#SkillStat})
    ]]
    longblade: function(
      actor: openmw_core.GameObject
    ): types.SkillStat
    
    --[[
      Marksman (returns @{#SkillStat})
    ]]
    marksman: function(
      actor: openmw_core.GameObject
    ): types.SkillStat
    
    --[[
      Medium Armor (returns @{#SkillStat})
    ]]
    mediumarmor: function(
      actor: openmw_core.GameObject
    ): types.SkillStat
    
    --[[
      Mercantile (returns @{#SkillStat})
    ]]
    mercantile: function(
      actor: openmw_core.GameObject
    ): types.SkillStat
    
    --[[
      Mysticism (returns @{#SkillStat})
    ]]
    mysticism: function(
      actor: openmw_core.GameObject
    ): types.SkillStat
    
    --[[
      Restoration (returns @{#SkillStat})
    ]]
    restoration: function(
      actor: openmw_core.GameObject
    ): types.SkillStat
    
    --[[
      Security (returns @{#SkillStat})
    ]]
    security: function(
      actor: openmw_core.GameObject
    ): types.SkillStat
    
    --[[
      Short Blade (returns @{#SkillStat})
    ]]
    shortblade: function(
      actor: openmw_core.GameObject
    ): types.SkillStat
    
    --[[
      Sneak (returns @{#SkillStat})
    ]]
    sneak: function(
      actor: openmw_core.GameObject
    ): types.SkillStat
    
    --[[
      Spear (returns @{#SkillStat})
    ]]
    spear: function(
      actor: openmw_core.GameObject
    ): types.SkillStat
    
    --[[
      Speechcraft (returns @{#SkillStat})
    ]]
    speechcraft: function(
      actor: openmw_core.GameObject
    ): types.SkillStat
    
    --[[
      Unarmored (returns @{#SkillStat})
    ]]
    unarmored: function(
      actor: openmw_core.GameObject
    ): types.SkillStat
    
  end
  record StaticRecord
    --[[
      Record id
    ]]
    id: string
    
    --[[
      VFS path to the model
    ]]
    model: string
    
  end
  record WeaponRecord
    chopMaxDamage: number
    
    chopMinDamage: number
    
    enchant: string
    
    enchantCapacity: number
    
    health: number
    
    --[[
      VFS path to the icon
    ]]
    icon: string
    
    --[[
      Record id
    ]]
    id: string
    
    isMagical: boolean
    
    isSilver: boolean
    
    --[[
      VFS path to the model
    ]]
    model: string
    
    --[[
      MWScript on this weapon (can be empty)
    ]]
    mwscript: string
    
    --[[
      Human-readable name
    ]]
    name: string
    
    reach: number
    
    slashMaxDamage: number
    
    slashMinDamage: number
    
    speed: number
    
    thrustMaxDamage: number
    
    thrustMinDamage: number
    
    --[[
      See @{#Weapon.TYPE}
    ]]
    type: number
    
    value: number
    
    weight: number
    
  end
  --[[
    Weapon.TYPE
  ]]
  record WeaponTYPE
    Arrow: number
    
    AxeOneHand: number
    
    AxeTwoHand: number
    
    BluntOneHand: number
    
    BluntTwoClose: number
    
    BluntTwoWide: number
    
    Bolt: number
    
    LongBladeOneHand: number
    
    LongBladeTwoHand: number
    
    MarksmanBow: number
    
    MarksmanCrossbow: number
    
    MarksmanThrown: number
    
    ShortBladeOneHand: number
    
    SpearTwoWide: number
    
  end
  record bool
  end
end
return types