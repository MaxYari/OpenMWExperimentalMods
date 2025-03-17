local ui = require('openmw.ui')
local util = require('openmw.util')
local core = require('openmw.core')

local dialogueWindow = nil
local topicsList = nil
local responseField = nil

local function createDialogueWindow()
    dialogueWindow = ui.create {
        layer = 'HUD',
        type = ui.TYPE.Window,
        props = {
            title = "Dialogue",
            size = util.vector2(600, 400),
            position = util.vector2(0.5, 0.5),
            anchor = util.vector2(0.5, 0.5),
            draggable = true,
            resizable = true,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    direction = 'horizontal',
                    size = util.vector2(1, 1),
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            direction = 'vertical',
                            size = util.vector2(0.3, 1),
                        },
                        content = ui.content {
                            {
                                type = ui.TYPE.Text,
                                props = {
                                    text = "Topics",
                                    textSize = 20,
                                    textColor = util.color.rgb(1, 1, 1),
                                },
                            },
                            {
                                type = ui.TYPE.Container,
                                props = {
                                    size = util.vector2(1, 1),
                                },
                                content = ui.content {},
                                name = "topicsList",
                            },
                        },
                    },
                    {
                        type = ui.TYPE.Container,
                        props = {
                            size = util.vector2(0.7, 1),
                        },
                        content = ui.content {
                            {
                                type = ui.TYPE.Text,
                                props = {
                                    text = "Select a topic to see the response.",
                                    textSize = 16,
                                    textColor = util.color.rgb(1, 1, 1),
                                },
                                name = "responseField",
                            },
                        },
                    },
                },
            },
        },
    }

    topicsList = dialogueWindow.layout.content[1].content[1].content[2]
    responseField = dialogueWindow.layout.content[1].content[2].content[1]
end

local function showDialogue(topics)
    if not dialogueWindow then
        createDialogueWindow()
    end

    topicsList.content = ui.content {}
    for _, topic in ipairs(topics) do
        topicsList.content:add {
            type = ui.TYPE.Text,
            props = {
                text = topic,
                textSize = 16,
                textColor = util.color.rgb(0.8, 0.8, 0.8),
            },
            events = {
                onClick = function()
                    core.sendGlobalEvent("TopicSelected", { topic = topic })
                end,
            },
        }
    end

    dialogueWindow:update()
end

local function updateResponse(response)
    responseField.layout.props.text = response
    responseField:update()
end

return {
    showDialogue = showDialogue,
    updateResponse = updateResponse,
}
