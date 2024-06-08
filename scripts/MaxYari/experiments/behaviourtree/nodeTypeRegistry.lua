local registeredNodes = {}

local NodeTypeRegistry = {}

function NodeTypeRegistry.register(name, node)
  if registeredNodes[name] ~= nil then
    error(name .. "node type already rigestered. Please use different name/registry id.", 2)
  else
    registeredNodes[name] = node;
  end
end

function NodeTypeRegistry.getNode(name)
  if type(name) == 'string' and registeredNodes[name] ~= nil then
    return registeredNodes[name]
  else
    error(
      name ..
      "node type doesn't exist, make sure that you've registered a node of that type before attempting to load the behaviour tree file.",
      2)
  end
end

return NodeTypeRegistry
