return {
  -- Override tailwindcss: add classRegex for shadcn/ui / Next.js (cn, cva, cx)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        tailwindcss = {
          settings = {
            tailwindCSS = {
              experimental = {
                classRegex = {
                  { 'cva\\(([^)]*)\\)', "[\"'`]([^\"'`]*).*?[\"'`]" },
                  { 'cx\\(([^)]*)\\)',  "[\"'`]([^\"'`]*).*?[\"'`]" },
                  { 'cn\\(([^)]*)\\)',  "[\"'`]([^\"'`]*).*?[\"'`]" },
                },
              },
            },
          },
        },
      },
    },
  },

  -- oxlint: fast linter for JS/TS/HTML/Markdown (replaces eslint)
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        javascript = { "oxlint" },
        javascriptreact = { "oxlint" },
        typescript = { "oxlint" },
        typescriptreact = { "oxlint" },
        html = { "oxlint" },
        markdown = { "oxlint" },
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
