local opt = vim.opt

-- Set leader key to space in Lua
vim.g.mapleader = " "

-- Disable space from moving the cursor in Visual Mode
vim.api.nvim_set_keymap('x', '<Space>', '<Nop>', { noremap = true, silent = true })

-- Make space work as leader key in Visual Mode
vim.api.nvim_set_keymap('v', '<Space>', '<Leader>', { noremap = true, silent = true })

-- Enable true color support
opt.termguicolors = true
vim.o.confirm = false
-- Enable line numbers
opt.number = true
opt.relativenumber = false

-- Clipboard
opt.clipboard = "unnamedplus"

-- Indentation settings

opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4

-- Enable mouse support
opt.mouse = 'a'

-- Enable line wrapping
opt.wrap = true

-- Show matching brackets
opt.showmatch = true

-- Always show status line
opt.laststatus = 2

-- Improve search behavior
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true

-- Highlight current line
opt.cursorline = true

-- Enable syntax highlighting
vim.cmd('syntax on')
-- Treesitter
-- Set folding method to expr for Tree-sitter folding
vim.o.foldmethod = "expr"
vim.o.foldexpr = "nvim_treesitter#foldexpr()"
vim.o.foldenable = true -- Enable folding by default
vim.opt.foldenable = false
-- Diagnostics
vim.diagnostic.config({
    virtual_text = true, -- Show inline errors
    signs = true,        -- Show gutter signs (🔴, ⚠️)
    underline = true,    -- Underline errors
    update_in_insert = false, -- Don't update while typing
    severity_sort = true, -- Show severe errors first
})

