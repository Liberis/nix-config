return {
    'nvim-telescope/telescope.nvim',
    dependencies = { 
        'nvim-lua/plenary.nvim',
        { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
        'nvim-telescope/telescope-ui-select.nvim',
        'nvim-telescope/telescope-file-browser.nvim'
    },
    config = function()
        require('telescope').setup({
            defaults = {
                sorting_strategy = "ascending",
                layout_config = {
                    prompt_position = "top",
                },
                file_ignore_patterns = { "node_modules", ".git/" },
                mappings = {
                    i = {
                        ["<C-j>"] = "move_selection_next",
                        ["<C-k>"] = "move_selection_previous",
                    }
                }
            },
            extensions = {
                ["ui-select"] = {
                    require("telescope.themes").get_dropdown()
                },
                file_browser = {
                    theme = "dropdown",
                    hijack_netrw = true,
                }
            }
        })
        require('telescope').load_extension('fzf')
        require('telescope').load_extension('ui-select')
        require('telescope').load_extension('file_browser')
    end
}
