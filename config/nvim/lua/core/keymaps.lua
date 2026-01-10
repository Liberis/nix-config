local wk = require("which-key")
vim.g.mapleader = " "  -- Set space as the leader key

wk.add({
    -- 🔍 Search (Telescope)
    { "<leader>f", group = "Find" },
    { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find Files" },
    { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Live Grep" },
    { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Find Buffers" },
    { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Find Help Tags" },
    { "<leader>fc", "<cmd>Telescope commands<CR>", desc = "Find Commands" },
    { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent Files" },
    { "<leader>ft", "<cmd>Telescope file_browser<CR>", desc = "File Browser" },

    -- 🌳 Tree-sitter
    { "<leader>t", group = "Tree-sitter" },
    { "<leader>th", "<cmd>TSBufToggle highlight<CR>", desc = "Toggle Highlighting" },
    
    -- Incremental Selection
    { "<leader>ti", group = "Incremental Selection" },
    { "<leader>tin", "gnn", desc = "Start Selection" },
    { "<leader>tii", "grn", desc = "Expand Selection" },
    { "<leader>tiz", "grc", desc = "Scope Increment" },
    { "<leader>tid", "grm", desc = "Shrink Selection" },

    -- Folding
    { "<leader>tf", "<cmd>set foldmethod=expr foldexpr=nvim_treesitter#foldexpr()<CR>", desc = "Enable Folding" },
    { "<leader>tF", "<cmd>set foldmethod=manual<CR>", desc = "Disable Folding" },

    -- Debugging
    { "<leader>td", group = "Debugging" },
    { "<leader>tds", "<cmd>TSPlaygroundToggle<CR>", desc = "Toggle Playground" },
    { "<leader>tdh", "<cmd>TSHighlightCapturesUnderCursor<CR>", desc = "Highlight Captures" },

    -- Parser Management
    { "<leader>tp", "<cmd>TSUpdate<CR>", desc = "Update Parsers" },
    { "<leader>tP", "<cmd>TSInstallInfo<CR>", desc = "Show Installed Parsers" },
    { "<leader>tc", "<cmd>TSContextToggle<CR>", desc = "Toggle TS Context" },

    -- 📝 Git (LazyGit + Gitsigns)
    { "<leader>g", group = "Git" },
    { "<leader>gg", "<cmd>LazyGit<CR>", desc = "Open LazyGit" },
    { "<leader>gl", "<cmd>ToggleTerm cmd=lazygit<CR>", desc = "LazyGit Terminal" },
    { "<leader>gp", "<cmd>!git push<CR>", desc = "Git Push" },
    { "<leader>gd", "<cmd>!git diff<CR>", desc = "Git Diff" },
    { "<leader>gb", "<cmd>!git branch<CR>", desc = "Git Branch" },
    { "<leader>gs", "<cmd>!git status<CR>", desc = "Git Status" },

    -- 🔍 LSP Actions
    { "<leader>l", group = "LSP" },
    { "<leader>ld", "<cmd>lua vim.lsp.buf.definition()<CR>", desc = "Go to Definition" },
    { "<leader>lf", "<cmd>lua vim.lsp.buf.format()<CR>", desc = "Format Code" },
    { "<leader>lh", "<cmd>lua vim.lsp.buf.hover()<CR>", desc = "Hover Documentation" },
    { "<leader>li", "<cmd>lua vim.lsp.buf.implementation()<CR>", desc = "Go to Implementation" },
    { "<leader>lr", "<cmd>lua vim.lsp.buf.rename()<CR>", desc = "Rename Symbol" },
    { "<leader>nd", "<cmd>lua vim.diagnostic.open_float()<CR>", desc = "Show Diagnostics (Null-LS)" },

    -- Diagnostics Navigation
    { "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>", desc = "Previous Diagnostic" },
    { "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>", desc = "Next Diagnostic" },

    -- 📁 File Explorer (NeoTree)
    { "<leader>e",  "<cmd>Neotree toggle<cr>", desc = "toggle file explorer" },
    { "<leader>yf", "<cmd>Yazi<CR>", desc = "Toggle Yazi" },
    { "<leader>yp", "<cmd>YaziPicker<CR>", desc = "Toggle Yazi Picker" },

    -- 🪟 Window Management
    { "<leader>w", group = "Window" },
    { "<leader>wv", "<cmd>vsplit<CR>", desc = "Vertical Split" },
    { "<leader>wh", "<cmd>split<CR>", desc = "Horizontal Split" },
    { "<leader>wc", "<cmd>close<CR>", desc = "Close Split" },
    { "<leader>w=", "<cmd>wincmd =<CR>", desc = "Equalize Splits" },

    -- 🎨 UI Toggles
    { "<leader>u", group = "UI" },
    { "<leader>ui", "<cmd>IndentBlanklineToggle<CR>", desc = "Toggle Indent Guides" },
    { "<leader>uc", "<cmd>ColorizerToggle<CR>", desc = "Toggle Colorizer" },
    { "<leader>un", "<cmd>set relativenumber!<CR>", desc = "Toggle Relative Numbers" },
    { "<leader>uw", "<cmd>set wrap!<CR>", desc = "Toggle Word Wrap" },
    { "<leader>uh", "<cmd>nohlsearch<CR>", desc = "Clear Search Highlight" },

    -- 📋 Snippet Actions
    { "<leader>s", group = "Snippets" },
    { "<leader>ss", "<cmd>lua toggle_snippet_source()<CR>", desc = "Toggle Snippet Completion" },
    { "<leader>sr", "<cmd>lua require('luasnip').cleanup(); require('luasnip.loaders.from_lua').load({ paths = '~/.config/nvim/lua/snippets' })<CR>", desc = "Reload All Snippets" },

    -- 🔎 Aerial (Symbols Outline)
    { "<leader>a", group = "Aerial" },
    { "<leader>aa", "<cmd>AerialToggle!<CR>", desc = "Toggle Aerial" },
    { "<leader>an", "<cmd>AerialNext<CR>", desc = "Next Symbol" },
    { "<leader>ap", "<cmd>AerialPrev<CR>", desc = "Previous Symbol" },
    { "<leader>aj", "<cmd>AerialNext<CR>", desc = "Jump to Next Symbol" },
    { "<leader>ak", "<cmd>AerialPrev<CR>", desc = "Jump to Previous Symbol" },
    { "<leader>af", "<cmd>AerialOpen Float<CR>", desc = "Toggle Floating Aerial" },
    { "<leader>al", "<cmd>AerialNavToggle<CR>", desc = "Toggle Navigation" },
    
    -- NEW KEYMAPS FOR NEW PLUGINS

    -- ⚠️ Diagnostics & Trouble
    { "<leader>x", group = "Diagnostics" },
    { "<leader>xx", "<cmd>TroubleToggle<CR>", desc = "Toggle Trouble" },
    { "<leader>xw", "<cmd>TroubleToggle workspace_diagnostics<CR>", desc = "Workspace Diagnostics" },
    { "<leader>xd", "<cmd>TroubleToggle document_diagnostics<CR>", desc = "Document Diagnostics" },
    { "<leader>xq", "<cmd>TroubleToggle quickfix<CR>", desc = "Quickfix List" },
    { "<leader>xl", "<cmd>TroubleToggle loclist<CR>", desc = "Location List" },
    
    -- 📂 Session Management 
    { "<leader>S", group = "Session" },
    { "<leader>Ss", "<cmd>SaveSession<CR>", desc = "Save Session" },
    { "<leader>Sl", "<cmd>RestoreSession<CR>", desc = "Load Session" },
    { "<leader>Sd", "<cmd>DeleteSession<CR>", desc = "Delete Session" },
    
    -- 🔍 Search & Replace
    { "<leader>r", group = "Replace" },
    { "<leader>rr", "<cmd>lua require('spectre').open()<CR>", desc = "Open Spectre" },
    { "<leader>rw", "<cmd>lua require('spectre').open_visual({select_word=true})<CR>", desc = "Search Current Word" },
    { "<leader>rf", "<cmd>lua require('spectre').open_file_search()<CR>", desc = "Search in Current File" },
    
    -- 📑 Code Folding with UFO
    { "zR", "<cmd>lua require('ufo').openAllFolds()<CR>", desc = "Open All Folds" },
    { "zM", "<cmd>lua require('ufo').closeAllFolds()<CR>", desc = "Close All Folds" },
    { "zr", "<cmd>lua require('ufo').openFoldsExceptKinds()<CR>", desc = "Open Folds Except Kinds" },
    { "zm", "<cmd>lua require('ufo').closeFoldsWith()<CR>", desc = "Close Folds With" },
    { "zp", "<cmd>lua require('ufo').peekFoldedLinesUnderCursor()<CR>", desc = "Peek Fold" },
    
    -- 📝 Enhanced Telescope Commands
    { "<leader>fb", "<cmd>Telescope file_browser<CR>", desc = "File Browser" },
    { "<leader>fp", "<cmd>Telescope projects<CR>", desc = "Projects" },
    { "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>", desc = "Document Symbols" },
    { "<leader>fS", "<cmd>Telescope lsp_workspace_symbols<CR>", desc = "Workspace Symbols" },
    { "<leader>fd", "<cmd>Telescope diagnostics<CR>", desc = "Diagnostics" },
})
