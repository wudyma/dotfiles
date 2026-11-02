-- Offline regression checks; run with nvim -u NONE -i NONE --headless -l this-file.
local root = assert(vim.env.DOTFILES_LUA_ROOT)
local server = dofile(root .. "/lua/latex/server.lua")
vim.fn.chdir(vim.env.HOME)
assert(server.detect_project() == vim.fn.getcwd(), "unnamed buffer used the parent directory")

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
local exits = {}
vim.fn.jobstart = function(command, options)
  table.insert(commands, command)
  table.insert(exits, options.on_exit)
  -- Include any automatically created headless server in the mocked list.
  table.insert(sockets, vim.v.servername)
  return #commands
end
vim.notify = function() end
server.start()
server.start()
assert(#commands == 1, "a pending server was started twice")
vim.fn.jobstop = function() end
server.stop()
server.start()
assert(#commands == 2, "server did not start twice")
assert(vim.deep_equal(commands[1], commands[2]), "restarting changed the socket")
exits[1](1, 0)
server.start()
assert(#commands == 2, "an old exit callback cleared the active server")

-- Opening a local preview uses Neovim's asynchronous platform opener.
server.detect_running = detect_running
local requests = 0
vim.fn.system = function()
  requests = requests + 1
  return "200"
end
local opened
vim.ui.open = function(url)
  opened = url
  return {}
end
server.open_browser()
assert(opened == "http://127.0.0.1:17525", "preview did not open the local URL")
server.stop()
assert(server.detect_running(), "external service was not detected")
local before_stop = requests
server.stop()
assert(requests == before_stop, "stopping the editor shut down an external service")

-- Lazy loading on FileType must configure the already-open first TeX buffer.
package.loaded["latex.server"] = server
package.loaded["latex.synctex"] = { forward_sync = function() end }
vim.g.mapleader = " "
vim.bo.filetype = "tex"
local deferred = 0
vim.defer_fn = function() deferred = deferred + 1 end
dofile(root .. "/lua/latex/init.lua").setup()
local mappings = vim.api.nvim_buf_get_keymap(0, "n")
assert(vim.iter(mappings):any(function(map) return map.desc == "LaTeX: View PDF" end),
  "first TeX buffer has no preview mapping")
assert(deferred == 0, "opening a TeX file unexpectedly started a preview")
