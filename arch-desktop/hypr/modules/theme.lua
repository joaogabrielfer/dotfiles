local path = os.getenv("HOME") .. "/.config/hypr/theme.generated.lua"
local chunk, message = loadfile(path)
assert(chunk, "Generate a theme with `dot-theme set <name>`: " .. tostring(message))
return chunk()
