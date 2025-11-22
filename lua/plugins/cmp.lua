-- Completion: nvim-cmp and LuaSnip configuration

return {
  -- Snippet engine
  {
    'L3MON4D3/LuaSnip',
    version = 'v2.*',
    build = 'make install_jsregexp',
    config = function()
      local luasnip = require('luasnip')

      luasnip.config.set_config({
        enable_autosnippets = true,
        store_selection_keys = '<Tab>',
      })

      -- Load snippets from files
      require('luasnip.loaders.from_lua').lazy_load({ path = '$XDG_CONFIG_HOME/nvim/luasnippets' })
      require('luasnip.loaders.from_snipmate').lazy_load({ path = '$XDG_CONFIG_HOME/nvim/snippets' })

      -- Keymap to edit snippets
      vim.keymap.set('n', '<leader>es', function()
        require('luasnip.loaders').edit_snippet_files()
      end, { desc = '[E]dit [S]nippets' })
    end,
  },

  -- Completion engine
  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-buffer',
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
      'onsails/lspkind-nvim',
    },
    config = function()
      local cmp = require('cmp')
      local luasnip = require('luasnip')
      local lspkind = require('lspkind')

      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match('%s') == nil
      end

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },

        mapping = cmp.mapping.preset.insert({
          ['<C-d>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete({}),
          ['<CR>'] = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false }),

          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            elseif has_words_before() then
              cmp.complete()
            else
              fallback()
            end
          end, { 'i', 's' }),

          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
        }),

        sources = {
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'path' },
          { name = 'buffer' },
        },

        formatting = {
          format = lspkind.cmp_format({
            mode = 'symbol_text',
            preset = 'codicons',
            maxwidth = 50,
            menu = {
              nvim_lsp = '[LSP]',
              path = '[PATH]',
              buffer = '[BUF]',
              luasnip = '[SNIP]',
            },
            symbol_map = {
              Text = '',
              Method = '',
              Function = '',
              Constructor = '',
              Field = 'ﰠ',
              Variable = '',
              Class = 'ﴯ',
              Interface = '',
              Module = '',
              Property = 'ﰠ',
              Unit = '塞',
              Value = '',
              Enum = '',
              Keyword = '',
              Snippet = '',
              Color = '',
              File = '',
              Reference = '',
              Folder = '',
              EnumMember = '',
              Constant = '',
              Struct = 'פּ',
              Event = '',
              Operator = '',
              TypeParameter = '',
            },
          }),
        },
      })
    end,
  },
}
