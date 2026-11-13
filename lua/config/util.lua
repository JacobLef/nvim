local M = {}

--- True when the buffer is a netrw remote buffer (scp://, sftp://, rsync://, ...).
--- Local tooling (LSP, linters, formatters, git) can't see these files.
function M.is_remote(buf)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  if not vim.api.nvim_buf_is_valid(buf) then return false end
  return vim.api.nvim_buf_get_name(buf):match("^%a[%w+.-]*://") ~= nil
end

--- Host aliases from ~/.ssh/config (and files it Includes, one level deep).
function M.ssh_hosts()
  local hosts, seen = {}, {}
  local function read(path)
    path = vim.fn.expand(path)
    if vim.fn.filereadable(path) == 0 then return end
    for _, line in ipairs(vim.fn.readfile(path)) do
      local key, rest = line:match("^%s*(%a+)%s+(.+)$")
      key = key and key:lower()
      if key == "host" then
        for name in rest:gmatch("%S+") do
          if not name:find("[*?!]") and not seen[name] then
            seen[name] = true
            table.insert(hosts, name)
          end
        end
      elseif key == "include" and path:match("/%.ssh/config$") then
        for pattern in rest:gmatch("%S+") do
          if not pattern:match("^[/~]") then pattern = "~/.ssh/" .. pattern end
          for _, inc in ipairs(vim.fn.glob(vim.fn.expand(pattern), false, true)) do
            read(inc)
          end
        end
      end
    end
  end
  read("~/.ssh/config")
  table.sort(hosts)
  return hosts
end

return M
