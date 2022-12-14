local null_ls = require("null-ls")
null_ls.setup({
    sources = {
        null_ls.builtins.formatting.eslint_d,
        null_ls.builtins.diagnostics.eslint_d,
        null_ls.builtins.code_actions.eslint,
        null_ls.builtins.formatting.prettier,
        null_ls.builtins.formatting.stylua
    },
    on_attach = default_on_attach,
})
