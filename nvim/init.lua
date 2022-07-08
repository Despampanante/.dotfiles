--Package Init 
require('packages')

--Package Conf Setup 
require('packConfs/lualineConf')
--require('packConfs/telescopeConf')
require('packConfs/cmpConf')
require('packConfs/nvim-treeConf')

--LspSetup
require('nvim-lsp-installer').setup {}
require('Lsps/defaultLspConf')
require('Lsps/tsserverLsp')
require('Lsps/gdscriptLsp')
require('Lsps/luaLsp')
require('Lsps/null_lsLsp')

--General
require('configs')
require('keybindings')

