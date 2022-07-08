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

--Open file_browser
--nkeymap("<space>fb", ":Telescope file_browser <CR>")
nkeymap("<space>fb", ":NvimTreeToggle <CR>")

--" FZF keybindings"
nkeymap( "<C-p>", ":<C-u>Telescope find_files<CR>")

--"Move better between splits"
nkeymap( '<c-j>', '<c-w>j')
nkeymap( '<c-h>', '<c-w>h')
nkeymap( '<c-k>', '<c-w>k')
nkeymap( '<c-l>', '<c-w>l')

-- Diagnostic stuff
nkeymap('<space>e', 'vim.diagnostic.open_float')
nkeymap('[d', 'vim.diagnostic.goto_prev')
nkeymap(']d', 'vim.diagnostic.goto_next')
nkeymap('<space>q', 'vim.diagnostic.setloclist')

