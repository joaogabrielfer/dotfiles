local M = {}

M.required = {
  "base",
  "blue",
  "crust",
  "green",
  "lavender",
  "mantle",
  "maroon",
  "mauve",
  "overlay0",
  "overlay1",
  "overlay2",
  "peach",
  "pink",
  "red",
  "rosewater",
  "sapphire",
  "sky",
  "subtext0",
  "subtext1",
  "surface0",
  "surface1",
  "surface2",
  "teal",
  "text",
  "yellow",
}

function M.validate(palette, expected_name)
  assert(type(palette) == "table", "theme must return a table")
  assert(palette.name == expected_name, "theme name does not match its filename")
  assert(palette.appearance == "dark" or palette.appearance == "light", "invalid appearance")
  assert(type(palette.colors) == "table", "theme must define colors")
  assert(type(palette.accent) == "string" and palette.colors[palette.accent], "invalid accent")

  for _, name in ipairs(M.required) do
    local value = palette.colors[name]
    assert(type(value) == "string" and value:match("^#%x%x%x%x%x%x$"), "invalid color: " .. name)
  end
  return palette
end

return M
