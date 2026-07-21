-- Treesitter — nvim-treesitter `main` branch (required for Neovim >= 0.12).
-- This is the rewrite: highlighting/indent are enabled per-buffer via the
-- native `vim.treesitter` API (the old `configs.setup{ highlight/indent }` and
-- the incremental-selection module no longer exist on `main`).

local ensure_installed = {
  'c', 'cpp', 'go', 'lua', 'python', 'rust',
  'tsx', 'javascript', 'typescript',
  'vimdoc', 'vim', 'bash', 'markdown', 'markdown_inline', 'yaml',
  'typst', 'verilog',
}

return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter').setup()

      -- Install any missing parsers (async, no-op if already present).
      require('nvim-treesitter').install(ensure_installed)

      -- Enable native treesitter highlighting + (experimental) indentation for
      -- every buffer whose filetype has a parser installed.
      local function enable(buf)
        if not pcall(vim.treesitter.start, buf) then
          return
        end
        vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end

      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('ts_highlight', { clear = true }),
        callback = function(args)
          enable(args.buf)
        end,
      })

      -- Buffers already open before this config ran (e.g. the file nvim was
      -- launched with) don't get the FileType event, so enable them now.
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
          enable(buf)
        end
      end
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      require('nvim-treesitter-textobjects').setup({
        select = { lookahead = true },
        move = { set_jumps = true },
      })

      local select = require('nvim-treesitter-textobjects.select')
      local move = require('nvim-treesitter-textobjects.move')
      local swap = require('nvim-treesitter-textobjects.swap')

      -- select
      vim.keymap.set({ 'x', 'o' }, 'aa', function() select.select_textobject('@parameter.outer', 'textobjects') end)
      vim.keymap.set({ 'x', 'o' }, 'ia', function() select.select_textobject('@parameter.inner', 'textobjects') end)
      vim.keymap.set({ 'x', 'o' }, 'af', function() select.select_textobject('@function.outer', 'textobjects') end)
      vim.keymap.set({ 'x', 'o' }, 'if', function() select.select_textobject('@function.inner', 'textobjects') end)
      vim.keymap.set({ 'x', 'o' }, 'ac', function() select.select_textobject('@class.outer', 'textobjects') end)
      vim.keymap.set({ 'x', 'o' }, 'ic', function() select.select_textobject('@class.inner', 'textobjects') end)

      -- move
      vim.keymap.set({ 'n', 'x', 'o' }, ']m', function() move.goto_next_start('@function.outer', 'textobjects') end)
      vim.keymap.set({ 'n', 'x', 'o' }, ']]', function() move.goto_next_start('@class.outer', 'textobjects') end)
      vim.keymap.set({ 'n', 'x', 'o' }, ']M', function() move.goto_next_end('@function.outer', 'textobjects') end)
      vim.keymap.set({ 'n', 'x', 'o' }, '][', function() move.goto_next_end('@class.outer', 'textobjects') end)
      vim.keymap.set({ 'n', 'x', 'o' }, '[m', function() move.goto_previous_start('@function.outer', 'textobjects') end)
      vim.keymap.set({ 'n', 'x', 'o' }, '[[', function() move.goto_previous_start('@class.outer', 'textobjects') end)
      vim.keymap.set({ 'n', 'x', 'o' }, '[M', function() move.goto_previous_end('@function.outer', 'textobjects') end)
      vim.keymap.set({ 'n', 'x', 'o' }, '[]', function() move.goto_previous_end('@class.outer', 'textobjects') end)

      -- swap
      vim.keymap.set('n', '<leader>a', function() swap.swap_next('@parameter.inner') end)
      vim.keymap.set('n', '<leader>A', function() swap.swap_previous('@parameter.inner') end)
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter-context',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    opts = {
      enable = true,
      trim_scope = 'outer',
    },
  },
}
