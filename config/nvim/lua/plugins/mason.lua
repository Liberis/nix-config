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
    dependencies = { "neovim/nvim-lspconfig" },
    config = function()
      require("mason-lspconfig").setup({})

      local lspconfig = require("lspconfig")

      -- Automatically configure all installed LSP servers
      local lspconfig = require("lspconfig")
      for _, server in ipairs(require("mason-lspconfig").get_installed_servers()) do
          lspconfig[server].setup({
              on_attach = function(client, bufnr)
                  print("LSP started for " .. vim.bo.filetype)
              end,
          })
      end
      -- Ensure LSP starts automatically when opening a file
      vim.api.nvim_create_autocmd("BufReadPost", {
          callback = function()
              local clients = vim.lsp.get_active_clients()
              if #clients == 0 then
                  vim.cmd("LspStart")
              end
          end,
      })
  end
  },

  -- Mason-Null-LS: Fully Dynamic Detection of Installed Formatters & Linters
  {
      "jay-babu/mason-null-ls.nvim",
      event = { "BufReadPost", "BufNewFile" },
      dependencies = { "jose-elias-alvarez/null-ls.nvim" },
      config = function()
          local null_ls = require("null-ls")
          local mason_registry = require("mason-registry")

          -- Get all installed Mason packages
          local installed_packages = mason_registry.get_installed_packages()

          -- Extract package names for quick lookup
          local installed_names = {}
          for _, package in ipairs(installed_packages) do
              installed_names[package.name] = true
          end

          -- Filter only installed formatters & linters
          local sources = {}

          -- Check installed formatters
          for name, builtin in pairs(null_ls.builtins.formatting) do
              if installed_names[name] then
                  table.insert(sources, builtin)
              end
          end

          -- Check installed linters
          for name, builtin in pairs(null_ls.builtins.diagnostics) do
              if installed_names[name] then
                  table.insert(sources, builtin)
              end
          end

          -- Set up Null-LS with dynamically detected sources
          null_ls.setup({ sources = sources })
      end
  }
}

