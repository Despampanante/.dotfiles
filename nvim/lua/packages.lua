return require('packer').startup(function()
  use { "wbthomason/packer.nvim" }
  use { "ellisonleao/gruvbox.nvim" }
  use { "neovim/nvim-lspconfig" }
  use { "nvim-treesitter/nvim-treesitter" }
  use { "williamboman/nvim-lsp-installer" }
  use {
    'goolord/alpha-nvim',
    requires = { 'kyazdani42/nvim-web-devicons' },
    config = function()
      require'alpha'.setup(require'alpha.themes.startify'.opts)
    end
  }

  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/cmp-path'
  use 'hrsh7th/cmp-cmdline'
  use 'hrsh7th/nvim-cmp'
  use 'nvim-lua/plenary.nvim'
  use 'nvim-telescope/telescope.nvim'
  use 'tpope/vim-fugitive'
  use 'jose-elias-alvarez/nvim-lsp-ts-utils'
  use 'airblade/vim-gitgutter'
  use 'habamax/vim-godot'
  use {
    'nvim-lualine/lualine.nvim',
    requires = { 'kyazdani42/nvim-web-devicons', opt = true }
  }
end)


