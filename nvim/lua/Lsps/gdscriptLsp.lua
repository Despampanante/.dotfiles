require('Lsps/defaultLspConf')
require'lspconfig'.gdscript.setup{
  on_attach = default_on_attach,
  capabilities = capabilities
}
