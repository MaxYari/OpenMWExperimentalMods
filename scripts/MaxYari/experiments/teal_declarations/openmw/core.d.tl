--[[
  `openmw.core` defines functions and types that are available in both local
  and global scripts.
  local core = require('openmw.core')
]]

local openmw_util = require("openmw.util")
--[[
  Functions working with the list of currently loaded content files.
]]
global record ContentFiles
  --[[
    Check if the content file with given name present in the load order.
  ]]
  has: function(
    contentFile: string
  ): boolean
  
  --[[
    Return the index of a specific content file in the load order (or `nil` if there is no such content file).
  ]]
  indexOf: function(
    contentFile: string
  ): number
  
  --[[
    The current load order (list of content file names).
  ]]
  list: { string }
  
end
global record Magic
  --[[
    Possible @{#MagicEffectId} values
  ]]
  EFFECT_TYPE: core.MagicEffectId
  
  --[[
    Possible @{#EnchantmentType} values
  ]]
  ENCHANTMENT_TYPE: core.EnchantmentType
  
  --[[
    Possible @{#SpellRange} values
  ]]
  RANGE: core.SpellRange
  
  --[[
    Possible @{#SpellType} values
  ]]
  SPELL_TYPE: core.SpellType
  
  --[[
    Map from @{#MagicEffectId} to @{#MagicEffect}
    -- Print all harmful effects
    for _, effect in pairs(core.magic.effects) do
        if effect.harmful then
            print(effect.name)
        end
    end
  ]]
  effects: { any: core.MagicEffect }
  
  --[[
    List of all @{#Enchantment}s.
    local enchantment = core.magic.enchantments['marara's boon']  -- get by id
  ]]
  enchantments: { core.Enchantment }
  
  --[[
    List of all @{#Spell}s.
    local spell = core.magic.spells['thunder fist']  -- get by id
  ]]
  spells: { core.Spell }
  
end
global record Sound
  --[[
    Checks if sound system is enabled (any functions to play sounds are no-ops when it is disabled).
    It can not be enabled or disabled during runtime.
    local enabled = core.sound.isEnabled();
  ]]
  isEnabled: function(): boolean
  
  --[[
    Check if animated voiceover is playing
    -- check voice for given object
    local isActive = isSayActive(object);
  ]]
  isSayActive: function(
    object: core.GameObject
  ): boolean
  
  --[[
    Check if sound file is playing on given object
    local isPlaying = core.sound.isSoundFilePlaying("Sound\\test.mp3", object);
  ]]
  isSoundFilePlaying: function(
    fileName: string, --[[Path to sound file in VFS]]
    object: core.GameObject
  ): boolean
  
  --[[
    Check if sound is playing on given object
    local isPlaying = core.sound.isSoundPlaying("shock bolt", object);
  ]]
  isSoundPlaying: function(
    soundId: string, --[[ID of Sound record to check]]
    object: core.GameObject
  ): boolean
  
  --[[
    Play a 3D sound, attached to object
    local params = {
       timeOffset=0.1
       volume=0.3,
       loop=false,
       pitch=1.0
    };
    core.sound.playSound3d("shock bolt", object, params)
  ]]
  playSound3d: function(
    soundId: string, --[[ID of Sound record to play]]
    object: core.GameObject, --[[Object to which we attach the sound]]
    options: table
  )
  
  --[[
    Play a 3D sound file, attached to object
    local params = {
       timeOffset=0.1
       volume=0.3,
       loop=false,
       pitch=1.0
    };
    core.sound.playSoundFile3d("Sound\\test.mp3", object, params)
  ]]
  playSoundFile3d: function(
    fileName: string, --[[Path to sound file in VFS]]
    object: core.GameObject, --[[Object to which we attach the sound]]
    options: table
  )
  
  --[[
    Play an animated voiceover.
    Has two overloads:
    
      * With an "object" argument: play sound for given object, with speaking animation if possible
      * Without an "object" argument: play sound globally, without object
    -- play voiceover for object and print messagebox
    core.sound.say("Sound\\Vo\\Misc\\voice.mp3", object, "Subtitle text")
  ]]
  say: function(
    fileName: string, --[[Path to sound file in VFS]]
    object: core.GameObject, --[[Object on which we want to play an animated voiceover (optional)]]
    text: string
  )
  
  --[[
    List of all @{#SoundRecord}s.
    local sound = core.sound.sounds['Ashstorm']  -- get by id
  ]]
  sounds: { core.SoundRecord }
  
  --[[
    Stop animated voiceover
    -- stop voice for given object
    core.sound.stopSay(object);
  ]]
  stopSay: function(
    fileName: string, --[[Path to sound file in VFS]]
    object: core.GameObject
  )
  
  --[[
    Stop a 3D sound, attached to object
    core.sound.stopSound("shock bolt", object);
  ]]
  stopSound3d: function(
    soundId: string, --[[ID of Sound record to stop]]
    object: core.GameObject
  )
  
  --[[
    Stop a 3D sound file, attached to object
    core.sound.stopSoundFile("Sound\\test.mp3", object);
  ]]
  stopSoundFile3d: function(
    fileName: string, --[[Path to sound file in VFS]]
    object: core.GameObject
  )
  
end
global record Stats
  --[[
    @{#Attribute} functions
  ]]
  Attribute: core.Attribute
  
  --[[
    @{#Skill} functions
  ]]
  Skill: core.Skill
  
end
local record core
  --[[
    The revision of OpenMW Lua API.
    It is an integer that is incremented every time the API is changed. See the actual value at the top of the page.
  ]]
  API_REVISION: number
  
  --[[
    @{#ContentFiles}: functions working with the list of currently loaded content files.
  ]]
  contentFiles: ContentFiles
  
  --[[
    A read-only list of all @{#FactionRecord}s in the world database.
  ]]
  factions: { core.FactionRecord }
  
  --[[
    Construct FormId string from content file name and the index in the file.
    In ESM3 games (e.g. Morrowind) FormIds are used to reference game objects.
    In ESM4 games (e.g. Skyrim) FormIds are used both for game objects and as record ids.
    if obj.recordId == core.getFormId('Skyrim.esm', 0x4d7da) then ... end
  ]]
  getFormId: function(
    contentFile: string,
    index: number
  ): string
  
  --[[
    Get a GMST setting from content files.
  ]]
  getGMST: function(
    setting: string
  ): any
  
  --[[
    Game time in seconds.
  ]]
  getGameTime: function(): number
  
  --[[
    The scale of game time relative to simulation time.
  ]]
  getGameTimeScale: function(): number
  
  --[[
    Real time in seconds; starting point is not fixed (can be time since last reboot), use only for measuring intervals.
    For Unix time use `os.time()`.
  ]]
  getRealTime: function(): number
  
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
    Return l10n formatting function for the given context.
    Localisation files (containing the message names and translations) should be stored in
    VFS as files of the form `l10n/<ContextName>/<Locale>.yaml`.
    
    See [Localisation](../modding/localisation.html) for details of the localisation file structure.
    
    When calling the l10n formatting function, if no localisation can be found for any of the requested locales then
    the message key will be returned instead (and formatted, if possible).
    This makes it possible to use the source strings as message identifiers.
    
    If you do not use the source string as a message identifier you should instead make certain to include
    a fallback locale with a complete set of messages.
    
    # DataFiles/l10n/MyMod/en.yaml
    good_morning: 'Good morning.'
    you_have_arrows: |-
      {count, plural,
        one {You have one arrow.}
        other {You have {count} arrows.}
      }
  ]]
  l10n: function(
    context: string, --[[l10n context; recommended to use the name of the mod.
                   This must match the <ContextName> directory in the VFS which stores the localisation files.]]
    fallbackLocale: string
  ): function
  
  --[[
    @{#Magic}: spells and spell effects
  ]]
  magic: Magic
  
  --[[
    Terminates the game and quits to the OS.
    Should be used only for testing purposes.
  ]]
  quit: function()
  
  --[[
    Send an event to global scripts.
  ]]
  sendGlobalEvent: function(
    eventName: string,
    eventData: any
  )
  
  --[[
    @{#Sound}: Sounds and Speech
  ]]
  sound: Sound
  
  --[[
    @{#Stats}: stats
  ]]
  stats: Stats
  
  record ActiveEffect
    --[[
      Optional attribute ID
    ]]
    affectedAttribute: string
    
    --[[
      Optional skill ID
    ]]
    affectedSkill: string
    
    --[[
      Effect id string
    ]]
    id: string
    
    --[[
      current magnitude of the effect. Will be set to 0 when effect is removed or expires.
    ]]
    magnitude: number
    
    magnitudeBase: number
    
    magnitudeModifier: number
    
    --[[
      Localized name of the effect
    ]]
    name: string
    
  end
  record ActiveSpell
    --[[
      The caster object, or nil if the spell has no defined caster
    ]]
    caster: core.GameObject
    
    --[[
      The active effects (@{#ActiveSpellEffect}) of this spell.
    ]]
    effects: { core.ActiveSpellEffect }
    
    --[[
      Record id of the spell or item used to cast the spell
    ]]
    id: string
    
    --[[
      The enchanted item used to cast the spell, or nil if the spell was not cast from an enchanted item. Note that if the spell was cast for a single-use enchantment such as a scroll, this will be nil.
    ]]
    item: core.GameObject
    
    --[[
      The spell or item display name
    ]]
    name: string
    
  end
  record ActiveSpellEffect
    --[[
      Optional attribute ID
    ]]
    affectedAttribute: string
    
    --[[
      Optional skill ID
    ]]
    affectedSkill: string
    
    --[[
      Total duration in seconds of this spell effect, should not be confused with remaining duration. Or nil if the effect is not temporary.
    ]]
    duration: number
    
    --[[
      Remaining duration in seconds of this spell effect, or nil if the effect is not temporary.
    ]]
    durationLeft: number
    
    --[[
      Magic effect id
    ]]
    id: string
    
    --[[
      The magnitude of the effect in the current frame. This will be a new random number between minMagnitude and maxMagnitude every frame. Or nil if the effect has no magnitude.
    ]]
    magnitudeThisFrame: number
    
    --[[
      The maximum magnitude of this effect, or nil if the effect has no magnitude.
    ]]
    maxMagnitude: number
    
    --[[
      The minimum magnitude of this effect, or nil if the effect has no magnitude.
    ]]
    minMagnitude: number
    
    --[[
      Localized name of the effect
    ]]
    name: string
    
  end
  --[[
    `core.stats.Attribute`
  ]]
  record Attribute
    --[[
      Returns a read-only @{#AttributeRecord}
    ]]
    record: function(
      recordId: string
    ): core.AttributeRecord
    
    --[[
      A read-only list of all @{#AttributeRecord}s in the world database.
    ]]
    records: { core.AttributeRecord }
    
  end
  record AttributeRecord
    --[[
      Human-readable description
    ]]
    description: string
    
    --[[
      VFS path to the icon
    ]]
    icon: string
    
    --[[
      Record id
    ]]
    id: string
    
    --[[
      Human-readable name
    ]]
    name: string
    
  end
  --[[
    A cell of the game world.
  ]]
  record Cell
    --[[
      Get all objects of given type from the cell; Only available from global scripts.
      local type = require('openmw.types')
      local all = cell:getAll()
      local weapons = cell:getAll(types.Weapon)
    ]]
    getAll: function(
      self: core.Cell,
      type: any
    ): core.ObjectList
    
    --[[
      Index of the cell by X (only for exteriors).
    ]]
    gridX: number
    
    --[[
      Index of the cell by Y (only for exteriors).
    ]]
    gridY: number
    
    --[[
      True if in this cell sky should be rendered.
    ]]
    hasSky: boolean
    
    --[[
      Returns true if the cell has given tag.
    ]]
    hasTag: function(
      self: core.Cell,
      tag: string
    ): boolean
    
    --[[
      True if the cell contains water.
    ]]
    hasWater: boolean
    
    --[[
      Whether the cell is an exterior cell. "Exterior" means grid of cells where the player can seamless walk from one cell to another without teleports. QuasiExterior (interior with sky) is not an exterior.
    ]]
    isExterior: boolean
    
    --[[
      Returns true either if the cell contains the object or if the cell is an exterior and the object is also in an exterior.
      if obj1.cell:isInSameSpace(obj2) then
          dist = (obj1.position - obj2.position):length()
      else
          -- the distance can't be calculated because the coordinates are in different spaces
      end
    ]]
    isInSameSpace: function(
      self: core.Cell,
      object: core.GameObject
    ): boolean
    
    --[[
      (DEPRECATED, use `hasTag("QuasiExterior")`) Whether the cell is a quasi exterior (like interior but with the sky and the wheather).
    ]]
    isQuasiExterior: boolean
    
    --[[
      Name of the cell (can be empty string).
    ]]
    name: string
    
    --[[
      Region of the cell.
    ]]
    region: string
    
    --[[
      Id of the world space.
    ]]
    worldSpaceId: string
    
  end
  --[[
    -- Getting the enchantment of an arbitrary item, if it has one
    local function getRecord(item)
        if item.type and item.type.record then
            return item.type.record(item)
        end
        return nil
    end
    local function getEnchantment(item)
        local record = getRecord(item)
        if record and record.enchant then
            return core.magic.enchantments[record.enchant]
        end
        return nil
    end
  ]]
  record Enchantment
    --[[
      If set, the casting cost should be computer rather than reading the cost field
    ]]
    autocalcFlag: number
    
    --[[
      Charge capacity. Should not be confused with current charge.
    ]]
    charge: number
    
    cost: number
    
    --[[
      The effects (@{#MagicEffectWithParams}) of the enchantment
    ]]
    effects: { core.MagicEffectWithParams }
    
    --[[
      Enchantment id
    ]]
    id: string
    
    --[[
      @{#EnchantmentType}
    ]]
    type: number
    
  end
  --[[
    `core.magic.ENCHANTMENT_TYPE`
  ]]
  record EnchantmentType
    --[[
      Enchantment is cast on strike, if there is enough charge.
    ]]
    CastOnStrike: number
    
    --[[
      Enchantment is cast when used, if there is enough charge.
    ]]
    CastOnUse: number
    
    --[[
      Enchantment can be cast once, destroying the enchanted item.
    ]]
    CastOnce: number
    
    --[[
      Enchantment is always active when equipped.
    ]]
    ConstantEffect: number
    
  end
  --[[
    Faction rank data record
  ]]
  record FactionRank
    --[[
      Attributes values required to get this rank.
    ]]
    attributeValues: { number }
    
    --[[
      Reaction of faction members if player is in this faction.
    ]]
    factionReaction: number
    
    --[[
      Secondary skill value required to get this rank.
    ]]
    favouredSkillValue: number
    
    --[[
      Faction name Rank display name
    ]]
    name: string
    
    --[[
      Primary skill value required to get this rank.
    ]]
    primarySkillValue: number
    
  end
  --[[
    Faction data record
  ]]
  record FactionRecord
    --[[
      A read-only list containing IDs of attributes to advance ranks in the faction.
    ]]
    attributes: { string }
    
    --[[
      Faction id
    ]]
    id: string
    
    --[[
      Faction name
    ]]
    name: string
    
    --[[
      A read-only list containing data for all ranks in the faction, in order.
    ]]
    ranks: { core.FactionRank }
    
    --[[
      A read-only map containing reactions of other factions to this faction.
    ]]
    reactions: { any: number }
    
    --[[
      A read-only list containing IDs of skills to advance ranks in the faction.
    ]]
    skills: { string }
    
  end
  --[[
    Any object that exists in the game world and has a specific location.
    Player, actors, items, and statics are game objects.
  ]]
  record GameObject
    userdata
    --[[
      Activate the object.
      local self = require('openmw.self')
      object:activateBy(self)
    ]]
    activateBy: function(
      self: core.GameObject,
      actor: core.GameObject
    )
    
    --[[
      Add new local script to the object.
      Can be called only from a global script. Script should be specified in a content
      file (omwgame/omwaddon/omwscripts) with a CUSTOM flag. Scripts can not be attached to Statics.
    ]]
    addScript: function(
      self: core.GameObject,
      scriptPath: string, --[[Path to the script in OpenMW virtual filesystem.]]
      initData: table
    )
    
    --[[
      The cell where the object currently is. During loading a game and for objects in an inventory or a container `cell` is nil.
    ]]
    cell: core.Cell
    
    --[[
      Lower cased file name of the content file that defines this object; nil for dynamically created objects.
    ]]
    contentFile: string
    
    --[[
      Count (>1 means a stack of objects).
    ]]
    count: number
    
    --[[
      Whether the object is enabled or disabled. Global scripts can set the value. Items in containers or inventories can't be disabled.
    ]]
    enabled: boolean
    
    --[[
      The axis aligned bounding box in local coordinates.
    ]]
    getBoundingBox: function(
      self: core.GameObject
    ): openmw_util.Box
    
    --[[
      Global Variable associated with this object(read only).
    ]]
    globalVariable: string
    
    --[[
      Whether a script with given path is attached to this object.
      Can be called only from a global script.
    ]]
    hasScript: function(
      self: core.GameObject,
      scriptPath: string
    ): boolean
    
    --[[
      A unique id of this object (not record id), can be used as a key in a table.
    ]]
    id: string
    
    --[[
      Does the object still exist and is available.
      Returns true if the object exists and loaded, and false otherwise. If false, then every
      access to the object will raise an error.
    ]]
    isValid: function(
      self: core.GameObject
    ): boolean
    
    --[[
      Moves object into a container or an inventory.
      Enables if was disabled.
      Can be called only from a global script.
      item:moveInto(types.Actor.inventory(actor))
    ]]
    moveInto: function(
      self: core.GameObject,
      dest: any
    )
    
    --[[
      Faction who owns the object (nil if missing). Global and self scripts can set the value.
    ]]
    ownerFactionId: string
    
    --[[
      Rank required to be allowed to pick up the object. Global and self scripts can set the value.
    ]]
    ownerFactionRank: number
    
    --[[
      NPC who owns the object (nil if missing). Global and self scripts can set the value.
    ]]
    ownerRecordId: string
    
    --[[
      Container or actor that contains (or has in inventory) this object. It is nil if the object is in a cell.
    ]]
    parentContainer: core.GameObject
    
    --[[
      Object position.
    ]]
    position: openmw_util.Vector3
    
    --[[
      Returns record ID of the object in lowercase.
    ]]
    recordId: string
    
    --[[
      Removes an object or reduces a stack of objects.
      Can be called only from a global script.
    ]]
    remove: function(
      self: core.GameObject,
      count: number
    )
    
    --[[
      Removes script that was attached by `addScript`
      Can be called only from a global script.
    ]]
    removeScript: function(
      self: core.GameObject,
      scriptPath: string
    )
    
    --[[
      Object rotation.
    ]]
    rotation: openmw_util.Transform
    
    --[[
      Object scale.
    ]]
    scale: number
    
    --[[
      Send local event to the object.
    ]]
    sendEvent: function(
      self: core.GameObject,
      eventName: string,
      eventData: any
    )
    
    --[[
      Sets the object's scale.
      Can be called only from a global script.
    ]]
    setScale: function(
      self: core.GameObject,
      scale: number
    )
    
    --[[
      Splits a stack of items.
      Original stack is reduced by `count`. Returns a new stack with `count` items.
      Can be called only from a global script.
      -- take 50 coins from `money` and put to the container `cont`
      money:split(50):moveInto(types.Container.content(cont))
    ]]
    split: function(
      self: core.GameObject,
      count: number
    )
    
    --[[
      The object original position
    ]]
    startingPosition: openmw_util.Vector3
    
    --[[
      The object original rotation
    ]]
    startingRotation: openmw_util.Transform
    
    --[[
      Moves object to given cell and position.
      Can be called only from a global script.
      The effect is not immediate: the position will be updated only in the next
      frame. Can be called only from a global script. Enables object if it was disabled.
      Can be used to move objects from an inventory or a container to the world.
    ]]
    teleport: function(
      self: core.GameObject,
      cellOrName: any, --[[A cell to define the destination worldspace; can be either #Cell, or cell name, or an empty string (empty string means the default exterior worldspace).
      If the worldspace has multiple cells (i.e. an exterior), the destination cell is calculated using `position`.]]
      position: openmw_util.Vector3, --[[New position.]]
      options: core.TeleportOptions
    )

    --[[
      Dynamic rigidbody's current position
    ]]
    rigidBodyPosition: openmw_util.Vector3
    
    --[[
      Dynamic rigidbody's current rotation
    ]]
    rigidBodyRotation: openmw_util.Transform

    --[[
      Get velocity of a local point of a dynamic rigidbody
    ]]
    getRigidBodyVelocity: function(self: core.GameObject, offset: openmw_util.Vector3): openmw_util.Vector3

    --[[
      Applies an impulse in a specific `direction` to a rigidbody. Impulse is applied at an `offset` from the object's origin.
    ]]
    applyImpulse: function(object: core.GameObject, direction: openmw_util.Vector3, offset: openmw_util.Vector3)
    
    

    

    --[[
      Type of the object (one of the tables from the package @{openmw.types#types}).
    ]]
    type: any
    
  end

  
  --[[
    Inventory of a player/NPC or a content of a container.
  ]]
  record Inventory
    --[[
      The number of items with given recordId.
    ]]
    countOf: function(
      self: core.Inventory,
      recordId: string
    ): number
    
    --[[
      Get first item with given recordId from the inventory.
      Returns nil if not found.
      inventory:find('gold_001')
    ]]
    find: function(
      self: core.Inventory,
      recordId: string
    ): core.GameObject
    
    --[[
      Get all items with given recordId from the inventory.
      for _, item in ipairs(inventory:findAll('common_shirt_01')) do ... end
    ]]
    findAll: function(
      self: core.Inventory,
      recordId: string
    ): core.ObjectList
    
    --[[
      Get all items of given type from the inventory.
      local types = require('openmw.types')
      local self = require('openmw.self')
      local playerInventory = types.Actor.inventory(self.object)
      local all = playerInventory:getAll()
      local weapons = playerInventory:getAll(types.Weapon)
    ]]
    getAll: function(
      self: core.Inventory,
      type: any
    ): core.ObjectList
    
    --[[
      Checks if the inventory has a resolved item list.
      inventory:isResolved()
    ]]
    isResolved: function(
      self: core.Inventory
    ): boolean
    
    --[[
      Will resolve the inventory, filling it with levelled items if applicable, making its contents permanent.
      Must be used in a global script.
      inventory:resolve()
    ]]
    resolve: function(
      self: core.Inventory
    )
    
  end
  record MagicEffect
    baseCost: number
    
    color: openmw_util.Color
    
    harmful: boolean
    
    --[[
      Effect Icon Path
    ]]
    icon: string
    
    --[[
      Effect ID
    ]]
    id: string
    
    --[[
      Localized name of the effect
    ]]
    name: string
    
    --[[
      Skill ID that is this effect's school
    ]]
    school: string
    
  end
  --[[
    `core.magic.EFFECT_TYPE`
  ]]
  record MagicEffectId
    --[[
      "absorbattribute"
    ]]
    AbsorbAttribute: number
    
    --[[
      "absorbfatigue"
    ]]
    AbsorbFatigue: number
    
    --[[
      "absorbhealth"
    ]]
    AbsorbHealth: number
    
    --[[
      "absorbmagicka"
    ]]
    AbsorbMagicka: number
    
    --[[
      "absorbskill"
    ]]
    AbsorbSkill: number
    
    --[[
      "almsiviintervention"
    ]]
    AlmsiviIntervention: number
    
    --[[
      "blind"
    ]]
    Blind: number
    
    --[[
      "boundbattleaxe"
    ]]
    BoundBattleAxe: number
    
    --[[
      "boundboots"
    ]]
    BoundBoots: number
    
    --[[
      "boundcuirass"
    ]]
    BoundCuirass: number
    
    --[[
      "bounddagger"
    ]]
    BoundDagger: number
    
    --[[
      "boundgloves"
    ]]
    BoundGloves: number
    
    --[[
      "boundhelm"
    ]]
    BoundHelm: number
    
    --[[
      "boundlongbow"
    ]]
    BoundLongbow: number
    
    --[[
      "boundlongsword"
    ]]
    BoundLongsword: number
    
    --[[
      "boundmace"
    ]]
    BoundMace: number
    
    --[[
      "boundshield"
    ]]
    BoundShield: number
    
    --[[
      "boundspear"
    ]]
    BoundSpear: number
    
    --[[
      "burden"
    ]]
    Burden: number
    
    --[[
      "calmcreature"
    ]]
    CalmCreature: number
    
    --[[
      "calmhumanoid"
    ]]
    CalmHumanoid: number
    
    --[[
      "chameleon"
    ]]
    Chameleon: number
    
    --[[
      "charm"
    ]]
    Charm: number
    
    --[[
      "commandcreature"
    ]]
    CommandCreature: number
    
    --[[
      "commandhumanoid"
    ]]
    CommandHumanoid: number
    
    --[[
      "corprus"
    ]]
    Corprus: number
    
    --[[
      "cureblightdisease"
    ]]
    CureBlightDisease: number
    
    --[[
      "curecommondisease"
    ]]
    CureCommonDisease: number
    
    --[[
      "curecorprusdisease"
    ]]
    CureCorprusDisease: number
    
    --[[
      "cureparalyzation"
    ]]
    CureParalyzation: number
    
    --[[
      "curepoison"
    ]]
    CurePoison: number
    
    --[[
      "damageattribute"
    ]]
    DamageAttribute: number
    
    --[[
      "damagefatigue"
    ]]
    DamageFatigue: number
    
    --[[
      "damagehealth"
    ]]
    DamageHealth: number
    
    --[[
      "damagemagicka"
    ]]
    DamageMagicka: number
    
    --[[
      "damageskill"
    ]]
    DamageSkill: number
    
    --[[
      "demoralizecreature"
    ]]
    DemoralizeCreature: number
    
    --[[
      "demoralizehumanoid"
    ]]
    DemoralizeHumanoid: number
    
    --[[
      "detectanimal"
    ]]
    DetectAnimal: number
    
    --[[
      "detectenchantment"
    ]]
    DetectEnchantment: number
    
    --[[
      "detectkey"
    ]]
    DetectKey: number
    
    --[[
      "disintegratearmor"
    ]]
    DisintegrateArmor: number
    
    --[[
      "disintegrateweapon"
    ]]
    DisintegrateWeapon: number
    
    --[[
      "dispel"
    ]]
    Dispel: number
    
    --[[
      "divineintervention"
    ]]
    DivineIntervention: number
    
    --[[
      "drainattribute"
    ]]
    DrainAttribute: number
    
    --[[
      "drainfatigue"
    ]]
    DrainFatigue: number
    
    --[[
      "drainhealth"
    ]]
    DrainHealth: number
    
    --[[
      "drainmagicka"
    ]]
    DrainMagicka: number
    
    --[[
      "drainskill"
    ]]
    DrainSkill: number
    
    --[[
      "extraspell"
    ]]
    ExtraSpell: number
    
    --[[
      "feather"
    ]]
    Feather: number
    
    --[[
      "firedamage"
    ]]
    FireDamage: number
    
    --[[
      "fireshield"
    ]]
    FireShield: number
    
    --[[
      "fortifyattack"
    ]]
    FortifyAttack: number
    
    --[[
      "fortifyattribute"
    ]]
    FortifyAttribute: number
    
    --[[
      "fortifyfatigue"
    ]]
    FortifyFatigue: number
    
    --[[
      "fortifyhealth"
    ]]
    FortifyHealth: number
    
    --[[
      "fortifymagicka"
    ]]
    FortifyMagicka: number
    
    --[[
      "fortifymaximummagicka"
    ]]
    FortifyMaximumMagicka: number
    
    --[[
      "fortifyskill"
    ]]
    FortifySkill: number
    
    --[[
      "frenzycreature"
    ]]
    FrenzyCreature: number
    
    --[[
      "frenzyhumanoid"
    ]]
    FrenzyHumanoid: number
    
    --[[
      "frostdamage"
    ]]
    FrostDamage: number
    
    --[[
      "frostshield"
    ]]
    FrostShield: number
    
    --[[
      "invisibility"
    ]]
    Invisibility: number
    
    --[[
      "jump"
    ]]
    Jump: number
    
    --[[
      "levitate"
    ]]
    Levitate: number
    
    --[[
      "light"
    ]]
    Light: number
    
    --[[
      "lightningshield"
    ]]
    LightningShield: number
    
    --[[
      "lock"
    ]]
    Lock: number
    
    --[[
      "mark"
    ]]
    Mark: number
    
    --[[
      "nighteye"
    ]]
    NightEye: number
    
    --[[
      "open"
    ]]
    Open: number
    
    --[[
      "paralyze"
    ]]
    Paralyze: number
    
    --[[
      "poison"
    ]]
    Poison: number
    
    --[[
      "rallycreature"
    ]]
    RallyCreature: number
    
    --[[
      "rallyhumanoid"
    ]]
    RallyHumanoid: number
    
    --[[
      "recall"
    ]]
    Recall: number
    
    --[[
      "reflect"
    ]]
    Reflect: number
    
    --[[
      "removecurse"
    ]]
    RemoveCurse: number
    
    --[[
      "resistblightdisease"
    ]]
    ResistBlightDisease: number
    
    --[[
      "resistcommondisease"
    ]]
    ResistCommonDisease: number
    
    --[[
      "resistcorprusdisease"
    ]]
    ResistCorprusDisease: number
    
    --[[
      "resistfire"
    ]]
    ResistFire: number
    
    --[[
      "resistfrost"
    ]]
    ResistFrost: number
    
    --[[
      "resistmagicka"
    ]]
    ResistMagicka: number
    
    --[[
      "resistnormalweapons"
    ]]
    ResistNormalWeapons: number
    
    --[[
      "resistparalysis"
    ]]
    ResistParalysis: number
    
    --[[
      "resistpoison"
    ]]
    ResistPoison: number
    
    --[[
      "resistshock"
    ]]
    ResistShock: number
    
    --[[
      "restoreattribute"
    ]]
    RestoreAttribute: number
    
    --[[
      "restorefatigue"
    ]]
    RestoreFatigue: number
    
    --[[
      "restorehealth"
    ]]
    RestoreHealth: number
    
    --[[
      "restoremagicka"
    ]]
    RestoreMagicka: number
    
    --[[
      "restoreskill"
    ]]
    RestoreSkill: number
    
    --[[
      "sanctuary"
    ]]
    Sanctuary: number
    
    --[[
      "shield"
    ]]
    Shield: number
    
    --[[
      "shockdamage"
    ]]
    ShockDamage: number
    
    --[[
      "silence"
    ]]
    Silence: number
    
    --[[
      "slowfall"
    ]]
    SlowFall: number
    
    --[[
      "soultrap"
    ]]
    Soultrap: number
    
    --[[
      "sound"
    ]]
    Sound: number
    
    --[[
      "spellabsorption"
    ]]
    SpellAbsorption: number
    
    --[[
      "stuntedmagicka"
    ]]
    StuntedMagicka: number
    
    --[[
      "summonancestralghost"
    ]]
    SummonAncestralGhost: number
    
    --[[
      "summonbear"
    ]]
    SummonBear: number
    
    --[[
      "summonbonelord"
    ]]
    SummonBonelord: number
    
    --[[
      "summonbonewalker"
    ]]
    SummonBonewalker: number
    
    --[[
      "summonbonewolf"
    ]]
    SummonBonewolf: number
    
    --[[
      "summoncenturionsphere"
    ]]
    SummonCenturionSphere: number
    
    --[[
      "summonclannfear"
    ]]
    SummonClannfear: number
    
    --[[
      "summoncreature04"
    ]]
    SummonCreature04: number
    
    --[[
      "summoncreature05"
    ]]
    SummonCreature05: number
    
    --[[
      "summondaedroth"
    ]]
    SummonDaedroth: number
    
    --[[
      "summondremora"
    ]]
    SummonDremora: number
    
    --[[
      "summonfabricant"
    ]]
    SummonFabricant: number
    
    --[[
      "summonflameatronach"
    ]]
    SummonFlameAtronach: number
    
    --[[
      "summonfrostatronach"
    ]]
    SummonFrostAtronach: number
    
    --[[
      "summongoldensaint"
    ]]
    SummonGoldenSaint: number
    
    --[[
      "summongreaterbonewalker"
    ]]
    SummonGreaterBonewalker: number
    
    --[[
      "summonhunger"
    ]]
    SummonHunger: number
    
    --[[
      "summonscamp"
    ]]
    SummonScamp: number
    
    --[[
      "summonskeletalminion"
    ]]
    SummonSkeletalMinion: number
    
    --[[
      "summonstormatronach"
    ]]
    SummonStormAtronach: number
    
    --[[
      "summonwingedtwilight"
    ]]
    SummonWingedTwilight: number
    
    --[[
      "summonwolf"
    ]]
    SummonWolf: number
    
    --[[
      "sundamage"
    ]]
    SunDamage: number
    
    --[[
      "swiftswim"
    ]]
    SwiftSwim: number
    
    --[[
      "telekinesis"
    ]]
    Telekinesis: number
    
    --[[
      "turnundead"
    ]]
    TurnUndead: number
    
    --[[
      "vampirism"
    ]]
    Vampirism: number
    
    --[[
      "waterbreathing"
    ]]
    WaterBreathing: number
    
    --[[
      "waterwalking"
    ]]
    WaterWalking: number
    
    --[[
      "weaknesstoblightdisease"
    ]]
    WeaknessToBlightDisease: number
    
    --[[
      "weaknesstocommondisease"
    ]]
    WeaknessToCommonDisease: number
    
    --[[
      "weaknesstocorprusdisease"
    ]]
    WeaknessToCorprusDisease: number
    
    --[[
      "weaknesstofire"
    ]]
    WeaknessToFire: number
    
    --[[
      "weaknesstofrost"
    ]]
    WeaknessToFrost: number
    
    --[[
      "weaknesstomagicka"
    ]]
    WeaknessToMagicka: number
    
    --[[
      "weaknesstonormalweapons"
    ]]
    WeaknessToNormalWeapons: number
    
    --[[
      "weaknesstopoison"
    ]]
    WeaknessToPoison: number
    
    --[[
      "weaknesstoshock"
    ]]
    WeaknessToShock: number
    
  end
  record MagicEffectWithParams
    --[[
      Optional attribute ID
    ]]
    affectedAttribute: string
    
    --[[
      Optional skill ID
    ]]
    affectedSkill: string
    
    area: number
    
    duration: number
    
    --[[
      @{#MagicEffect}
    ]]
    effect: core.MagicEffect
    
    magnitudeMax: number
    
    magnitudeMin: number
    
    range: number
    
  end
  record MagicSchoolData
  end
  --[[
    List of GameObjects.
    Implements [iterables#List](iterables.html#List) of #GameObject
  ]]
  record ObjectList
    { core.GameObject }
  end
  --[[
    `core.stats.Skill`
  ]]
  record Skill
    --[[
      Returns a read-only @{#SkillRecord}
    ]]
    record: function(
      recordId: string
    ): core.SkillRecord
    
    --[[
      A read-only list of all @{#SkillRecord}s in the world database.
    ]]
    records: { core.SkillRecord }
    
  end
  record SkillRecord
    --[[
      Human-readable description
    ]]
    description: string
    
    --[[
      VFS path to the icon
    ]]
    icon: string
    
    --[[
      Record id
    ]]
    id: string
    
    --[[
      Human-readable name
    ]]
    name: string
    
    --[[
      Optional magic school
    ]]
    school: core.MagicSchoolData
    
  end
  record SoundRecord
    --[[
      Normalized path to sound file in VFS
    ]]
    fileName: string
    
    --[[
      Sound id
    ]]
    id: string
    
    --[[
      Raw maximal range value, from 0 to 255
    ]]
    maxRange: number
    
    --[[
      Raw minimal range value, from 0 to 255
    ]]
    minRange: number
    
    --[[
      Raw sound volume, from 0 to 255
    ]]
    volume: number
    
  end
  record Spell
    cost: number
    
    --[[
      The effects (@{#MagicEffectWithParams}) of the spell
    ]]
    effects: { core.MagicEffectWithParams }
    
    --[[
      Spell id
    ]]
    id: string
    
    --[[
      Spell name
    ]]
    name: string
    
    --[[
      @{#SpellType}
    ]]
    type: number
    
  end
  --[[
    `core.magic.RANGE`
  ]]
  record SpellRange
    --[[
      Applied on self
    ]]
    Self: number
    
    --[[
      Ranged spell
    ]]
    Target: number
    
    --[[
      On touch
    ]]
    Touch: number
    
  end
  --[[
    `core.magic.SPELL_TYPE`
  ]]
  record SpellType
    --[[
      Innate ability, always in effect
    ]]
    Ability: number
    
    --[[
      Blight disease
    ]]
    Blight: number
    
    --[[
      Curse
    ]]
    Curse: number
    
    --[[
      Common disease
    ]]
    Disease: number
    
    --[[
      Power, can be used once a day
    ]]
    Power: number
    
    --[[
      Normal spell, must be cast and costs mana
    ]]
    Spell: number
    
  end
  --[[
    Either table with options or @{openmw.util#Vector3} rotation.
  ]]
  record TeleportOptions
    --[[
      If true, adjust destination position to the ground.
    ]]
    onGround: boolean
    
    --[[
      New rotation; if missing, then the current rotation is used.
    ]]
    rotation: openmw_util.Transform
    
  end
end
return core