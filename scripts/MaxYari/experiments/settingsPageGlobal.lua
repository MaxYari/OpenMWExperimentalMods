local storage = require('openmw.storage')
local I = require('openmw.interfaces')

I.Settings.registerGroup {
    key = 'SettingsMercyCAOBehavior',
    page = 'MercyCAOPage',
    l10n = 'MercyCAO',
    name = 'Behavior Modifiers',
    permanentStorage = true,
    description = "'Modifier' Values below function as probability multipliers and have no upper limit, set them to an arbitrary high value (e.g 10000) if you want to force the corresponding behaviour to always appear.",
    settings = {
        {
            key = 'StandGroundProbModifier',
            renderer = 'number',
            default = 1,
            argument = {
                min = 0,
                max = 100000,
            },
            name = 'Stand Back Modifier',
            description = 'Higher values make NPC more likely to hesitate and warn the player before engaging in combat.',
        },
        {
            key = 'ScaredProbModifier',
            renderer = 'number',
            default = 1,
            argument = {
                min = 0,
                max = 100000,
            },
            name = 'Scared Modifier',
            description = 'Higher values make NPC more likely to ask for mercy on run away.',
        },
        {
            key = 'SurrenderHealthFraction',
            renderer = 'number',
            default = 0.33,
            argument = {
                min = 0,
                max = 1,
            },
            name = 'Scared Health Fraction',
            description = 'A fraction of total health (in 0 - 1 range) below which NPC will consider asking for mercy or running away.',
        },
    },
}

return {
    
}
