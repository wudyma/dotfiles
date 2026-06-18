-- ~/.config/nvim/lua/plugins/latex.lua
-- LaTeX support: lsp + preview server + treesitter + mason

return {
  -- 1. texlab LSP (via nvim-lspconfig override)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        texlab = {
          settings = {
            texlab = {
              build = {
                onSave = false,
                forwardSearchAfter = false,
              },
              latexFormatter = "latexindent",
              latexindent = {
                modifyLineBreaks = true,
              },
            },
          },
        },
      },
    },
  },

  -- 2. Ensure texlab is installed via Mason
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "texlab",
        "latexindent",
      })
    end,
  },

  -- 3. Treesitter for LaTeX + BibTeX
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "latex", "bibtex" })
    end,
  },

  -- 4. LaTeX preview module: loaded when entering .tex files
  {
    "latex-preview-nvim",
    dir = vim.fn.stdpath("config") .. "/lua/latex",
    lazy = true,
    event = "FileType tex",
    config = function()
      require("latex").setup()
    end,
  },
}
