local keymap = vim.api.nvim_set_keymap
local opts = { noremap = true }
local function nkeymap(key, map)
	keymap('n', key, map, opts)
end
--" Always move by visible lines"
nkeymap( "k", "gk")
nkeymap( "gk", "k")
nkeymap( "j", "gj")
nkeymap( "gj", "j")

--" FZF keybindings"
nkeymap( "<C-p>", ":<C-u>Telescope find_files<CR>")

--"Move better between splits"
nkeymap( '<c-j>', '<c-w>j')
nkeymap( '<c-h>', '<c-w>h')
nkeymap( '<c-k>', '<c-w>k')
nkeymap( '<c-l>', '<c-w>l')
