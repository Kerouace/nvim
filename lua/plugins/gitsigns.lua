return {
  { -- Adds git releated signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',  -- [Okay?]
    opts = {
      -- See `:help gitsigns.txt`
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
      -- Inline blame on by default
      current_line_blame = true,
      current_line_blame_opts = {
        delay = 200,
      },
      on_attach = function(bufnr)
        local gs = require('gitsigns')
        vim.keymap.set('n', '<leader>gp', gs.prev_hunk, { buffer = bufnr, desc = '[G]it [P]revious Hunk' })
        vim.keymap.set('n', '<leader>gn', gs.next_hunk, { buffer = bufnr, desc = '[G]it [N]ext Hunk' })
        vim.keymap.set('n', '<leader>gh', gs.preview_hunk, { buffer = bufnr, desc = '[G]it Preview [H]unk' })
        vim.keymap.set('n', '<leader>gb', gs.toggle_current_line_blame, { buffer = bufnr, desc = '[G]it Toggle [B]lame' })
      end,
    },
  }
}

