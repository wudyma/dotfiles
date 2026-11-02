return {
  -- Use the supported function-name setting for nested calls and templates.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        tailwindcss = {
          settings = {
            tailwindCSS = {
              classFunctions = { "cn", "cva", "cx", "clsx" },
            },
          },
        },
      },
    },
  },

  -- oxlint handles JavaScript/TypeScript, including JSX/TSX.
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        javascript = { "oxlint" },
        javascriptreact = { "oxlint" },
        typescript = { "oxlint" },
        typescriptreact = { "oxlint" },
      },
    },
  },

  -- oxfmt: fast formatter for JS/TS/HTML/Markdown (replaces prettier)
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        javascript = { "oxfmt" },
        javascriptreact = { "oxfmt" },
        typescript = { "oxfmt" },
        typescriptreact = { "oxfmt" },
        html = { "oxfmt" },
        markdown = { "oxfmt" },
      },
    },
  },
}
