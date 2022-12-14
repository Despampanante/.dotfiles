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
nkeymap('<c-t><c-t>', ':ToggleTermToggleAll<CR>')
--nkeymap('<c-t><c-h>', ':ToggleTerm direction=horizontal<CR>')
nkeymap('<c-s><c-l>', ':ToggleTerm size=60 direction=vertical dir=.<CR>')

vim.keymap.set('t', '<c-[>', [[<C-\><C-n>]], opts)
vim.keymap.set('t', '<c-t><c-t>', [[<Cmd>ToggleTermToggleAll<CR>]], opts)
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

nkeymap("<F4>", ":lua require('dapui').toggle()<CR>")

--DaDap stuff
nkeymap("<Leader>dsc", ":lua require('dap').continue()<CR>" )
nkeymap("<Leader>dsv", ":lua require('dap').step_over()<CR>" )
nkeymap("<Leader>dsi", ":lua require('dap').step_into()<CR>" )
nkeymap("<Leader>dso", ":lua require('dap').step_out()<CR>" )

nkeymap("<Leader>dhh", ":lua require('dap.ui.variables').hover()<CR>" )
nkeymap("<Leader>dhv", ":lua require('dap.ui.variables').visual_hover()<CR>" )

nkeymap("<Leader>duh", ":lua require('dap.ui.widgets').hover()<CR>" )
nkeymap("<Leader>duf", ":lua local widgets=require('dap.ui.widgets');widgets.centered_float(widgets.scopes)<CR>" )

nkeymap("<Leader>dro", ":lua require('dap').repl.open()<CR>" )
nkeymap("<Leader>drl", ":lua require('dap').repl.run_last()<CR>" )

nkeymap("<Leader>dbc", ":lua require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>" )
nkeymap("<Leader>dbm", ":lua require('dap').set_breakpoint({ nil, nil, vim.fn.input('Log point message: ') )<CR>" )
nkeymap("<Leader>dbt", ":lua require('dap').toggle_breakpoint()<CR>" )

nkeymap("<Leader>dc", ":lua require('dap.ui.variables').scopes()<CR>" )
nkeymap("<Leader>di", ":lua require('dapui').toggle()<CR>" )
