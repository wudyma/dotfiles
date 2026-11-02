-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

-- Python extra selects one type server and Ruff for linting.
vim.g.lazyvim_python_lsp = "ty"
vim.g.lazyvim_python_ruff = "ruff"

-- Make LazyVim's built-in picker keymaps match the custom Telescope mappings.
vim.g.lazyvim_picker = "telescope"

opt.smoothscroll = false
