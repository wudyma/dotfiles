-- Offline regression checks; run with nvim -u NONE -i NONE --headless -l this-file.
local root = assert(vim.env.DOTFILES_LUA_ROOT)
local server = dofile(root .. "/lua/latex/server.lua")

-- Starting twice exercises reuse of serverlist(), which returns a list.
local detect_running = server.detect_running
server.detect_running = function() return false end
local sockets = {}
vim.fn.serverlist = function() return sockets end
vim.fn.serverstart = function()
  sockets = { "/private/unique-nvim.sock" }
  return sockets[1]
end
local commands = {}
vim.fn.jobstart = function(command)
  table.insert(commands, command)
  -- Include any automatically created headless server in the mocked list.
  table.insert(sockets, vim.v.servername)
  return 1
end
vim.notify = function() end
server.start()
server.start()
assert(#commands == 2, "server did not start twice")
assert(vim.deep_equal(commands[1], commands[2]), "restarting changed the socket")

-- Opening a local preview uses Neovim's asynchronous platform opener.
server.detect_running = detect_running
vim.fn.system = function() return "200" end
local opened
vim.ui.open = function(url)
  opened = url
  return {}
end
server.open_browser()
assert(opened == "http://127.0.0.1:17525", "preview did not open the local URL")
