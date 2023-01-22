require('nvim-treesitter.configs').setup ({
highlight = {
  -- \`false\` will disable the whole extension  

  enable = true,
},
incremental_selection = {
  enable = true,
  keymaps = {
  	init_selection = '<CR>',
  	scope_incremental = '<CR>',
  	node_incremental = '<TAB>',
  	node_decremental = '<S-TAB>',
  },
},
textobjects = {
  select = {
  	enable = true,
  	-- Automatically jump forward to textobj, similar to targets.vim  
  	lookahead = true,
  	keymaps = {
            -- You can use the capture groups defined in textobjects.scm
            ['af'] = '@function.outer',
            ['if'] = '@function.inner',
            ['ac'] = '@class.outer',
            ['ic'] = '@class.inner',
            ['al'] = '@loop.outer',
            ['il'] = '@loop.inner',
            ['aa'] = '@parameter.outer',
            ['ia'] = '@parameter.inner',
            ['uc'] = '@comment.outer',
            -- Or you can define your own textobjects like this
            -- ["iF"] = {
            --     python = "(function_definition) u/function",
            --     cpp = "(function_definition) u/function",
            --     c = "(function_definition) u/function",
            --     java = "(method_declaration) u/function",
            -- },
            },
  	},

  	move = {
            enable = true,
            set_jumps = true, -- whether to set jumps in the jumplist
            goto_next_start = {
            [']f'] = '@function.outer',
            [']]'] = '@class.outer',
            },
            goto_next_end = {
            [']F'] = '@function.outer',
            [']['] = '@class.outer',
            },
            goto_previous_start = {
            ['[f'] = '@function.outer',
            ['[['] = '@class.outer',
            },
            goto_previous_end = {
            ['[F'] = '@function.outer',
            ['[]'] = '@class.outer',
            },
  	},

  },
})
