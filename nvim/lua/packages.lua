return require('packer').startup(function()
  --Prereq
  use { 'nvim-lua/plenary.nvim' }
  use { 'wbthomason/packer.nvim' }

  --Aesthetic
  use { 'gruvbox-community/gruvbox' }
  use {
    'goolord/alpha-nvim',
    requires = { 'kyazdani42/nvim-web-devicons' },
    config = function() require('plugins.alpha-nvim') end
  }
  use {
    'nvim-lualine/lualine.nvim',
    requires = { 'kyazdani42/nvim-web-devicons', opt = true },
    config = function() require('plugins.lualine') end
  }

  --Cmp Stuff
  use {
    'hrsh7th/nvim-cmp',
    requires ={
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-cmdline',
      'saadparwaiz1/cmp_luasnip',
    },
    config = function() require('plugins.nvim-cmp') end
  }

  --Lsp Stuff 
  use { 'williamboman/mason.nvim' }
  use { 'williamboman/mason-lspconfig.nvim' }
  use { 'neovim/nvim-lspconfig' }

  use { 'jose-elias-alvarez/nvim-lsp-ts-utils' }
  use { 'jose-elias-alvarez/null-ls.nvim' }


  --Snipping Tools
  use { 'https://github.com/L3MON4D3/LuaSnip' }
  use { 'rafamadriz/friendly-snippets' }

  --Treesitter stuff
  use { 
    'nvim-treesitter/nvim-treesitter',
    config = function() require('plugins.nvim-treesitter') end
  }

  --File browser
  use { 'vijaymarupudi/nvim-fzf' }
  use { 
    'kyazdani42/nvim-tree.lua',
    config = function() require('plugins.nvim-tree') end
  }
  use { 'ahmedkhalf/project.nvim', config = function() require('project_nvim').setup{} end}

  --Telescope stuff
  use {
    'nvim-telescope/telescope.nvim',
    config = function() require('plugins.telescope') end
  }

  --Git Stuff
  use { 'tpope/vim-fugitive' }
  use { 'airblade/vim-gitgutter' }


  --Misc
  use {'lewis6991/impatient.nvim'}
  use {'windwp/nvim-autopairs',config = function() require('nvim-autopairs').setup {} end}
  use { 'habamax/vim-godot' }
  use {
    "akinsho/toggleterm.nvim",
    tag = '*',
    config = function()require('plugins.toggleterm')end
  }
  use {
    'chipsenkbeil/distant.nvim',
    config = function() require('plugins.distant') end
  }
end)


