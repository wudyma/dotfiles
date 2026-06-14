-- ~/.config/nvim/lua/latex/synctex.lua
-- Forward sync: send cursor position to latex-preview-server

local M = {}

function M.forward_sync()
  local server = require("latex.server")
  if not server.is_running() then
    vim.notify("[latex-preview] Server not running. Start with :LatexPreviewStart or run latex-preview-server manually", vim.log.levels.WARN)
    return
  end

  -- Get current cursor position
  local buf = vim.api.nvim_get_current_buf()
  local file_path = vim.api.nvim_buf_get_name(buf)
  if file_path == "" then
    vim.notify("[latex-preview] No file associated with current buffer", vim.log.levels.WARN)
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0) -- {row, col} — row is 1-indexed, col is 0-indexed (Neovim 0.5+)

  -- Build the HTTP request body
  local data = vim.json.encode({
    file = file_path,
    line = cursor[1],
    col = cursor[2], -- Already 0-indexed in Neovim 0.5+
  })

  local port = server.get_port()
  local url = string.format("http://127.0.0.1:%d/forward-sync", port)

  -- Send async POST request via curl (--noproxy '*' bypasses Surge and other local proxies)
  vim.fn.jobstart({
    "curl", "--noproxy", "*", "-s", "-X", "POST",
    "-H", "Content-Type: application/json",
    "-d", data,
    url,
    "--max-time", "3",
  }, {
    on_stdout = function(_, d, _)
      if d then
        for _, line in ipairs(d) do
          if line ~= "" then
            -- Parse response: {"ok":true} or {"ok":false,"error":"..."}
            local ok = line:match('"ok":true') ~= nil
            if not ok then
              vim.notify("[latex-preview] Forward sync failed: " .. line, vim.log.levels.WARN)
            end
          end
        end
      end
    end,
    on_stderr = function(_, d, _)
      if d then
        for _, line in ipairs(d) do
          if line ~= "" then
            vim.notify("[latex-preview] Forward sync error: " .. line, vim.log.levels.WARN)
          end
        end
      end
    end,
  })

  vim.notify("[latex-preview] Forward sync → line " .. cursor[1])
end

return M
