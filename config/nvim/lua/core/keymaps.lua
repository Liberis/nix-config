local wk = require("which-key")

-- Lazygit terminal (created on first use)
local lazygit_term = nil
local function toggle_lazygit()
    if not lazygit_term then
        local Terminal = require("toggleterm.terminal").Terminal
        lazygit_term = Terminal:new({
            cmd = "lazygit",
            dir = "git_dir",
            direction = "float",
            float_opts = { border = "curved" },
            on_open = function() vim.cmd("startinsert!") end,
        })
    end
    lazygit_term:toggle()
end

wk.add({
    -----------------------------------------------------------------------
    -- Find (Telescope)
    -----------------------------------------------------------------------
    { "<leader>f", group = "Find" },
    { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find Files" },
    { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Live Grep" },
    { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Find Buffers" },
    { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Find Help Tags" },
    { "<leader>fc", "<cmd>Telescope commands<CR>", desc = "Find Commands" },
    { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent Files" },
    { "<leader>ft", "<cmd>TodoTelescope<CR>", desc = "Search TODOs" },
    { "<leader>fB", "<cmd>Telescope file_browser<CR>", desc = "File Browser" },
    { "<leader>fp", "<cmd>Telescope projects<CR>", desc = "Projects" },
    { "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>", desc = "Document Symbols" },
    { "<leader>fS", "<cmd>Telescope lsp_workspace_symbols<CR>", desc = "Workspace Symbols" },
    { "<leader>fd", "<cmd>Telescope diagnostics<CR>", desc = "Diagnostics" },

    -----------------------------------------------------------------------
    -- Tree-sitter
    -----------------------------------------------------------------------
    { "<leader>t", group = "Tree-sitter" },
    { "<leader>th", "<cmd>TSBufToggle highlight<CR>", desc = "Toggle Highlighting" },
    { "<leader>ti", group = "Incremental Selection" },
    { "<leader>tin", "gnn", desc = "Start Selection" },
    { "<leader>tii", "grn", desc = "Expand Selection" },
    { "<leader>tiz", "grc", desc = "Scope Increment" },
    { "<leader>tid", "grm", desc = "Shrink Selection" },
    { "<leader>td", group = "TS Debugging" },
    { "<leader>tds", "<cmd>InspectTree<CR>", desc = "Inspect Tree" },
    { "<leader>tdh", "<cmd>Inspect<CR>", desc = "Inspect Highlights" },
    { "<leader>tp", "<cmd>TSUpdate<CR>", desc = "Update Parsers" },
    { "<leader>tP", "<cmd>TSInstallInfo<CR>", desc = "Show Installed Parsers" },
    { "<leader>tc", "<cmd>TSContextToggle<CR>", desc = "Toggle TS Context" },

    -----------------------------------------------------------------------
    -- Git
    -----------------------------------------------------------------------
    { "<leader>g", group = "Git" },
    { "<leader>gg", toggle_lazygit, desc = "LazyGit" },
    { "<leader>gp", function()
        local Terminal = require("toggleterm.terminal").Terminal
        Terminal:new({ cmd = "git push", direction = "float", close_on_exit = false }):toggle()
    end, desc = "Git Push" },
    { "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Open Diff View" },
    { "<leader>gH", "<cmd>DiffviewFileHistory %<CR>", desc = "File History" },
    { "<leader>gD", "<cmd>DiffviewClose<CR>", desc = "Close Diff View" },

    -- Git Hunks (gitsigns)
    { "<leader>gh", group = "Hunks" },
    { "<leader>ghs", function() require("gitsigns").stage_hunk() end, desc = "Stage Hunk" },
    { "<leader>ghr", function() require("gitsigns").reset_hunk() end, desc = "Reset Hunk" },
    { "<leader>ghs", function() require("gitsigns").stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, mode = "v", desc = "Stage Hunk" },
    { "<leader>ghr", function() require("gitsigns").reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, mode = "v", desc = "Reset Hunk" },
    { "<leader>ghS", function() require("gitsigns").stage_buffer() end, desc = "Stage Buffer" },
    { "<leader>ghp", function() require("gitsigns").preview_hunk() end, desc = "Preview Hunk" },
    { "<leader>ghb", function() require("gitsigns").blame_line({ full = true }) end, desc = "Blame Line" },

    -----------------------------------------------------------------------
    -- Harpoon
    -----------------------------------------------------------------------
    { "<leader>h", group = "Harpoon" },
    { "<leader>ha", function() require("harpoon"):list():add() end, desc = "Add File" },
    { "<leader>hh", function()
        local harpoon = require("harpoon")
        harpoon.ui:toggle_quick_menu(harpoon:list())
    end, desc = "Quick Menu" },
    { "<leader>1", function() require("harpoon"):list():select(1) end, desc = "Harpoon 1" },
    { "<leader>2", function() require("harpoon"):list():select(2) end, desc = "Harpoon 2" },
    { "<leader>3", function() require("harpoon"):list():select(3) end, desc = "Harpoon 3" },
    { "<leader>4", function() require("harpoon"):list():select(4) end, desc = "Harpoon 4" },

    -----------------------------------------------------------------------
    -- LSP
    -----------------------------------------------------------------------
    { "<leader>l", group = "LSP" },
    { "<leader>ld", vim.lsp.buf.definition, desc = "Go to Definition" },
    { "<leader>lf", function() vim.lsp.buf.format() end, desc = "Format Code" },
    { "<leader>lh", vim.lsp.buf.hover, desc = "Hover Documentation" },
    { "<leader>li", vim.lsp.buf.implementation, desc = "Go to Implementation" },
    { "<leader>lr", function() return ":IncRename " .. vim.fn.expand("<cword>") end, expr = true, desc = "Rename Symbol" },
    { "<leader>la", vim.lsp.buf.code_action, desc = "Code Actions" },
    { "<leader>ll", vim.lsp.buf.references, desc = "References" },
    { "<leader>ls", vim.lsp.buf.signature_help, desc = "Signature Help" },
    { "<leader>lt", vim.lsp.buf.type_definition, desc = "Type Definition" },
    { "<leader>lI", function()
        local bufnr = vim.api.nvim_get_current_buf()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
    end, desc = "Toggle Inlay Hints" },

    { "<leader>nd", vim.diagnostic.open_float, desc = "Show Diagnostics" },

    -----------------------------------------------------------------------
    -- Debug (DAP)
    -----------------------------------------------------------------------
    { "<leader>d", group = "Debug" },
    { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
    { "<leader>dc", function() require("dap").continue() end, desc = "Continue" },
    { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
    { "<leader>do", function() require("dap").step_over() end, desc = "Step Over" },
    { "<leader>dO", function() require("dap").step_out() end, desc = "Step Out" },
    { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
    { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },

    -----------------------------------------------------------------------
    -- Test (Neotest)
    -----------------------------------------------------------------------
    { "<leader>T", group = "Test" },
    { "<leader>Tn", function() require("neotest").run.run() end, desc = "Run Nearest" },
    { "<leader>Tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run File" },
    { "<leader>Ts", function() require("neotest").summary.toggle() end, desc = "Toggle Summary" },
    { "<leader>To", function() require("neotest").output.open({ enter = true }) end, desc = "Show Output" },

    -----------------------------------------------------------------------
    -- Session (Persistence)
    -----------------------------------------------------------------------
    { "<leader>S", group = "Session" },
    { "<leader>Ss", function() require("persistence").load() end, desc = "Load Session" },
    { "<leader>Sl", function() require("persistence").select() end, desc = "Select Session" },
    { "<leader>Sd", function() require("persistence").stop() end, desc = "Stop Auto-Save" },

    -----------------------------------------------------------------------
    -- Buffers
    -----------------------------------------------------------------------
    { "<leader>b", group = "Buffers" },
    { "<leader>bn", "<cmd>BufferLineCycleNext<CR>", desc = "Next Buffer" },
    { "<leader>bp", "<cmd>BufferLineCyclePrev<CR>", desc = "Previous Buffer" },
    { "<leader>bc", "<cmd>bdelete<CR>", desc = "Close Buffer" },

    -----------------------------------------------------------------------
    -- File Explorer
    -----------------------------------------------------------------------
    { "<leader>e",  "<cmd>Neotree toggle<cr>", desc = "Toggle File Explorer" },
    { "<leader>yf", "<cmd>Yazi<CR>", desc = "Toggle Yazi" },
    { "<leader>yp", "<cmd>YaziPicker<CR>", desc = "Toggle Yazi Picker" },

    -----------------------------------------------------------------------
    -- Window Management
    -----------------------------------------------------------------------
    { "<leader>w", group = "Window" },
    { "<leader>wv", "<cmd>vsplit<CR>", desc = "Vertical Split" },
    { "<leader>wh", "<cmd>split<CR>", desc = "Horizontal Split" },
    { "<leader>wc", "<cmd>close<CR>", desc = "Close Split" },
    { "<leader>w=", "<cmd>wincmd =<CR>", desc = "Equalize Splits" },

    -----------------------------------------------------------------------
    -- UI Toggles
    -----------------------------------------------------------------------
    { "<leader>u", group = "UI" },
    { "<leader>ui", "<cmd>IBLToggle<CR>", desc = "Toggle Indent Guides" },
    { "<leader>uc", "<cmd>ColorizerToggle<CR>", desc = "Toggle Colorizer" },
    { "<leader>un", "<cmd>set relativenumber!<CR>", desc = "Toggle Relative Numbers" },
    { "<leader>uw", "<cmd>set wrap!<CR>", desc = "Toggle Word Wrap" },
    { "<leader>uh", "<cmd>nohlsearch<CR>", desc = "Clear Search Highlight" },
    { "<leader>uu", "<cmd>UndotreeToggle<CR>", desc = "Toggle Undo Tree" },

    -----------------------------------------------------------------------
    -- Snippets
    -----------------------------------------------------------------------
    { "<leader>s", group = "Snippets" },
    { "<leader>ss", "<cmd>lua toggle_snippet_source()<CR>", desc = "Toggle Snippet Completion" },
    { "<leader>sr", "<cmd>lua require('luasnip').cleanup(); require('luasnip.loaders.from_lua').load({ paths = '~/.config/nvim/lua/snippets' })<CR>", desc = "Reload All Snippets" },

    -----------------------------------------------------------------------
    -- Aerial (Symbols Outline)
    -----------------------------------------------------------------------
    { "<leader>a", group = "Aerial" },
    { "<leader>aa", "<cmd>AerialToggle!<CR>", desc = "Toggle Aerial" },
    { "<leader>an", "<cmd>AerialNext<CR>", desc = "Next Symbol" },
    { "<leader>ap", "<cmd>AerialPrev<CR>", desc = "Previous Symbol" },
    { "<leader>af", "<cmd>AerialOpen Float<CR>", desc = "Toggle Floating Aerial" },
    { "<leader>al", "<cmd>AerialNavToggle<CR>", desc = "Toggle Navigation" },

    -----------------------------------------------------------------------
    -- Diagnostics & Trouble
    -----------------------------------------------------------------------
    { "<leader>x", group = "Diagnostics" },
    { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Toggle Trouble" },
    { "<leader>xw", "<cmd>Trouble diagnostics toggle filter.severity=vim.diagnostic.severity.WARN<CR>", desc = "Warnings" },
    { "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Document Diagnostics" },
    { "<leader>xq", "<cmd>Trouble qflist toggle<CR>", desc = "Quickfix List" },
    { "<leader>xl", "<cmd>Trouble loclist toggle<CR>", desc = "Location List" },

    -----------------------------------------------------------------------
    -- Search & Replace
    -----------------------------------------------------------------------
    { "<leader>r", group = "Replace" },
    { "<leader>rr", function() require("spectre").open() end, desc = "Open Spectre" },
    { "<leader>rw", function() require("spectre").open_visual({ select_word = true }) end, desc = "Search Current Word" },
    { "<leader>rf", function() require("spectre").open_file_search() end, desc = "Search in Current File" },

    -----------------------------------------------------------------------
    -- Code Folding (UFO)
    -----------------------------------------------------------------------
    { "zR", function() require("ufo").openAllFolds() end, desc = "Open All Folds" },
    { "zM", function() require("ufo").closeAllFolds() end, desc = "Close All Folds" },
    { "zr", function() require("ufo").openFoldsExceptKinds() end, desc = "Open Folds Except Kinds" },
    { "zm", function() require("ufo").closeFoldsWith() end, desc = "Close Folds With" },
    { "zp", function() require("ufo").peekFoldedLinesUnderCursor() end, desc = "Peek Fold" },

    -----------------------------------------------------------------------
    -- Navigation (bracket motions)
    -----------------------------------------------------------------------
    { "[d", vim.diagnostic.goto_prev, desc = "Previous Diagnostic" },
    { "]d", vim.diagnostic.goto_next, desc = "Next Diagnostic" },
    { "]q", "<cmd>cnext<CR>", desc = "Next Quickfix" },
    { "[q", "<cmd>cprev<CR>", desc = "Prev Quickfix" },
    { "]t", function() require("todo-comments").jump_next() end, desc = "Next TODO" },
    { "[t", function() require("todo-comments").jump_prev() end, desc = "Prev TODO" },
    { "]h", function()
        if vim.wo.diff then vim.cmd.normal({ "]c", bang = true }) else require("gitsigns").nav_hunk("next") end
    end, desc = "Next Hunk" },
    { "[h", function()
        if vim.wo.diff then vim.cmd.normal({ "[c", bang = true }) else require("gitsigns").nav_hunk("prev") end
    end, desc = "Prev Hunk" },
})

-- Terminal mode: toggle terminal with same key
vim.keymap.set("n", "<C-\\>", "<cmd>ToggleTerm<CR>", { silent = true, desc = "Toggle Terminal" })
vim.keymap.set("t", "<C-\\>", "<cmd>ToggleTerm<CR>", { silent = true, desc = "Toggle Terminal" })
