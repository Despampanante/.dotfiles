--Package Init 
require('packages')

--Package Setup 
require('packConfs/lualineConf')
require('packConfs/telescopeConf')
require('packConfs/cmpConf')

--LspSetup
require('nvim-lsp-installer').setup {}
require('Lsps/defaultLspConf')
require('Lsps/tsserverLsp')
require('Lsps/gdscriptLsp')
require('Lsps/luaLsp')

--General
require('configs')
require('keybindings')

