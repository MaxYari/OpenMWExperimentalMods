local _PACKAGE = (...):match("^(.+)[%./][^%./]+") or ""
local Registry = require(_PACKAGE .. '/registry')

-- Utility functions ------------------
---------------------------------------
local function strToBool(str)
    if str == "true" then
        return true
    else
        return false
    end
end

local function strIsBool(str)
    return str == "true" or str == "false"
end

local function parseNode(node, treeData)
    if node == nil then
        return error("Passed node argument is nil, this shouldn't happen...")
    end
    local initData = {}
    initData.properties = node.properties
    initData.name = node.title or node.name

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

    for field, value in pairs(node.properties) do
        if strIsBool(value) then node.properties[field] = strToBool(value) end
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

-- Recursively parse a tree into a node config
local function ParseProjectJsonTable(projectData)
    local trees = {}

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

return ParseProjectJsonTable
