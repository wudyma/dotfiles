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

  -- Configure both the buffer that triggered lazy loading and future buffers.
  local augroup = vim.api.nvim_create_augroup("latex_preview_keymaps", { clear = true })
  local function setup_buffer(bufnr)
    local opts = { buffer = bufnr, silent = true }

    opts.desc = "LaTeX: View PDF"
    vim.keymap.set("n", "<leader>lv", function()
      if not server.is_running() then server.start() end
      vim.defer_fn(function() server.open_browser() end, 1500)
    end, opts)

    opts.desc = "LaTeX: Forward sync"
    vim.keymap.set("n", "<leader>lf", synctex.forward_sync, opts)

    opts.desc = "LaTeX: Toggle preview"
    vim.keymap.set("n", "<leader>lt", function()
      if server.is_running() then server.stop() else server.start() end
    end, opts)

    -- Starting a preview is explicit unless this machine opts in.
    if vim.g.latex_preview_auto_start and vim.fn.executable("latex-preview-server") == 1 then
      vim.defer_fn(function()
        if vim.api.nvim_buf_is_valid(bufnr) and not server.is_running() then
          vim.api.nvim_buf_call(bufnr, server.start)
        end
      end, 500)
    end
  end

  vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = "tex",
    callback = function(event)
      setup_buffer(event.buf)
    end,
  })
  if vim.bo.filetype == "tex" then
    setup_buffer(vim.api.nvim_get_current_buf())
  end

  -- Auto-stop server on exit
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = augroup,
    callback = function()
      server.stop()
    end,
  })
end

return M
