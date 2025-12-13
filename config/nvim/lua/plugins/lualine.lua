return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        require('lualine').setup {
            options = {
                icons_enabled = true,
                theme = 'auto',
                component_separators = { left = '', right = '' },
                section_separators = { left = '', right = '' },
                disabled_filetypes = { 'neo-tree' }, -- Ignore neo-tree
            },
            sections = {
                lualine_a = { 'mode' },
                lualine_b = { 'branch', 'diff' }, -- Git integration (Gitsigns handles diffs)
                lualine_c = {
                    { 'filename', file_status = true, path = 1 } -- Show relative path
                },
                lualine_x = {
                    {
                        'diagnostics',
                        sources = { 'nvim_diagnostic' }, -- Use LSP diagnostics (null-ls included)
                        sections = { 'error', 'warn', 'info', 'hint' },
                        symbols = { error = ' ', warn = ' ', info = ' ', hint = ' ' },
                        colored = true,
                        update_in_insert = false,
                        always_visible = false,
                    },
                    'encoding',
                    'fileformat',
                    'filetype'
                },
                lualine_y = { 'progress' },
                lualine_z = { 'location' }
            },
            extensions = { 'quickfix', 'fugitive' } -- Add more extensions if needed
        }
end
}
