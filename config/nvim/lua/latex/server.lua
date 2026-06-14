-- ~/.config/nvim/lua/latex/server.lua
-- Server lifecycle management for latex-preview-server

local M = {}

-- State
local server_job = nil -- vim.fn.jobstart job id
local server_port = nil -- detected port
local project_root = nil -- detected project root
local nvim_socket = nil -- Neovim server socket path

-- Configuration
local DEFAULT_PORT = 17525
local HOST = "127.0.0.1"

--- Check if a server is responding on a given port
local function probe_port(port)
  local result = vim.fn.system({ "curl", "--noproxy", "*", "-s", "-o", "/dev/null", "-w", "%{http_code}",
    "http://" .. HOST .. ":" .. port .. "/status",
    "--max-time", "1" })
  local ok = result:match("^200$") ~= nil
  if ok then
    return tonumber(port)
  end
  return nil
end

--- Start the Neovim server socket (for reverse sync)
local function ensure_nvim_socket()
  if nvim_socket and vim.fn.serverlist():find(nvim_socket, 1, true) then
    return nvim_socket
  end

  -- Create a socket name based on the project directory
  local cwd = vim.fn.getcwd()
  local cwd_name = vim.fn.fnamemodify(cwd, ":t")
  nvim_socket = "/tmp/nvim-latex-" .. cwd_name .. ".sock"

  -- vim.fn.serverstart returns the socket path on success, empty on failure
  local ok, result = pcall(vim.fn.serverstart, nvim_socket)
  if not ok then
    vim.notify("[latex-preview] Failed to start Neovim server socket", vim.log.levels.WARN)
    nvim_socket = nil
    return nil
  end

  return nvim_socket
end

--- Walk up from current .tex file to find project root (.latexmkrc)
function M.detect_project()
  local tex_file = vim.fn.expand("%:p")
  if tex_file == "" then
    tex_file = vim.fn.getcwd()
  end

  local dir = vim.fn.fnamemodify(tex_file, ":h")
  local root = dir
  while true do
    local latexmkrc = root .. "/.latexmkrc"
    if vim.fn.filereadable(latexmkrc) == 1 then
      project_root = root
      return project_root
    end
    local parent = vim.fn.fnamemodify(root, ":h")
    if parent == root then
      break -- Hit filesystem root
    end
    root = parent
  end
  -- Fallback: directory of current .tex file
  project_root = dir
  return project_root
end

--- Scan for a running server and update server_port if found
function M.detect_running()
  -- Check default port first
  local port = probe_port(DEFAULT_PORT)
  if port then
    server_port = port
    return true
  end
  -- Also check nearby ports in case someone used a custom port
  for p = 17525, 17535 do
    local found = probe_port(p)
    if found then
      server_port = found
      return true
    end
  end
  return false
end

--- Start the latex-preview-server
function M.start()
  -- First check if a server is already running (maybe started externally)
  if M.detect_running() then
    vim.notify("[latex-preview] Server already running on port " .. server_port)
    return
  end

  M.detect_project()
  ensure_nvim_socket()

  if not project_root then
    vim.notify("[latex-preview] Could not detect LaTeX project root", vim.log.levels.ERROR)
    return
  end

  -- Try to auto-detect port: check if DEFAULT_PORT is already in use by our server
  local port = DEFAULT_PORT

  -- Build the command
  local cmd = {
    "latex-preview-server",
    "--root", project_root,
    "--host", HOST,
    "--port", tostring(port),
  }

  if nvim_socket then
    table.insert(cmd, "--nvim-socket")
    table.insert(cmd, nvim_socket)
  end

  vim.notify("[latex-preview] Starting server in " .. project_root .. "...")

  server_job = vim.fn.jobstart(cmd, {
    on_stdout = function(_, data, _)
      if not data then return end
      for _, line in ipairs(data) do
        if line ~= "" then
          -- Parse port from server output: "listening on http://127.0.0.1:17525"
          local http_match = line:match("listening on http://[^:]+:(%d+)")
          if http_match then
            server_port = tonumber(http_match)
          end
          vim.notify("[latex-preview] " .. line)
        end
      end
    end,
    on_stderr = function(_, data, _)
      if not data then return end
      for _, line in ipairs(data) do
        if line ~= "" then
          vim.notify("[latex-preview] " .. line, vim.log.levels.WARN)
        end
      end
    end,
    on_exit = function(_, code, _)
      server_job = nil
      server_port = nil
      if code and code ~= 0 then
        vim.notify("[latex-preview] Server exited with code " .. code, vim.log.levels.WARN)
      end
    end,
  })

  if server_job <= 0 then
    vim.notify("[latex-preview] Failed to start server. Is latex-preview-server installed? (bun install -g latex-preview-server)", vim.log.levels.ERROR)
    server_job = nil
    return
  end

  vim.notify("[latex-preview] Server starting... Use <leader>lv to open preview")
end

--- Stop the server
function M.stop()
  if server_job then
    vim.fn.jobstop(server_job)
    server_job = nil
    server_port = nil
    vim.notify("[latex-preview] Server stopped")
  else
    -- Try to stop any server on the known port
    if server_port then
      vim.fn.system({ "curl", "--noproxy", "*", "-s", "-X", "POST",
        "http://" .. HOST .. ":" .. server_port .. "/shutdown",
        "--max-time", "2" })
    end
    server_port = nil
    vim.notify("[latex-preview] No managed server to stop")
  end
end

--- Check if server is running (managed or external)
function M.is_running()
  if server_job ~= nil then
    return true
  end
  -- Also check if an externally-started server is responding
  if server_port then
    return probe_port(server_port) ~= nil
  end
  return M.detect_running()
end

--- Get the server port (detects if not known)
function M.get_port()
  if server_port then
    return server_port
  end
  -- Try to detect
  M.detect_running()
  return server_port or DEFAULT_PORT
end

--- Open PDF preview in browser
function M.open_browser()
  -- Ensure we know the port
  if not server_port then
    if not M.detect_running() then
      vim.notify("[latex-preview] No server detected. Start with :LatexPreviewStart", vim.log.levels.WARN)
      return
    end
  end

  local url = "http://" .. HOST .. ":" .. server_port

  -- Check if we're in an SSH session
  if vim.env.SSH_CONNECTION or vim.env.SSH_CLIENT or vim.env.SSH_TTY then
    vim.notify(
      "[latex-preview] Open in your local browser:\n  " .. url .. "\n"
      .. "SSH tunnel: ssh -L " .. server_port .. ":" .. HOST .. ":" .. server_port .. " user@host",
      vim.log.levels.INFO
    )
  else
    -- Running locally: try to open the browser
    local ok = pcall(function()
      if vim.fn.has("mac") == 1 then
        vim.fn.system({ "open", url })
      elseif vim.fn.has("unix") == 1 then
        vim.fn.system({ "xdg-open", url, ">/dev/null", "2>&1", "&" })
      elseif vim.fn.has("win32") == 1 then
        vim.fn.system({ "cmd", "/c", "start", url })
      end
    end)
    if not ok then
      vim.notify("[latex-preview] PDF viewer: " .. url)
    end
  end
end

return M
