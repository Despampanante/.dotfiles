--Set cursor to THIQQ
vim.opt.guicursor = ""

--Line number stuff
vim.opt.nu = true
vim.opt.relativenumber = true

--Please indent good
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

--Wrapping
vim.opt.wrap = true

--Undo & Swap file
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

--Highlighting
vim.opt.hlsearch = false
vim.opt.incsearch = true

--IDk
vim.opt.termguicolors = true
vim.opt.isfname:append("@-@")
vim.opt.updatetime = 50
vim.opt.colorcolumn = "80"

--Minimum Scroll 
vim.opt.scrolloff = 8

--Sign Column
vim.opt.signcolumn = "yes"
vim.opt.colorcolumn = "0"

--Map LEader
vim.g.mapleader = " "

--Make netrw better
--vim.g.netrw_browse_split = 0
--vim.g.netrw_banner = 0
--vim.g.netrw_winsize = 25

