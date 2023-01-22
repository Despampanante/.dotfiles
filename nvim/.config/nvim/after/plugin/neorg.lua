require('neorg').setup {
    load = {
        ["core.defaults"] = {},
        ["core.norg.dirman"] = {
            config = {
                workspaces = {
                    main = "~/notes",
                    -- gtd = "~/notes/gtd"
                }
            }
        },
        ["core.norg.concealer"] = {},
        ["core.norg.completion"] = {
            config =  {
                engine="nvim-cmp"},
        },
        -- ["core.gtd.base"] = {
        --     config = {
        --         workspace = "gtd"
        --     }
        -- },
    }
}
