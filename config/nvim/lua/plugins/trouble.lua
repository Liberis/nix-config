return {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = { "TroubleToggle", "Trouble" },
    config = function()
        require("trouble").setup {
            position = "bottom",
            height = 10,
            icons = true,
            mode = "workspace_diagnostics",
            auto_preview = true,
            signs = {
                error = "", 
                warning = "",
                hint = "",
                information = "",
                other = "﫠"
            },
        }
    end
}
