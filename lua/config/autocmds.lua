local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup
local is_remote = require("config.util").is_remote

-- Highlight on yank
autocmd("TextYankPost", {
  group = augroup("HighlightYank", { clear = true }),
  callback = function() vim.hl.on_yank({ timeout = 200 }) end,
})

-- Remove trailing whitespace on save (without moving the cursor or clobbering the search register)
autocmd("BufWritePre", {
  group = augroup("TrimWhitespace", { clear = true }),
  pattern = "*",
  callback = function()
    local view = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

-- Restore cursor position
autocmd("BufReadPost", {
  group = augroup("RestoreCursor", { clear = true }),
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Auto-save on focus lost / buffer leave (local files only: remote buffers
-- would trigger an scp upload on every buffer switch, so save those with :w)
autocmd({ "FocusLost", "BufLeave" }, {
  group = augroup("AutoSave", { clear = true }),
  callback = function(ev)
    if vim.bo[ev.buf].modified
      and vim.bo[ev.buf].buftype == ""
      and vim.api.nvim_buf_get_name(ev.buf) ~= ""
      and not is_remote(ev.buf)
    then
      vim.api.nvim_buf_call(ev.buf, function() vim.cmd("silent! write") end)
    end
  end,
})

-- Language-specific indentation
autocmd("FileType", {
  group = augroup("LangIndent", { clear = true }),
  pattern = { "go", "make" },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.expandtab = false
  end,
})

autocmd("FileType", {
  group = augroup("LangIndentTwo", { clear = true }),
  pattern = { "lua", "yaml", "json", "toml" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
  end,
})

-- Close some filetypes with q
autocmd("FileType", {
  group = augroup("CloseWithQ", { clear = true }),
  pattern = { "help", "man", "qf", "checkhealth" },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = ev.buf, silent = true })
  end,
})

-- Use cindent instead of treesitter indent for C/C++
autocmd("FileType", {
  group = augroup("CIndent", { clear = true }),
  pattern = { "c", "cpp" },
  callback = function(ev)
    vim.bo[ev.buf].indentexpr = ""
    vim.bo[ev.buf].cindent = true
  end,
})
