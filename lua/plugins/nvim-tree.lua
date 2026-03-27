return {
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file explorer" },
    { "<leader>o", "<cmd>NvimTreeFindFileToggle<cr>", desc = "Find file in explorer" },
  },
  opts = {
    filters = { dotfiles = false, custom = { ".git", "node_modules", ".cache" } },
    view = { width = 35 },
    renderer = {
      group_empty = true,
      highlight_git = true,
      icons = { show = { git = true } },
    },
    git = { enable = true, ignore = false },
    actions = { open_file = { quit_on_open = false } },
  },
}
