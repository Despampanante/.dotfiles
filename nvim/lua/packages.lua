return require('packer').startup(function()

    --Packer Prereq
    use { "wbthomason/packer.nvim" }

    --Aesthetic
    use { "gruvbox-community/gruvbox" }
    use { "goolord/alpha-nvim",
        requires = { 'kyazdani42/nvim-web-devicons' },
        config = function()
            require'alpha'.setup(require'alpha.themes.startify'.opts)
        end
    }
    use { "nvim-lualine/lualine.nvim",
        requires = { 'kyazdani42/nvim-web-devicons', opt = true }
    }

    --Lsp Stuff 
    use { "neovim/nvim-lspconfig" }
    use { "williamboman/nvim-lsp-installer" }
    use { "jose-elias-alvarez/nvim-lsp-ts-utils" }
    use { "jose-elias-alvarez/null-ls.nvim" }

    --Cmp Stuff
    use { "hrsh7th/cmp-nvim-lsp" }
    use { "hrsh7th/cmp-buffer" }
    use { "hrsh7th/cmp-path" }
    use { "hrsh7th/cmp-cmdline" }
    use { "hrsh7th/nvim-cmp" }

    --Treesitter stuff
    use { "nvim-treesitter/nvim-treesitter" }

    --File browser
    use { "kyazdani42/nvim-tree.lua" }

    --Telescope stuff
    use { "nvim-lua/plenary.nvim" }
    --use { "nvim-telescope/telescope-file-browser.nvim" }
    use { "nvim-telescope/telescope.nvim" }

    --Git Stuff
    use { "tpope/vim-fugitive" }
    use { "airblade/vim-gitgutter" }

    --Snipping Tools
    use { "hrsh7th/vim-vsnip" }
    use { "hrsh7th/vim-vsnip-integ" }

    --Misc
    use { "habamax/vim-godot" }

end)


