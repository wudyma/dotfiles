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
}
