--[[
  -- In a player script
  local storage = require('openmw.storage')
  local I = require('openmw.interfaces')
  I.Settings.registerPage {
      key = 'MyModPage',
      l10n = 'MyMod',
      name = 'My Mod Name',
      description = 'My Mod Description',
  }
  I.Settings.registerGroup {
      key = 'SettingsPlayerMyMod',
      page = 'MyModPage',
      l10n = 'MyMod',
      name = 'My Group Name',
      description = 'My Group Description',
      permanentStorage = false,
      settings = {
          {
              key = 'Greeting',
              renderer = 'textLine',
              name = 'Greeting',
              description = 'Text to display when the game starts',
              default = 'Hello, world!',
          },
      },
  }
  local playerSettings = storage.playerSection('SettingsPlayerMyMod')
  ...
  ui.showMessage(playerSettings:get('Greeting'))
  -- ...
  -- access a setting page registered by a global script
  local globalSettings = storage.globalSection('SettingsGlobalMyMod')
]]

local record Settings
  --[[
    I.Settings.registerGroup {
        key = 'SettingsTest',
        page = 'test',
        l10n = 'test',
        name = 'Player',
        description = 'Player settings group',
        permanentStorage = false,
        settings = {
            {
                key = 'Greeting',
                default = 'Hi',
                renderer = 'textLine',
                name = 'Text Input',
                description = 'Short text input',
            },
            {
                key = 'Flag',
                default = false,
                renderer = 'checkbox',
                name = 'Flag',
                description = 'Flag toggle',
            },
        }
    }
  ]]
  registerGroup: function(
    options: Settings.GroupOptions
  )
  
  --[[
    I.Settings.registerPage({
      key = 'MyModName',
      l10n = 'MyModName',
      name = 'MyModName',
      description = 'MyModDescription',
    })---
  ]]
  registerPage: function(
    options: Settings.PageOptions
  )
  
  --[[
    I.Settings.registerRenderer('text', function(value, set, arg)
      return {
        type = ui.TYPE.TextEdit,
        props = {
          size = util.vector2(arg and arg.size or 150, 30),
          text = value,
          textColor = util.color.rgb(1, 1, 1),
          textSize = 15,
          textAlignV = ui.ALIGNMENT.End,
        },
        events = {
          textChanged = async:callback(function(s) set(s) end),
        },
      }
    end)
  ]]
  registerRenderer: function(
    key: string,
    renderer: function
  )
  
  updateRendererArgument: function(
    groupKey: string, --[[A settings group key]]
    settingKey: string, --[[A setting key]]
    argument: any
  )
  
  version: string
  
  record GroupOptions
    --[[
      A key from the localization context (optional, can be `nil`)
    ]]
    description: string
    
    --[[
      A unique key, starts with "Settings" by convention
    ]]
    key: string
    
    --[[
      A localization context (an argument of core.l10n)
    ]]
    l10n: string
    
    --[[
      A key from the localization context
    ]]
    name: string
    
    --[[
      Groups within the same page are sorted by this number, or their key for equal values.
        Defaults to 0.
    ]]
    order: number
    
    --[[
      Key of a page which will contain this group
    ]]
    page: string
    
    --[[
      Whether the group should be stored in permanent storage, or in the save file
    ]]
    permanentStorage: boolean
    
    --[[
      A [iterables#List](iterables.html#List) table of #SettingOptions
    ]]
    settings: { Settings.SettingOptions }
    
  end
  record PageOptions
    --[[
      A key from the localization context (optional, can be `nil`)
    ]]
    description: string
    
    --[[
      A unique key
    ]]
    key: string
    
    --[[
      A localization context (an argument of core.l10n)
    ]]
    l10n: string
    
    --[[
      A key from the localization context
    ]]
    name: string
    
  end
  --[[
    Table of setting options
  ]]
  record SettingOptions
    --[[
      An argument for the renderer
    ]]
    argument: any
    
    --[[
      A default value
    ]]
    default: any
    
    --[[
      A key from the localization context (optional, can be `nil`)
    ]]
    description: string
    
    --[[
      A unique key
    ]]
    key: string
    
    --[[
      A key from the localization context
    ]]
    name: string
    
    --[[
      A renderer key (see the "Built-in Setting Renderers" page)
    ]]
    renderer: string
    
  end
end
return Settings