local keymap = vim.api.nvim_set_keymap
local opts = { noremap = true }
local function nkeymap(key, map)
    keymap('n', key, map, opts)
end

nkeymap("<space>", "<Nop>")
--" Always move by visible lines"
nkeymap("k", "gk")
nkeymap("gk", "k")
nkeymap("j", "gj")
nkeymap("gj", "j")

--Open file_browser
--nkeymap("<space>fb", ":Telescope file_browser <CR>")
nkeymap("<space>fb", ":NvimTreeToggle <CR>")

--" Telescope keybindings"
nkeymap("<leader>p", ":<C-u>Telescope find_files<CR>")
nkeymap("<leader>P", ":<C-u>Telescope projects<CR>")
nkeymap("<leader>s", ":<C-u>Telescope live_grep<CR>")

--"Move better between splits"
nkeymap('<c-j>', '<c-w>j')
nkeymap('<c-h>', '<c-w>h')
nkeymap('<c-k>', '<c-w>k')
nkeymap('<c-l>', '<c-w>l')
nkeymap('<c-leader><c-leader>', ':ToggleTermToggleAll<CR>')
--nkeymap('<c-t><c-h>', ':ToggleTerm direction=horizontal<CR>')
nkeymap('<c-s><c-l>', ':ToggleTerm size=60 direction=vertical dir=.<CR>')

vim.keymap.set('t', '<c-[>', [[<C-\><C-n>]], opts)
vim.keymap.set('t', '<c-i><c-i>', [[<Cmd>ToggleTermToggleAll<CR>]], opts)
vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)

-- Diagnostic stuff
nkeymap('<space>e', ':lua vim.diagnostic.open_float() <CR>')
nkeymap('[d', ':lua vim.diagnostic.goto_prev() <CR>')
nkeymap(']d', ':lua vim.diagnostic.goto_next() <CR>')
nkeymap('<space>q', ':lua vim.diagnostic.setloclist() <CR>')

