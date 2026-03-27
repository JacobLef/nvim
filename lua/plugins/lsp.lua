return {
  {
    "williamboman/mason.nvim",
    opts = { ui = { border = "rounded" } },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = {
        "clangd", "gopls", "pyright", "lua_ls",
        "bashls", "yamlls", "jsonls",
      },
      automatic_installation = true,
    },
  },
  { "hrsh7th/cmp-nvim-lsp", lazy = true },
  { "j-hui/fidget.nvim", event = { "BufReadPre", "BufNewFile" }, opts = {} },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
      "j-hui/fidget.nvim",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      vim.lsp.config("*", { capabilities = capabilities })

      vim.lsp.config("clangd", {
        cmd = {
          "clangd", "--background-index", "--clang-tidy",
          "--header-insertion=iwyu", "--completion-style=detailed",
          "--function-arg-placeholders", "--fallback-style=llvm",
        },
      })

      vim.lsp.config("gopls", {
        settings = { gopls = {
          analyses = { unusedparams = true, shadow = true, nilness = true, unusedwrite = true },
          staticcheck = true, gofumpt = true, usePlaceholders = true,
          hints = { assignVariableTypes = true, compositeLiteralFields = true,
            constantValues = true, parameterNames = true },
        }},
      })

      vim.lsp.config("rust_analyzer", {
        settings = { ["rust-analyzer"] = {
          cargo = { allFeatures = true },
          checkOnSave = { command = "clippy" },
          procMacro = { enable = true },
          inlayHints = { bindingModeHints = { enable = true },
            closureReturnTypeHints = { enable = "always" },
            lifetimeElisionHints = { enable = "always" } },
        }},
      })

      vim.lsp.config("pyright", {
        settings = { python = { analysis = {
          typeCheckingMode = "basic", autoImportCompletions = true,
        }}},
      })

      vim.lsp.config("lua_ls", {
        settings = { Lua = {
          runtime = { version = "LuaJIT" },
          workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
          completion = { callSnippet = "Replace" },
          diagnostics = { globals = { "vim" } },
        }},
      })

      vim.lsp.enable({
        "clangd", "gopls", "rust_analyzer", "pyright",
        "lua_ls", "bashls", "yamlls", "jsonls",
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("LspKeymaps", { clear = true }),
        callback = function(ev)
          local buf = ev.buf
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          local map = function(k, f, d)
            vim.keymap.set("n", k, f, { buffer = buf, desc = "LSP: " .. d })
          end
          map("gd", vim.lsp.buf.definition, "Go to definition")
          map("gD", vim.lsp.buf.declaration, "Go to declaration")
          map("gi", vim.lsp.buf.implementation, "Go to implementation")
          map("gr", vim.lsp.buf.references, "Find references")
          map("K", vim.lsp.buf.hover, "Hover documentation")
          map("<leader>ca", vim.lsp.buf.code_action, "Code actions")
          map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>D", vim.lsp.buf.type_definition, "Type definition")
          map("]d", vim.diagnostic.goto_next, "Next diagnostic")
          map("[d", vim.diagnostic.goto_prev, "Previous diagnostic")
          map("<leader>d", vim.diagnostic.open_float, "Show diagnostic")
          map("<leader>fm", function() vim.lsp.buf.format({ async = true }) end, "Format")
          if client and client.supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = buf })
          end
        end,
      })

      vim.diagnostic.config({
        virtual_text = { spacing = 4, prefix = "●" },
        signs = true, underline = true, update_in_insert = false,
        severity_sort = true, float = { border = "rounded", source = true },
      })
      local signs = { Error = " ", Warn = " ", Hint = "󰌵 ", Info = " " }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
      end
    end,
  },
}
