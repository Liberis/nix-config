return {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "BufReadPost",
    opts = {
        signs = true,
        sign_priority = 8,
        highlight = {
            multiline = false,
            before = "",
            keyword = "bg",
            after = "fg",
            pattern = [[.*<(KEYWORDS)\s*:]],
        },
    },
}
