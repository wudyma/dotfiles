return {
  -- Override LSP: use ty for type checking instead of pyright
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ty = {},
        pyright = { enabled = false },
        basedpyright = { enabled = false },
      },
    },
  },

  -- Override formatter: ruff format + organize imports
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        python = { "ruff_format", "ruff_organize_imports" },
      },
    },
  },
}
