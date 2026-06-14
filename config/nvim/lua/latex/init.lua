-- ~/.config/nvim/lua/latex/init.lua
-- LaTeX preview module: user commands, autocmds, keymaps

local M = {}

local server = require("latex.server")
local synctex = require("latex.synctex")

function M.setup()
  -- Create user commands
  vim.api.nvim_create_user_command("LatexPreviewStart", function()
    server.start()
  end, { desc = "Start latex-preview-server for current project" })

  vim.api.nvim_create_user_command("LatexPreviewStop", function()
    server.stop()
  end, { desc = "Stop latex-preview-server" })

  vim.api.nvim_create_user_command("LatexPreviewForward", function()
    synctex.forward_sync()
  end, { desc = "Forward sync: jump to PDF position" })

  vim.api.nvim_create_user_command("LatexPreviewOpen", function()
    server.open_browser()
  end, { desc = "Open PDF preview in browser" })

  vim.api.nvim_create_user_command("LatexPreviewToggle", function()
    if server.is_running() then
      server.stop()
    else
      server.start()
    end
  end, { desc = "Toggle latex-preview-server" })

  -- Keymaps (set globally, active only in .tex buffers via FileType autocmd)
  local augroup = vim.api.nvim_create_augroup("latex_preview_keymaps", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = "tex",
    callback = function()
      local opts = { buffer = true, noremap = true, silent = true, desc = "" }

      opts.desc = "LaTeX: View PDF"
      vim.keymap.set("n", "<leader>lv", function()
        if not server.is_running() then server.start() end
        -- Give server a moment, then open
        vim.defer_fn(function() server.open_browser() end, 1500)
      end, opts)

      opts.desc = "LaTeX: Forward sync"
      vim.keymap.set("n", "<leader>lf", function()
        synctex.forward_sync()
      end, opts)

      opts.desc = "LaTeX: Toggle preview"
      vim.keymap.set("n", "<leader>lt", function()
        if server.is_running() then server.stop() else server.start() end
      end, opts)
    end,
  })

  -- Auto-start server when opening .tex files
  local start_augroup = vim.api.nvim_create_augroup("latex_preview_start", { clear = true })
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = start_augroup,
    pattern = "*.tex",
    callback = function()
      -- Defer to avoid slowing down buffer open
      vim.defer_fn(function()
        if not server.is_running() then
          server.start()
        end
      end, 500)
    end,
  })

  -- Auto-stop server on exit
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = start_augroup,
    callback = function()
      server.stop()
    end,
  })
end

return M
