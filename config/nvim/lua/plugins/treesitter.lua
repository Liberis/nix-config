return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        "nvim-treesitter/nvim-treesitter-textobjects",
        "nvim-treesitter/playground",
    },
    config = function()
        require("nvim-treesitter.configs").setup {
            -- Automatically install missing parsers when opening a file
            auto_install = true,

            -- Ensure installed parsers for commonly used languages
            ensure_installed = {
                "lua", "vim", "vimdoc", "bash", "json", "yaml", "toml",
                "python", "rust", "javascript", "typescript", "html", "css", "c",
            },

            -- Enable syntax highlighting
            highlight = {
                enable = true,
                additional_vim_regex_highlighting = true,
            },

            -- Enable Treesitter-based indentation
            indent = {
                enable = true,
            },

            -- Enable incremental selection
            incremental_selection = {
                enable = true,
                keymaps = {
                    init_selection = "<C-space>",
                    node_incremental = "<C-space>",
                    node_decremental = "<BS>",
                    scope_incremental = "<C-s>",
                },
            },

            -- Treesitter-based code folding
            fold = {
                enable = true,
            },

            -- Enable text objects (requires `nvim-treesitter-textobjects`)
            textobjects = {
                select = {
                    enable = true,
                    lookahead = true,
                    keymaps = {
                        ["af"] = "@function.outer",
                        ["if"] = "@function.inner",
                        ["ac"] = "@class.outer",
                        ["ic"] = "@class.inner",
                    },
                },
                move = {
                    enable = true,
                    set_jumps = true,
                    goto_next_start = {
                        ["]m"] = "@function.outer",
                        ["]c"] = "@class.outer",
                    },
                    goto_previous_start = {
                        ["[m"] = "@function.outer",
                        ["[c"] = "@class.outer",
                    },
                },
            },
        }

        -- Treesitter-based code folding settings
        vim.opt.foldmethod = "expr"
        vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
        vim.opt.foldlevel = 99
    end,

    "nvim-treesitter/nvim-treesitter-context",
    dependencies = {
        "nvim-treesitter/nvim-treesitter"
    },
    config = function()
        require("treesitter-context").setup({
            enable = true,
            max_lines = 3,
            trim_scope = "outer",
        })
    end
}

