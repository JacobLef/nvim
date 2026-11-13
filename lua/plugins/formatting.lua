local is_remote = require("config.util").is_remote

return {
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>fm",
				function()
					require("conform").format({ async = true, lsp_format = "fallback" })
				end,
				desc = "Format",
			},
		},
		opts = {
			formatters_by_ft = {
				c = { "clang-format" },
				cpp = { "clang-format" },
				go = { "goimports", "gofumpt" }, -- gofumpt last so its stricter style wins
				rust = { "rustfmt" },
				python = { "isort", "black" }, -- black last so it has the final say
				lua = { "stylua" },
				sh = { "shfmt" },
				bash = { "shfmt" },
				json = { "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier" },
				perl = { "perltidy" },
			},
			format_on_save = function(bufnr)
				if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
					return
				end
				-- remote (scp://) files: no project config is visible locally, so don't
				-- reformat them behind your back. <leader>fm still works on demand.
				if is_remote(bufnr) then
					return
				end
				local ft = vim.bo[bufnr].filetype
				if ft == "c" or ft == "cpp" then
					local found = vim.fs.find(".clang-format", {
						upward = true,
						path = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr)),
					})
					if #found == 0 then
						return
					end
				end
				return { timeout_ms = 3000, lsp_format = "fallback" }
			end,
		},
		config = function(_, opts)
			require("conform").setup(opts)
			vim.api.nvim_create_user_command("FormatDisable", function(args)
				if args.bang then
					vim.b.disable_autoformat = true -- :FormatDisable! = this buffer only
				else
					vim.g.disable_autoformat = true
				end
			end, { bang = true, desc = "Disable format-on-save (! for current buffer)" })
			vim.api.nvim_create_user_command("FormatEnable", function()
				vim.g.disable_autoformat = false
				vim.b.disable_autoformat = false
			end, { desc = "Re-enable format-on-save" })
		end,
	},
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lint = require("lint")
			lint.linters_by_ft = {
				go = { "golangcilint" },
				python = { "pylint" },
				sh = { "shellcheck" },
				bash = { "shellcheck" },
			}
			vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
				group = vim.api.nvim_create_augroup("NvimLint", { clear = true }),
				callback = function(ev)
					-- linters run against the file on disk, which doesn't exist locally for scp:// buffers
					if not is_remote(ev.buf) then
						lint.try_lint()
					end
				end,
			})
		end,
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "mason-org/mason.nvim" },
		opts = {
			ensure_installed = {
				"clang-format",
				"gofumpt",
				"goimports",
				"golangci-lint",
				"black",
				"isort",
				"pylint",
				"stylua",
				"shfmt",
				"shellcheck",
				"prettier",
			},
		},
	},
}
