return {
    "nvim-pack/nvim-spectre",
    dependencies = {
        "nvim-lua/plenary.nvim"
    },
    config = function()
        require('spectre').setup({
            color_devicons = true,
            open_cmd = 'vnew',
            live_update = true,
            is_insert_mode = true
        })
    end
}
