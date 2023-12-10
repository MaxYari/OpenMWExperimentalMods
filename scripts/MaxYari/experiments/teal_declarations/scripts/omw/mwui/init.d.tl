--[[
  require('openmw.interfaces').MWUI
]]

local openmw_ui = require("openmw.ui")
--[[
  local I = require('openmw.interfaces')
  local ui = require('openmw.ui')
  local auxUi = require('openmw_aux.ui')
  ui.create {
      template = I.MWUI.templates.textNormal,
      layer = 'Windows',
      type = ui.TYPE.Text,
      props = {
          text = 'Hello, world!',
      },
  }
  -- important to copy here
  local myText = auxUi.deepLayoutCopy(I.MWUI.templates.textNormal)
  myText.props.textSize = 20
  I.MWUI.templates.textNormal = myText
  ui.updateAll()
]]
global record Templates
  --[[
    Standard rectangular borders
  ]]
  borders: openmw_ui.Template
  
  --[[
    Standard rectangular borders
  ]]
  bordersThick: openmw_ui.Template
  
  --[[
    Container wrapping the content with borders
  ]]
  box: openmw_ui.Template
  
  --[[
    Container wrapping the content with borders
  ]]
  boxThick: openmw_ui.Template
  
  --[[
    Same as box, but with a semi-transparent background
  ]]
  boxTransparent: openmw_ui.Template
  
  --[[
    Same as box, but with a semi-transparent background
  ]]
  boxTransparentThick: openmw_ui.Template
  
  --[[
    Shades its children and makes them uninteractible
  ]]
  disabled: openmw_ui.Template
  
  --[[
    Expanding horizontal line
  ]]
  horizontalLine: openmw_ui.Template
  
  --[[
    Expanding horizontal line
  ]]
  horizontalLineThick: openmw_ui.Template
  
  --[[
    Standard spacing interval
  ]]
  interval: openmw_ui.Template
  
  --[[
    Container that adds padding around its content.
  ]]
  padding: openmw_ui.Template
  
  --[[
    Multiline text input
  ]]
  textEditBox: openmw_ui.Template
  
  --[[
    Single line text input
  ]]
  textEditLine: openmw_ui.Template
  
  --[[
    Header white colored text
  ]]
  textHeader: openmw_ui.Template
  
  --[[
    Standard "sand" colored text
  ]]
  textNormal: openmw_ui.Template
  
  --[[
    Standard "sand" colored multiline text
  ]]
  textParagraph: openmw_ui.Template
  
  --[[
    Expanding vertical line
  ]]
  verticalLine: openmw_ui.Template
  
  --[[
    Expanding vertical line
  ]]
  verticalLineThick: openmw_ui.Template
  
end
local record MWUI
  templates: Templates
  
  --[[
    Interface version
  ]]
  version: number
  
end
return MWUI