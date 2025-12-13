return {
    "hrsh7th/nvim-cmp",
    dependencies = {
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-nvim-lua",
        "saadparwaiz1/cmp_luasnip",
        "L3MON4D3/LuaSnip",
        "rafamadriz/friendly-snippets"
    },
    event = "InsertEnter",
    config = function()
        local cmp = require("cmp")
        local friendly_snippets_enabled = false

        -- Toggle function for Friendly Snippets
        local function toggle_snippet_source()
            local sources = cmp.get_config().sources
            if friendly_snippets_enabled then
                cmp.setup({ sources = vim.tbl_filter(function(src) return src.name ~= "luasnip" end, sources) })
                print("Friendly Snippets: OFF")
            else
                table.insert(sources, { name = "luasnip" })
                cmp.setup({ sources = sources })
                print("Friendly Snippets: ON")
                require("luasnip.loaders.from_vscode").lazy_load()
            end
            friendly_snippets_enabled = not friendly_snippets_enabled
        end

        -- Expose toggle function globally
        _G.toggle_snippet_source = toggle_snippet_source

        -- Setup CMP
        cmp.setup({
            snippet = {
                expand = function(args)
                    require("luasnip").lsp_expand(args.body)
                end,
            },
            mapping = cmp.mapping.preset.insert({
                ["<C-Space>"] = cmp.mapping.complete(),
                ["<CR>"] = cmp.mapping.confirm({ select = true }),
                ["<Tab>"] = cmp.mapping.select_next_item(),
                ["<S-Tab>"] = cmp.mapping.select_prev_item(),
            }),
            sources = cmp.config.sources({
                { name = "nvim_lsp" },
                { name = "luasnip" },
                { name = "buffer" },
                { name = "path" },
            }),
        })
    end
}

