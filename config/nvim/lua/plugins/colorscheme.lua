return {
    {
        "EdenEast/nightfox.nvim",
        priority = 1000,
        config = function()
            require("nightfox").setup({
                options = {
                    transparent = true,
                    terminal_colors = true,
                },
                groups = {
                    carbonfox = {
                        -- Fix separators being invisible with transparency
                        WinSeparator = { fg = "#353535" },
                        -- Fix statusline/command area border
                        StatusLine = { bg = "NONE" },
                        StatusLineNC = { bg = "NONE" },
                    },
                },
            })
            vim.cmd("colorscheme carbonfox")
        end
    },

    {
        "echasnovski/mini.icons",
        version = "*",
        config = function()
            require("mini.icons").setup({})
        end
    }
}
