--Map leader
vim.g.mapleader = " "

--Open newtre
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

--Move highlighted stuff 
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

--Join lines better
vim.keymap.set("n", "J", "mzJ`z")

--Half page scroll and center
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

--IDK
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

--Paste over highlighted text without runing paste register
vim.keymap.set("x", "<leader>p", [["_dP]])

--Easier clipboard interaction
vim.keymap.set({"n", "v"}, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

--Delete into the VOID
vim.keymap.set({"n", "v"}, "<leader>d", [["_d]])

--Disable Q
vim.keymap.set("n", "Q", "<nop>")

--Tmux sessionizer
vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")

--Format current file
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)

--Easier movement in QuickFix and Jump lists
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

--Replace current word
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

--Make current file executable
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })
