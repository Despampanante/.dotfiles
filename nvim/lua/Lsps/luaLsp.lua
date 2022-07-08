require('lspconfig')['sumneko_lua'].setup {
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
