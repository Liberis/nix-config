return {
    'akinsho/bufferline.nvim',
    version = "*",
    dependencies = 'nvim-tree/nvim-web-devicons',
    event = "VeryLazy",
    opts = {
        options = {
            close_command = "bdelete! %d",
            right_mouse_command = "bdelete! %d",
            offsets = {
                {
                    filetype = "neo-tree",
                    text = "File Explorer",
                    highlight = "Directory",
                    separator = true,
                },
            },
            diagnostics = "nvim_lsp",
            separator_style = "slant",
        },
    },
}
