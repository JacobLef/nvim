local is_remote = require("config.util").is_remote

return {
	{
		"mason-org/mason.nvim",
		opts = { ui = { border = "rounded" } },
	},
	{
		"mason-org/mason-lspconfig.nvim",
		dependencies = { "mason-org/mason.nvim" },
		opts = {
			ensure_installed = {
				"clangd",
				"gopls",
				"pyright",
				"lua_ls",
				"bashls",
				"yamlls",
				"jsonls",
				"perlnavigator",
			},
			-- servers are enabled explicitly with vim.lsp.enable() below
			automatic_enable = false,
		},
	},
	{ "hrsh7th/cmp-nvim-lsp", lazy = true },
	{ "j-hui/fidget.nvim", event = { "BufReadPre", "BufNewFile" }, opts = {} },
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"mason-org/mason.nvim",
			"mason-org/mason-lspconfig.nvim",
			"hrsh7th/cmp-nvim-lsp",
			"j-hui/fidget.nvim",
		},
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			vim.lsp.config("*", { capabilities = capabilities })

			vim.lsp.config("clangd", {
				cmd = {
					"clangd",
					"--background-index",
					"--clang-tidy",
					"--header-insertion=iwyu",
					"--completion-style=detailed",
					"--function-arg-placeholders",
					"--fallback-style=llvm",
				},
			})

			vim.lsp.config("gopls", {
				settings = {
					gopls = {
						analyses = { unusedparams = true, shadow = true, nilness = true, unusedwrite = true },
						staticcheck = true,
						gofumpt = true,
						usePlaceholders = true,
						hints = {
							assignVariableTypes = true,
							compositeLiteralFields = true,
							constantValues = true,
							parameterNames = true,
						},
					},
				},
			})

			vim.lsp.config("rust_analyzer", {
				settings = {
					["rust-analyzer"] = {
						cargo = { allFeatures = true },
						checkOnSave = true,
						check = { command = "clippy" },
						procMacro = { enable = true },
						inlayHints = {
							bindingModeHints = { enable = true },
							closureReturnTypeHints = { enable = "always" },
							lifetimeElisionHints = { enable = "always" },
						},
					},
				},
			})

			vim.lsp.config("pyright", {
				settings = {
					python = {
						analysis = {
							typeCheckingMode = "basic",
							autoImportCompletions = true,
						},
					},
				},
			})

			vim.lsp.config("lua_ls", {
				settings = {
					Lua = {
						runtime = { version = "LuaJIT" },
						workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
						completion = { callSnippet = "Replace" },
						diagnostics = { globals = { "vim" } },
					},
				},
			})

			vim.lsp.enable({
				"clangd",
				"gopls",
				"rust_analyzer", -- installed via rustup, not Mason
				"pyright",
				"lua_ls",
				"bashls",
				"yamlls",
				"jsonls",
				"perlnavigator",
			})

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("LspKeymaps", { clear = true }),
				callback = function(ev)
					local buf = ev.buf
					local client = vim.lsp.get_client_by_id(ev.data.client_id)

					-- scp:// buffers don't exist on this machine; a local server can't analyze them
					if is_remote(buf) then
						vim.schedule(function()
							vim.lsp.buf_detach_client(buf, ev.data.client_id)
						end)
						return
					end

					local map = function(k, f, d)
						vim.keymap.set("n", k, f, { buffer = buf, desc = "LSP: " .. d })
					end
					map("gd", vim.lsp.buf.definition, "Go to definition")
					map("gD", vim.lsp.buf.declaration, "Go to declaration")
					map("gi", vim.lsp.buf.implementation, "Go to implementation")
					map("gr", vim.lsp.buf.references, "Find references")
					map("K", vim.lsp.buf.hover, "Hover documentation")
					map("<leader>ca", vim.lsp.buf.code_action, "Code actions")
					map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
					map("<leader>D", vim.lsp.buf.type_definition, "Type definition")
					map("]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Next diagnostic")
					map("[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Previous diagnostic")
					map("<leader>d", vim.diagnostic.open_float, "Show diagnostic")
					-- formatting is handled by conform.nvim (<leader>fm), which falls back to LSP

					if client and client:supports_method("textDocument/inlayHint") then
						vim.lsp.inlay_hint.enable(true, { bufnr = buf })
					end
				end,
			})

			vim.diagnostic.config({
				virtual_text = { spacing = 4, prefix = "●" },
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = " ",
						[vim.diagnostic.severity.WARN] = " ",
						[vim.diagnostic.severity.HINT] = "󰌵 ",
						[vim.diagnostic.severity.INFO] = " ",
					},
				},
				underline = true,
				update_in_insert = false,
				severity_sort = true,
				float = { border = "rounded", source = true },
			})
		end,
	},
}
