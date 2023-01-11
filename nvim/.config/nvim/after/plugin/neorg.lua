require('neorg').setup {
    load = {
        ["core.defaults"] = {},
        ["core.norg.dirman"] = {
            config = {
                workspaces = {
                    work = "~/notes/work",
                    personal = "~/notes/personal",
                    school = "~/notes/school",
                }
            }
        },
        ["core.norg.concealer"] = {},
        ["core.norg.completion"] = {},
    }
}
