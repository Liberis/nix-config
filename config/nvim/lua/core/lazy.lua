local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- Function to auto-import all plugins in `lua/plugins/`
local function import_plugins()
    local plugin_dir = vim.fn.stdpath("config") .. "/lua/plugins"
    local plugins = {}

    for _, file in ipairs(vim.fn.readdir(plugin_dir)) do
        if file:match("%.lua$") then
            local plugin_name = file:gsub("%.lua$", "")
            table.insert(plugins, { import = "plugins." .. plugin_name })
        end
    end

    return plugins
end

require("lazy").setup(import_plugins())

