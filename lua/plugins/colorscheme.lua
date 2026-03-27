return {
  "Mofiqul/vscode.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    local vscode = require("vscode")
    vscode.setup({
      transparent = false,
      italic_comments = true,
      underline_links = true,
      disable_nvimtree_bg = true,
    })
    vscode.load("dark")
  end,
}
