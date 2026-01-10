return
{
  "kylechui/nvim-surround",
  version = "*", -- Use latest version
  event = "VeryLazy",
  config = function()
    require("nvim-surround").setup({})
  end
}
