local parsers = {
    "lua", "vim", "vimdoc", "bash", "json", "yaml", "toml",
    "python", "rust", "javascript", "typescript", "html", "css", "c",
    "zig", "terraform", "hcl", "groovy", "java", "promql",
    "dockerfile", "go", "nix",
}

return {
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "nvim-treesitter/nvim-treesitter-textobjects",
        },
        config = function()
            require("nvim-treesitter").setup({})

            -- Install missing parsers on startup
            local installed = require("nvim-treesitter.config").get_installed()
            local installed_set = {}
            for _, p in ipairs(installed) do installed_set[p] = true end
            local to_install = {}
            for _, p in ipairs(parsers) do
                if not installed_set[p] then
                    table.insert(to_install, p)
                end
            end
            if #to_install > 0 then
                require("nvim-treesitter.install").install(to_install)
            end

            -- Enable treesitter highlighting and indentation for all buffers
            vim.api.nvim_create_autocmd("FileType", {
                callback = function()
                    pcall(vim.treesitter.start)
                    if vim.treesitter.query.get(vim.bo.filetype, "indents") then
                        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                    end
                end,
            })

            -- Configure textobjects
            require("nvim-treesitter-textobjects").setup({
                select = { lookahead = true },
                move = { set_jumps = true },
            })

            -- Select textobjects
            local ts_select = require("nvim-treesitter-textobjects.select")
            vim.keymap.set({ "x", "o" }, "af", function() ts_select.select_textobject("@function.outer", "textobjects") end, { desc = "Outer function" })
            vim.keymap.set({ "x", "o" }, "if", function() ts_select.select_textobject("@function.inner", "textobjects") end, { desc = "Inner function" })
            vim.keymap.set({ "x", "o" }, "ac", function() ts_select.select_textobject("@class.outer", "textobjects") end, { desc = "Outer class" })
            vim.keymap.set({ "x", "o" }, "ic", function() ts_select.select_textobject("@class.inner", "textobjects") end, { desc = "Inner class" })

            -- Move textobjects
            local ts_move = require("nvim-treesitter-textobjects.move")
            vim.keymap.set({ "n", "x", "o" }, "]m", function() ts_move.goto_next_start("@function.outer", "textobjects") end, { desc = "Next function" })
            vim.keymap.set({ "n", "x", "o" }, "[m", function() ts_move.goto_previous_start("@function.outer", "textobjects") end, { desc = "Prev function" })
            vim.keymap.set({ "n", "x", "o" }, "]c", function() ts_move.goto_next_start("@class.outer", "textobjects") end, { desc = "Next class" })
            vim.keymap.set({ "n", "x", "o" }, "[c", function() ts_move.goto_previous_start("@class.outer", "textobjects") end, { desc = "Prev class" })
        end,
    },

    {
        "nvim-treesitter/nvim-treesitter-context",
        event = "BufReadPost",
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
        },
        config = function()
            require("treesitter-context").setup({
                enable = true,
                max_lines = 3,
                trim_scope = "outer",
            })
        end,
    },
}
