local _PACKAGE = (...):match("^(.+)[%./][^%./]+") or ""
local Registry = require(_PACKAGE .. '/registry')
local g        = _BehaviourTreeGlobals


local state = nil

local function tryStrToOtherType(str)
    if str == "true" then
        return true
    elseif str == "false" then
        return false
    elseif str == "nil" then
        return nil
    else
        return str
    end
end

local function ParsePropertyValue(val, config)
    if type(val) == "string" and string.find(val, "%$") then
        -- state object reference found, parsing as a lua expression
        val = val:gsub("%$:", "_s:")
        val = val:gsub("%$%.", "_s.")
        val = val:gsub("%$(%a)", "_s.%1")

        local fn, err = g.loadCodeInScope("return " .. val, { _s = state })
        if err then
            print("Can not parse " .. config.name .. " value: " .. val)
        end
        if not fn then
            error("Somehow property value parser returned a nil function. This shouldn't happen.")
        end
        return fn
    else
        val = tryStrToOtherType(val)
        return function()
            return val
        end
    end
end


local function parseNode(node, treeData)
    if node == nil then
        return error("Passed node argument is nil, this shouldn't happen...")
    end
    local initData = {}
    initData.name = node.title or node.name
    initData.isStealthy = node.isStealthy

    if node.child then
        initData.childNode = parseNode(treeData.nodes[node.child], treeData)
    end
    if node.children then
        initData.childNodes = {}
        for i, childId in pairs(node.children) do
            local cn = parseNode(treeData.nodes[childId], treeData)
            if cn == nil then
                return error("Parsed node is nil, this shouldn't happen... Node id: " ..
                    childId .. " Node json data: " .. tostring(treeData.nodes[childId]))
            end
            table.insert(initData.childNodes, cn)
        end
    end

    local fn = Registry.get(node.name)

    initData._properties = node.properties
    initData.properties = {}
    for field, value in pairs(node.properties) do
        -- Warning! Strings will break since they will be treated as variables!
        initData.properties[field] = ParsePropertyValue(value, initData)
    end

    local inst

    if type(fn) == "table" then
        inst = fn:new(initData)
    else
        inst = fn(initData)
    end

    if inst == nil then
        return error("Return value of " ..
            node.name ..
            " Node retrieved from the registry returns nil instead of a node instance. Ensure that your behaviour node wrapper return a node instance.")
    end

    return inst
end

-- Recursively parse trees into a dictionaries of initialised nodes
local function ParseBehavior3Project(projectData, _state)
    state = _state

    local trees = {}

    if projectData.data then projectData = projectData.data end

    -- Expecting json lists to be dictionaries with 1,2,3 etc fields
    for i, treeData in pairs(projectData.trees) do
        if trees[treeData.title] then
            error("Duplicate tree names datected. Ensure that all the trees in you project have unique names.")
        end
        if not treeData.root then
            error(treeData.title ..
                " tree has no root. Ensure that you have atleast a single node conected to the root node in that tree.")
        end
        trees[treeData.title] = parseNode(treeData.nodes[treeData.root], treeData)
    end

    return trees
end

return ParseBehavior3Project
