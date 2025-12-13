return
{
    "mikavilpas/yazi.nvim",
    config = function()
        require("yazi").setup({
            open_for_directories = true, -- Open Yazi when opening a directory
            floating_window = false,      -- Open in a floating window
        })  end
    }

