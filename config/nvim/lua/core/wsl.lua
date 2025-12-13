if vim.fn.has("wsl") == 1 then
    local clip = "/mnt/c/Windows/System32/clip.exe"
    if vim.fn.executable(clip) == 1 then
        vim.api.nvim_create_autocmd("TextYankPost", {
            group = vim.api.nvim_create_augroup("WSLYank", { clear = true }),
            pattern = "*",
            callback = function()
                if vim.v.event.operator == "y" then
                    vim.fn.system(clip, vim.fn.getreg('"'))
                end
            end,
        })
    end
end
