return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      -- Use the new module path (works on latest nvim-treesitter)
      local ok, ts = pcall(require, "nvim-treesitter.configs")
      if not ok then
        -- Fallback: latest nvim-treesitter moved to this module
        ts = require("nvim-treesitter")
      end

      ts.setup({
        ensure_installed = {
          "c", "cpp", "go", "gomod", "gowork", "gosum",
          "rust", "python",
          "lua", "vim", "vimdoc", "query",
          "bash",
          "json", "yaml", "toml",
          "markdown", "markdown_inline",
          "make", "cmake",
          "dockerfile", "proto",
          "gitcommit", "gitignore",
        },
        highlight = { enable = true },
        indent = { enable = true },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<C-space>",
            node_incremental = "<C-space>",
            scope_incremental = false,
            node_decremental = "<bs>",
          },
        },
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    dependencies = "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local ok, ts = pcall(require, "nvim-treesitter.configs")
      if not ok then
        ts = require("nvim-treesitter")
      end

      ts.setup({
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
              ["aa"] = "@parameter.outer",
              ["ia"] = "@parameter.inner",
            },
          },
          move = {
            enable = true,
            set_jumps = true,
            goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
            goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
          },
          swap = {
            enable = true,
            swap_next = { ["<leader>a"] = "@parameter.inner" },
            swap_previous = { ["<leader>A"] = "@parameter.inner" },
          },
        },
      })
    end,
  },
}
