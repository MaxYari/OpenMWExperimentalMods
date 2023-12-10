--[[
  `openmw.ui` controls user interface.
  Can be used only by local scripts, that are attached to a player.
  local ui = require('openmw.ui')
]]

local openmw_core = require("openmw.core")
local openmw_util = require("openmw.util")
--[[
  Alignment values (details depend on the specific property).
  For horizontal alignment the order is left to right, for vertical alignment the order is top to bottom.
]]
global record ALIGNMENT
  Center: any
  
  End: any
  
  Start: any
  
end
--[[
  Predefined colors for console output
]]
global record CONSOLE_COLOR
  Default: openmw_util.Color
  
  Error: openmw_util.Color
  
  Info: openmw_util.Color
  
  Success: openmw_util.Color
  
end
--[[
  Layers.
  Implements [iterables#List](iterables.html#List) of #Layer.
  ui.layers.insertAfter('HUD', 'NewLayer', { interactive = true })
  local fourthLayer = ui.layers[4]
  local windowsIndex = ui.layers.indexOf('Windows')
  for i, layer in ipairs(ui.layers) do
    print('layer', i, layer.name, layer.size)
  end
]]
global record Layers
  { ui.Layer }
  --[[
    Index of the layer with the given name.
    Returns nil if the layer doesn't exist
  ]]
  indexOf: function(
    name: string
  ): number | nil
  
  --[[
    Creates a layer and inserts it after another layer (shifts indexes of some other layers).
  ]]
  insertAfter: function(
    afterName: string, --[[Name of the layer after which the new layer will be inserted]]
    name: string, --[[Name of the new layer]]
    options: table
  )
  
  --[[
    Creates a layer and inserts it before another layer (shifts indexes of some other layers).
  ]]
  insertBefore: function(
    beforeName: string, --[[Name of the layer before which the new layer will be inserted]]
    name: string, --[[Name of the new layer]]
    options: table
  )
  
end
--[[
  All available widget types
]]
global record TYPE
  --[[
    Automatically wraps around its contents
  ]]
  Container: any
  
  --[[
    Aligns widgets in a row or column
  ]]
  Flex: any
  
  --[[
    Displays an image
  ]]
  Image: any
  
  --[[
    Display text
  ]]
  Text: any
  
  --[[
    Accepts user text input
  ]]
  TextEdit: any
  
  --[[
    Base widget type
  ]]
  Widget: any
  
  --[[
    Can be moved and resized by the user
  ]]
  Window: any
  
end
local record ui
  --[[
    Alignment values (left to right, top to bottom)
  ]]
  ALIGNMENT: ALIGNMENT
  
  --[[
    Predefined colors for console output
  ]]
  CONSOLE_COLOR: CONSOLE_COLOR
  
  --[[
    Widget types
  ]]
  TYPE: TYPE
  
  --[[
    Converts a given table of tables into an @{openmw.ui#Content}
  ]]
  content: function(
    table: table
  ): ui.Content
  
  --[[
    Creates a UI element from the given layout table
  ]]
  create: function(
    layout: ui.Layout
  ): ui.Element
  
  --[[
    Tools for working with layers
  ]]
  layers: Layers
  
  --[[
    Print to the in-game console.
  ]]
  printToConsole: function(
    msg: string,
    color: openmw_util.Color
  )
  
  --[[
    Adds a settings page to main menu setting's Scripts tab.
  ]]
  registerSettingsPage: function(
    page: ui.SettingsPageOptions
  )
  
  --[[
    Returns the size of the OpenMW window in pixels as a 2D vector.
  ]]
  screenSize: function(): openmw_util.Vector2
  
  --[[
    Set mode of the in-game console.
    The mode can be any string, by default is empty.
    If not empty, then the console doesn't handle mwscript commands and
    instead passes user input to Lua scripts via `onConsoleCommand` engine handler.
  ]]
  setConsoleMode: function(
    mode: string
  )
  
  --[[
    Set selected object for console.
  ]]
  setConsoleSelectedObject: function(
    obj: openmw_core.GameObject
  )
  
  --[[
    Shows given message at the bottom of the screen.
  ]]
  showMessage: function(
    msg: string
  )
  
  --[[
    Register a new texture resource.
    Can be used to manually atlas UI textures.
    local ui = require('openmw.ui')
    local vector2 = require('openmw.util').vector2
    local myAtlas = 'textures/my_atlas.dds' -- a 128x128 atlas
    local texture1 = ui.texture { -- texture in the top left corner of the atlas
        path = myAtlas,
        offset = vector2(0, 0),
        size = vector2(64, 64),
    }
    local texture2 = ui.texture { -- texture in the top right corner of the atlas
        path = myAtlas,
        offset = vector2(64, 0),
        size = vector2(64, 64),
    }
  ]]
  texture: function(
    options: ui.TextureResourceOptions
  ): ui.TextureResource
  
  --[[
    Update all existing UI elements.
    Potentially extremely slow, so only call this when necessary, e. g. after overriding a template.
  ]]
  updateAll: function()
  
  --[[
    Content.
    An array-like container, which allows to reference elements by their name.
    Implements [iterables#List](iterables.html#List) of #Layout and [iterables#Map](iterables.html#Map) of #string to #Layout.
    local content = ui.content {
       { name = 'input' },
    }
    -- bad idea!
    -- content[1].name = 'otherInput'
    -- do this instead:
    content.input = { name = 'otherInput' }
  ]]
  record Content
    { ui.Layout }
    --[[
      Content also acts as a map of names to Layouts
    ]]
    metamethod __index: function(
      self: ui.Content,
      name: string
    ): ui.Layout
    
    --[[
      Adds the layout at the end of the Content
      (same as calling insert with `last index + 1`)
    ]]
    add: function(
      self: ui.Content,
      layout: ui.Layout
    )
    
    --[[
      Finds the index of the given layout.
      If it is not in the container, returns nil
    ]]
    indexOf: function(
      self: ui.Content,
      layout: ui.Layout
    ): number | nil
    
    --[[
      Puts the layout at given index by shifting all the elements after it
    ]]
    insert: function(
      self: ui.Content,
      index: number,
      layout: ui.Layout
    )
    
  end
  --[[
    Element.
    An element of the user interface
  ]]
  record Element
    --[[
      Destroys the element
    ]]
    destroy: function(
      self: ui.Element
    )
    
    --[[
      Access or replace the element's layout
        Note: Is reset to `nil` on `destroy`
    ]]
    layout: ui.Layout
    
    --[[
      Refreshes the rendered element to match the current layout state
    ]]
    update: function(
      self: ui.Element
    )
    
  end
  record Layer
    --[[
      Name of the layer
    ]]
    name: string
    
    --[[
      Size of the layer in pixels
    ]]
    size: openmw_util.Vector2
    
  end
  --[[
    Layout
  ]]
  record Layout
    --[[
      Optional @{openmw.ui#Content} of children layouts
    ]]
    content: ui.Content
    
    --[[
      Optional table of event callbacks
    ]]
    events: table
    
    --[[
      Optional table of external properties
    ]]
    external: table
    
    --[[
      Optional layout to display in. Only applies for the root widget.
        Note: if the #Element isn't attached to anything, it won't be visible!
    ]]
    layer: string
    
    --[[
      Optional name of the layout. Allows access by name from Content
    ]]
    name: string
    
    --[[
      Optional table of widget properties
    ]]
    props: table
    
    --[[
      Optional #Template
    ]]
    template: ui.Template
    
    --[[
      Type of the widget, one of the values in #TYPE. Must match the type in #Template if both are present
    ]]
    type: any
    
    --[[
      Arbitrary data for you to use, e. g. when receiving the layout in an event callback
    ]]
    userData: any
    
  end
  --[[
    Mouse event, passed as an argument to relevant UI events
  ]]
  record MouseEvent
    --[[
      Mouse button which triggered the event.
        Matches the arguments of @{openmw_input#input.isMouseButtonPressed} (`nil` for none, 1 for left, 3 for right).
    ]]
    button: number
    
    --[[
      Position of the mouse cursor relative to the widget
    ]]
    offset: openmw_util.Vector2
    
    --[[
      Absolute position of the mouse cursor
    ]]
    position: openmw_util.Vector2
    
  end
  --[[
    Table with settings page options, passed as an argument to ui.registerSettingsPage
  ]]
  record SettingsPageOptions
    --[[
      The page's UI, which will be attached to the settings tab. The root widget has to have a fixed size. Set the `size` field in `props`, `relativeSize` is ignored.
    ]]
    element: ui.Element
    
    --[[
      Name of the page, displayed in the list, used for search
    ]]
    name: string
    
    --[[
      Additional keywords used in search, not displayed anywhere
    ]]
    searchHints: string
    
  end
  --[[
    Template
  ]]
  record Template
    content: ui.Content
    
    props: table
    
    --[[
      One of the values in #TYPE, serves as the default value for the #Layout
    ]]
    type: any
    
  end
  --[[
    A texture ready to be used by UI widgets
  ]]
  record TextureResource
  end
  --[[
    Table with arguments passed to ui.texture.
  ]]
  record TextureResourceOptions
    --[[
      Offset of this resource in the texture. (0, 0) by default
    ]]
    offset: openmw_util.Vector2
    
    --[[
      Path to the texture file. Required
    ]]
    path: string
    
    --[[
      Size of the resource in the texture. (0, 0) by default. 0 means the whole texture size is used.
    ]]
    size: openmw_util.Vector2
    
  end
end
return ui