return {
  {
    'ahmedkhalf/project.nvim',
    event = "VeryLazy",
    config = function()
      require("project_nvim").setup({
        detection_methods = { "pattern" },
        patterns = { ".git", "Makefile", "package.json", "CMakeLists.txt" },
        manual_mode = false, -- Auto-detect project root
        show_hidden = true, -- Include hidden files
      })
      
      -- Load Telescope extension for Project.nvim
      require("telescope").load_extension("projects")
    end
  }
}

