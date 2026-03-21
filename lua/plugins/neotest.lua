-- Neotest: Test runner framework for Neovim

return {
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'antoinemadec/FixCursorHold.nvim',
      'nvim-neotest/neotest-python',
    },
    config = function()
      require('neotest').setup({
        adapters = {
          require('neotest-python')({
            dap = { justMyCode = false },
            runner = 'pytest',
            pytest_discover_instances = true,
          }),
        },
        status = {
          virtual_text = true,
        },
        output = {
          open_on_run = false,
        },
      })

      -- Keymaps
      local map = vim.keymap.set
      local neotest = require('neotest')

      map('n', '<leader>tt', function() neotest.run.run() end, { desc = '[T]est: Run nearest [T]est' })
      map('n', '<leader>tf', function() neotest.run.run(vim.fn.expand('%')) end, { desc = '[T]est: Run [F]ile' })
      map('n', '<leader>ta', function() neotest.run.run(vim.fn.getcwd()) end, { desc = '[T]est: Run [A]ll' })
      map('n', '<leader>ts', function() neotest.summary.toggle() end, { desc = '[T]est: Toggle [S]ummary' })
      map('n', '<leader>to', function() neotest.output.open({ enter = true, auto_close = true }) end, { desc = '[T]est: Show [O]utput' })
      map('n', '<leader>tO', function() neotest.output_panel.toggle() end, { desc = '[T]est: Toggle [O]utput panel' })
      map('n', '<leader>tx', function() neotest.run.stop() end, { desc = '[T]est: Stop' })
      map('n', '[t', function() neotest.jump.prev({ status = 'failed' }) end, { desc = 'Jump to previous failed test' })
      map('n', ']t', function() neotest.jump.next({ status = 'failed' }) end, { desc = 'Jump to next failed test' })
    end,
  },
}
