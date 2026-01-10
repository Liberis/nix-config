return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons", -- For file icons
        "MunifTanjim/nui.nvim",
    },
    config = function()
        require("neo-tree").setup({
            close_if_last_window = false,
            auto_expand_width = true,
            enable_git_status = true,
            enable_diagnostics = true,
            filesystem = {
                filtered_items = {
                    hide_dotfiles = false,
                    hide_gitignored = false,
                },
                follow_current_file_enabled = true,
                use_libuv_file_watcher = true,
            },
            window = {
                position = "left",
                width = 30,
                mappings = {
                    ["<CR>"] = "open",
                    ["l"] = "open",
                    ["h"] = "close_node",
                    ["t"] = "open_tabnew",
                    ["v"] = "open_vsplit",
                    ["s"] = "open_split",
                    ["i"] = "toggle_hidden",
                    ["R"] = "refresh",
                }
            },
            default_component_configs = {
                indent = {
                    indent_size = 2,
                    padding = 1,
                    with_markers = true,
                },
                git_status = {
                    symbols = {
                        added     = "+",
                        modified  = "M",
                        deleted   = "D",
                        renamed   = "R",
                        untracked = "U",
                        ignored   = "◌",
                        unstaged  = "✗",
                        staged    = "✓",
                        conflict  = "",
                    }
                }
            },
        })
    end,
}

