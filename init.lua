-- Requires Neovim 0.11+ (vim.lsp.config / vim.lsp.enable, vim.hl, vim.diagnostic.jump)
if vim.fn.has("nvim-0.11") == 0 then
	vim.api.nvim_echo({ { "This config requires Neovim 0.11 or newer", "ErrorMsg" } }, true, {})
	return
end

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- Leader key (must be set before lazy)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Load core config
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.remote")

-- Load plugins
require("lazy").setup("plugins", {
	install = { colorscheme = { "tokyonight" } },
	checker = { enabled = true, notify = false },
	change_detection = { notify = false },
	performance = {
		rtp = {
			disabled_plugins = {
				-- netrwPlugin is intentionally NOT disabled: it provides scp:// remote editing
				"gzip",
				"matchit",
				"matchparen",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
})
