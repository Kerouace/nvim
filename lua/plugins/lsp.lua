-- LSP: Language Server Protocol configuration
-- Uses Neovim 0.11+ native vim.lsp.config API

return {
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
      { 'j-hui/fidget.nvim', tag = 'legacy', event = 'LspAttach', opts = {} },
      'folke/neodev.nvim',
    },
    config = function()
      -- Setup neodev first (for Neovim Lua API completion)
      require('neodev').setup()

      -- Enhanced capabilities with nvim-cmp
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

      -- LSP servers to configure
      local servers = {
        clangd = {},
        pyright = {},
        lua_ls = {
          settings = {
            Lua = {
              workspace = { checkThirdParty = 'Disable' },
              telemetry = { enable = false },
            },
          },
        },
        verible = {},
        ltex = {},
        texlab = {},
        yamlls = {},
        vhdl_ls = {},  -- VHDL language server (was incorrectly called rust_hdl)
      }

      -- Configure each server using new vim.lsp.config API
      for server_name, server_opts in pairs(servers) do
        local config = vim.tbl_deep_extend('force', {
          capabilities = capabilities,
        }, server_opts)
        vim.lsp.config[server_name] = config
      end

      -- Setup Mason
      require('mason').setup()

      -- NixOS vs other systems
      if vim.g.system_id == 'nixos' then
        -- On NixOS, servers are installed via Nix - just enable them
        for server_name, _ in pairs(servers) do
          vim.lsp.enable(server_name)
        end
      else
        -- On other systems, use Mason to install
        local ensure_installed = vim.tbl_keys(servers)
        vim.list_extend(ensure_installed, { 'stylua' })
        require('mason-tool-installer').setup({ ensure_installed = ensure_installed })
        require('mason-lspconfig').setup({
          handlers = {
            function(server_name)
              vim.lsp.enable(server_name)
            end,
          },
        })
      end

      -- Diagnostic signs in gutter
      local signs = { Error = ' ', Warn = ' ', Hint = ' ', Info = ' ' }
      for type, icon in pairs(signs) do
        local hl = 'DiagnosticSign' .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
      end

      -- LSP keymaps (set when LSP attaches to buffer)
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          local builtin = require('telescope.builtin')

          -- Goto mappings (keep g prefix - Vim convention)
          map('gd', builtin.lsp_definitions, '[G]oto [D]efinition')
          map('gr', builtin.lsp_references, '[G]oto [R]eferences')
          map('gI', builtin.lsp_implementations, '[G]oto [I]mplementation')
          map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          -- LSP actions under <leader>l
          map('<leader>lr', vim.lsp.buf.rename, '[L]SP [R]ename')
          map('<leader>la', vim.lsp.buf.code_action, '[L]SP Code [A]ction')
          map('<leader>ld', builtin.lsp_document_symbols, '[L]SP [D]ocument Symbols')
          map('<leader>lw', builtin.lsp_dynamic_workspace_symbols, '[L]SP [W]orkspace Symbols')
          map('<leader>lt', builtin.lsp_type_definitions, '[L]SP [T]ype Definition')

          -- Highlight references on cursor hold
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
            local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })

            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds({ group = 'lsp-highlight', buffer = event2.buf })
              end,
            })
          end

          -- Inlay hints (enabled by default, toggle with <leader>lh)
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
            vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
            map('<leader>lh', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
            end, '[L]SP Toggle Inlay [H]ints')
          end
        end,
      })
    end,
  },
}
