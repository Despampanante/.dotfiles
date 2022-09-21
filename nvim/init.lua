--Package Init
require('packages')

--Package Conf Setup
require('packConfs/lualineConf')
require('packConfs/treesitterConf')
require('packConfs/cmpConf')
require('packConfs/nvim-treeConf')
require('packConfs/telescopeConf')

--LspSetup
require("mason").setup()
require("mason-lspconfig").setup()
require('Lsps/defaultLspConf')
require('Lsps/tsserverLsp'    )
require('Lsps/gdscriptLsp')
require('Lsps/luaLsp')
require('Lsps/cpp')
require('Lsps/null_lsLsp')

--General
require('configs')
require('keybindings')
