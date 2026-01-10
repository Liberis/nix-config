return {
    'kdheepak/lazygit.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    cmd = "LazyGit",
    keys = {
        { "<leader>gg", "<cmd>LazyGit<CR>", desc = "Open LazyGit" },
    },
    config = function()
        vim.g.lazygit_floating_window_use_plenary = 1
    end
}
