-- Telescope: Fuzzy finder for files, grep, LSP, etc.

return {
  {
    'nvim-telescope/telescope.nvim',
    version = '*',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('telescope').setup({
        defaults = {
          mappings = {
            i = {
              ['<C-u>'] = false,
              ['<C-d>'] = false,
            },
          },
        },
        pickers = {
          find_files = {
            follow = true,  -- Follow symlinks
          },
        },
      })

      -- Load fzf extension if available
      pcall(require('telescope').load_extension, 'fzf')

      -- Keymaps
      local builtin = require('telescope.builtin')
      local map = vim.keymap.set

      map('n', '<leader>?', builtin.oldfiles, { desc = '[?] Find recently opened files' })
      map('n', '<leader><space>', builtin.buffers, { desc = '[ ] Find existing buffers' })
      map('n', '<leader>/', function()
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown({
          winblend = 10,
          previewer = false,
        }))
      end, { desc = '[/] Fuzzily search in current buffer' })

      map('n', '<leader>gf', builtin.git_files, { desc = 'Search [G]it [F]iles' })
      map('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      map('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      map('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      map('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      map('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
    end,
  },

  -- FZF algorithm for faster fuzzy matching
  {
    'nvim-telescope/telescope-fzf-native.nvim',
    build = 'make',
    cond = function()
      return vim.fn.executable('make') == 1
    end,
  },
}
