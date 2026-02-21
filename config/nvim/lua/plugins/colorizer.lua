return {
    'NvChad/nvim-colorizer.lua',
    cmd = "ColorizerToggle",
    event = "BufReadPost",
    config = function() require('colorizer').setup({}) end
}
