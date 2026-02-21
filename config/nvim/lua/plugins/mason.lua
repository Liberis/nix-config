return {
  -- Mason: Auto-installs LSP, formatters, and linters
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end
  },

  -- Mason-LSPConfig: Auto-configures LSP servers dynamically
  {
    "williamboman/mason-lspconfig.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "neovim/nvim-lspconfig", "hrsh7th/cmp-nvim-lsp" },
    config = function()
      require("mason-lspconfig").setup({})

      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      for _, server in ipairs(require("mason-lspconfig").get_installed_servers()) do
        lspconfig[server].setup({
          capabilities = capabilities,
        })
      end
    end
  },

  -- Mason-Null-LS: Fully Dynamic Detection of Installed Formatters & Linters
  {
      "jay-babu/mason-null-ls.nvim",
      event = { "BufReadPost", "BufNewFile" },
      dependencies = { "nvimtools/none-ls.nvim" },
      config = function()
          local null_ls = require("null-ls")
          local mason_registry = require("mason-registry")

          local installed_packages = mason_registry.get_installed_packages()

          local installed_names = {}
          for _, package in ipairs(installed_packages) do
              installed_names[package.name] = true
          end

          local sources = {}

          for name, builtin in pairs(null_ls.builtins.formatting) do
              if installed_names[name] then
                  table.insert(sources, builtin)
              end
          end

          for name, builtin in pairs(null_ls.builtins.diagnostics) do
              if installed_names[name] then
                  table.insert(sources, builtin)
              end
          end

          null_ls.setup({ sources = sources })
      end
  }
}
