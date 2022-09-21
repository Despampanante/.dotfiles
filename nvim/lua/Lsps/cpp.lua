require('lspconfig')['clangd'].setup {
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    Lua = {
      diagnostics = {
        globals = {'vim', 'use', 'null_ls'},
      },
    },
  },
}
