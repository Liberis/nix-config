return {
    {
        "EdenEast/nightfox.nvim",
        priority = 1000,
        config = function()
            require("nightfox").setup({
                options = {
                    transparent = true, -- Enable transparency
                    terminal_colors = true, -- Set terminal colors
                }
            })
            vim.cmd("colorscheme carbonfox") -- Set carbonfox as the colorscheme
        end
    },

    {
        "echasnovski/mini.icons",
        version = "*", -- Always get the latest stable version
        config = function()
            require("mini.icons").setup({})
        end
    }
}

