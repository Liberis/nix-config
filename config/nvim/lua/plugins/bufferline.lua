return {
    'akinsho/bufferline.nvim',
    version = "*",
    dependencies = 'nvim-tree/nvim-web-devicons',
    event = "VeryLazy",
    config = function()
        local bg_visible = "#1e1e1e"
        local bg_selected = "#282828"
        local bg_fill = "NONE"
        local fg_dim = "#6e6e6e"
        local fg_visible = "#a0a0a0"
        local fg_selected = "#f2f4f8"
        local accent = "#78A9FF"

        require("bufferline").setup({
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
                separator_style = "thin",
                show_buffer_close_icons = false,
                show_close_icon = false,
            },
            highlights = {
                fill = { bg = bg_fill },
                background = { fg = fg_dim, bg = bg_fill },
                buffer_visible = { fg = fg_visible, bg = bg_visible },
                buffer_selected = { fg = fg_selected, bg = bg_selected, bold = true },
                separator = { fg = "#353535", bg = bg_fill },
                separator_visible = { fg = "#353535", bg = bg_visible },
                separator_selected = { fg = accent, bg = bg_selected },
                indicator_selected = { fg = accent, bg = bg_selected },
                modified = { fg = fg_dim, bg = bg_fill },
                modified_visible = { fg = fg_visible, bg = bg_visible },
                modified_selected = { fg = accent, bg = bg_selected },
                tab = { fg = fg_dim, bg = bg_fill },
                tab_selected = { fg = fg_selected, bg = bg_selected, bold = true },
                tab_separator = { fg = "#353535", bg = bg_fill },
                tab_separator_selected = { fg = accent, bg = bg_selected },
                duplicate = { fg = fg_dim, bg = bg_fill, italic = true },
                duplicate_visible = { fg = fg_visible, bg = bg_visible, italic = true },
                duplicate_selected = { fg = fg_selected, bg = bg_selected, italic = true },
            },
        })
    end,
}
