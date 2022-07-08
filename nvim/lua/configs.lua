-- Don't try to be vi compatible
vim.opt.compatible = false

vim.g.do_filetype_lua = 1
vim.g.did_load_filetypes = 0

--" Show line numbers"
vim.opt.number = true

--" Blink cursor on error instead of beeping (grr)"
vim.opt.visualbell = true

--" Whitespace"
vim.opt.wrap = true

--" Set tab rendering to 2 wide"
vim.opt.expandtab = true
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.autoindent = true

--" Autocomplete like zsh (ex commands)"
vim.opt.wildmenu = true
vim.opt.wildmode = "full"

--" Set history of commands"
vim.opt.history = 200

--
vim.cmd("colorscheme gruvbox")

--Set autofolding with Treesitter
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
