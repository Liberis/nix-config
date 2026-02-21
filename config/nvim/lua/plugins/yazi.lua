return {
    "mikavilpas/yazi.nvim",
    cmd = { "Yazi", "YaziPicker" },
    config = function()
        require("yazi").setup({
            open_for_directories = true,
            floating_window = false,
        })
    end
}
