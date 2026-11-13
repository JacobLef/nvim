-- Remote editing on VMs / servers.
--
-- 1. netrw over scp (Vim-style):   nvim scp://myvm//etc/hosts   or   :Remote myvm /etc/hosts
--      double slash after the host = absolute path, single slash = relative to remote $HOME,
--      end a path with "/" to get a directory listing.
-- 2. SSHFS mounts (full tooling):  :RemoteMount myvm [remote/path]   /   :RemoteUnmount myvm
--      mounts at ~/mnt/<host> so Telescope, nvim-tree, git, formatters all work.
-- 3. Running nvim on the VM itself: copy-to-local-clipboard works over SSH via OSC 52 (below).

local util = require("config.util")
local mount_root = vim.fn.expand("~/mnt")

---------------------------------------------------------------------------
-- netrw (needed for scp:// buffers; nvim-tree still handles local dirs)
---------------------------------------------------------------------------
vim.g.netrw_banner = 0
vim.g.netrw_silent = 1 -- run scp quietly, no "Press ENTER" after every write

---------------------------------------------------------------------------
-- :Remote <host> [path]  ->  opens scp://host/path
---------------------------------------------------------------------------
local function scp_url(host, path)
  path = path or ""
  -- "/abs/path" -> scp://host//abs/path ; "rel/path" or "" -> scp://host/rel/path
  return "scp://" .. host .. "/" .. path
end

local function complete_hosts(arglead, cmdline)
  -- only complete the first argument (the host); later args are remote paths
  local words = vim.split(vim.trim(cmdline), "%s+")
  local index = cmdline:match("%s$") and #words + 1 or #words
  if index ~= 2 then return {} end
  return vim.tbl_filter(function(h) return vim.startswith(h, arglead) end, util.ssh_hosts())
end

vim.api.nvim_create_user_command("Remote", function(opts)
  local host, path = opts.fargs[1], opts.fargs[2]
  vim.cmd.edit(vim.fn.fnameescape(scp_url(host, path)))
end, {
  nargs = "+",
  complete = complete_hosts,
  desc = "Edit a file or browse a directory on a remote host over scp",
})

local function pick_host(prompt, on_choice)
  local hosts = util.ssh_hosts()
  if #hosts == 0 then
    vim.ui.input({ prompt = prompt .. " (user@host or ssh alias): " }, function(h)
      if h and h ~= "" then on_choice(h) end
    end)
    return
  end
  vim.ui.select(hosts, { prompt = prompt }, function(h)
    if h then on_choice(h) end
  end)
end

---------------------------------------------------------------------------
-- SSHFS mounts
---------------------------------------------------------------------------
local function mount_dir(host)
  return mount_root .. "/" .. host:gsub("[^%w%._-]", "_")
end

local function is_mounted(dir)
  local out = vim.fn.system({ "mount" })
  return out:find(" on " .. dir .. " ", 1, true) ~= nil
end

local function open_dir(dir)
  vim.cmd.tcd(vim.fn.fnameescape(dir))
  pcall(vim.cmd, "NvimTreeOpen " .. vim.fn.fnameescape(dir))
end

local function mount(host, rpath)
  if vim.fn.executable("sshfs") == 0 then
    vim.notify("sshfs not found (macOS: install macFUSE + sshfs; Linux: install the sshfs package)",
      vim.log.levels.ERROR)
    return
  end
  local dir = mount_dir(host)
  if is_mounted(dir) then
    open_dir(dir)
    return
  end
  vim.fn.mkdir(dir, "p")
  vim.notify("Mounting " .. host .. " at " .. dir .. " ...")
  vim.system({
    "sshfs", host .. ":" .. (rpath or ""), dir,
    "-o", "reconnect,ServerAliveInterval=15,ServerAliveCountMax=3",
  }, { text = true }, vim.schedule_wrap(function(res)
    if res.code == 0 then
      vim.notify("Mounted " .. host .. " at " .. dir)
      open_dir(dir)
    else
      vim.notify("sshfs failed: " .. vim.trim(res.stderr or ""), vim.log.levels.ERROR)
    end
  end))
end

local function unmount(host)
  local dir = mount_dir(host)
  if not is_mounted(dir) then
    vim.notify(dir .. " is not mounted", vim.log.levels.WARN)
    return
  end
  -- refuse if there are unsaved buffers on the mount; wipe the clean ones
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buf)
    if vim.startswith(name, dir .. "/") then
      if vim.bo[buf].modified then
        vim.notify("Unsaved changes in " .. name .. "; save or discard them first", vim.log.levels.ERROR)
        return
      end
      pcall(vim.api.nvim_buf_delete, buf, { force = false })
    end
  end
  if vim.startswith(vim.fn.getcwd(), dir) then vim.cmd.tcd("~") end

  local cmd
  if vim.fn.has("mac") == 1 then
    cmd = { "umount", dir }
  elseif vim.fn.executable("fusermount3") == 1 then
    cmd = { "fusermount3", "-u", dir }
  else
    cmd = { "fusermount", "-u", dir }
  end
  vim.system(cmd, { text = true }, vim.schedule_wrap(function(res)
    if res.code == 0 then
      vim.notify("Unmounted " .. dir)
    else
      vim.notify("Unmount failed: " .. vim.trim(res.stderr or ""), vim.log.levels.ERROR)
    end
  end))
end

local function mounted_hosts()
  local hosts = {}
  for _, d in ipairs(vim.fn.glob(mount_root .. "/*", false, true)) do
    if is_mounted(d) then table.insert(hosts, vim.fn.fnamemodify(d, ":t")) end
  end
  return hosts
end

vim.api.nvim_create_user_command("RemoteMount", function(opts)
  mount(opts.fargs[1], opts.fargs[2])
end, { nargs = "+", complete = complete_hosts, desc = "Mount a remote host with sshfs at ~/mnt/<host>" })

vim.api.nvim_create_user_command("RemoteUnmount", function(opts)
  unmount(opts.fargs[1])
end, {
  nargs = 1,
  complete = function(arglead)
    return vim.tbl_filter(function(h) return vim.startswith(h, arglead) end, mounted_hosts())
  end,
  desc = "Unmount an sshfs mount under ~/mnt",
})

---------------------------------------------------------------------------
-- Keymaps (<leader>R = Remote)
---------------------------------------------------------------------------
local map = vim.keymap.set
map("n", "<leader>Rh", function()
  pick_host("Remote host", function(host)
    vim.ui.input({ prompt = "Path on " .. host .. " (blank = home, /abs, end dirs with /): " }, function(p)
      if p == nil then return end
      vim.cmd.edit(vim.fn.fnameescape(scp_url(host, p)))
    end)
  end)
end, { desc = "Remote: open file/dir over scp" })

map("n", "<leader>Rm", function()
  pick_host("Mount host", function(host)
    vim.ui.input({ prompt = "Remote path to mount (blank = home): " }, function(p)
      if p == nil then return end
      mount(host, p ~= "" and p or nil)
    end)
  end)
end, { desc = "Remote: sshfs mount" })

map("n", "<leader>Ru", function()
  local hosts = mounted_hosts()
  if #hosts == 0 then
    vim.notify("No sshfs mounts under " .. mount_root)
    return
  end
  vim.ui.select(hosts, { prompt = "Unmount" }, function(h)
    if h then unmount(h) end
  end)
end, { desc = "Remote: sshfs unmount" })

---------------------------------------------------------------------------
-- Clipboard when nvim itself runs on a VM over SSH: copy via OSC 52 to your
-- local terminal. Paste falls back to Neovim's own register, because many
-- terminals block OSC 52 reads (and they can hang).
---------------------------------------------------------------------------
if vim.env.SSH_TTY and not vim.env.DISPLAY and not vim.env.WAYLAND_DISPLAY then
  local ok, osc52 = pcall(require, "vim.ui.clipboard.osc52")
  if ok then
    local function paste()
      return { vim.fn.getreg('"', 1, true), vim.fn.getregtype('"') }
    end
    vim.g.clipboard = {
      name = "OSC 52 (copy only)",
      copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
      paste = { ["+"] = paste, ["*"] = paste },
    }
  end
end
