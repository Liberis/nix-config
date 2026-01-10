return {
    "stevearc/aerial.nvim",
    requires = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    config = function()
        require("aerial").setup({
            backends = { "lsp", "treesitter", "markdown" },   
            open_automatic = true,
            layout = {
                max_width = { 40, 0.2 },  -- Sidebar width (40 columns or 20% of window)
                min_width = 20,           -- Minimum sidebar width
                default_direction = "prefer_right", -- Show sidebar on the right
            },
            manage_folds = true,
            link_folds_to_tree = true,
            link_tree_to_folds = true,
            filter_kind = false,        -- Show all symbol types (functions, classes, etc.)
            resize_to_content = true,
            close_automatic_events = { "unfocus", "switch_buffer", "unsupported"},
            highlight_on_hover = true,  -- Highlight symbols when navigating
            autojump = true,            -- Auto-jump to symbol when selected
            show_guides = true,         -- Enable tree guides (indentation lines)
            guides = {                  -- Customize tree indentation lines
                mid_item = "├─ ",
                last_item = "└─ ",
                nested_top = "│  ",
                whitespace = "   ",
            },
        })    
end
}
