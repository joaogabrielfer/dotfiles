vim.loader.enable()

require("config.options")
require("config.pack")
require("config.autocmds")
require("config.terminal").setup()
require("config.repl").setup()
require("config.keymaps")

require("config.theme").setup({ default = "peach" })
