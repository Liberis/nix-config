-- Auto-save session on exit
vim.api.nvim_create_autocmd("VimLeavePre", {
    pattern = "*",
    command = "mksession! ~/.config/nvim/session.vim"
})

-- Auto-format on save (using LSP)
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*",
    callback = function()
        -- Check if an LSP supporting formatting is attached
        local clients = vim.lsp.get_active_clients({ bufnr = 0 })
        for _, client in ipairs(clients) do
            if client.supports_method("textDocument/formatting") then
                vim.lsp.buf.format({ async = false })
                break
            end
        end
    end,
})

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
    pattern = "*",
    callback = function()
        vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
    end
})

-- Auto-resize splits when the window is resized
-- vim.api.nvim_create_autocmd("VimResized", {
--     pattern = "*",
--     command = "wincmd ="
-- })
-- -- vim.opt.cmdheight = 0  -- Hide command line when not in use
--
-- -- Automatically show the command line when entering command mode
-- vim.api.nvim_create_autocmd("CmdlineEnter", {
--     pattern = "[:/?]",
--     callback = function() vim.opt.cmdheight = 1 end,
-- })
--
--
-- -- Autohide command line bar
-- vim.api.nvim_create_autocmd("CmdlineLeave", {
--     pattern = "[:/?]",
--     callback = function() vim.opt.cmdheight = 0 end,
-- })

