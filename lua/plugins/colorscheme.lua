return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require("tokyonight").setup({
      style = "night",
      transparent = false,
      styles = {
        comments = { italic = true },
      },
      -- Your custom background, applied as part of the theme so it survives reloads
      on_colors = function(colors)
        colors.bg = "#15161e"
        colors.bg_float = "#15161e"
      end,
    })
    vim.cmd.colorscheme("tokyonight")
  end,
}
