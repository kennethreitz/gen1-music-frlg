return function(mod)
  local function ownFile(file)
    local source, err = mod:read(file)
    assert(source, err or ("Missing " .. file))
    return assert(load(source, "@" .. mod.path .. "/" .. file))()
  end
  ownFile("runtime.lua")(mod, ownFile("mapping.lua"))
end
