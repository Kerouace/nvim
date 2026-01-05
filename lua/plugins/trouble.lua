return {
  {
    'folke/trouble.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    cmd = 'Trouble',
    keys = {
      {
        '<leader>lx',
        '<cmd>Trouble diagnostics toggle<cr>',
        desc = '[L]SP Trouble diagnostics',
      },
      {
        '<leader>lX',
        '<cmd>Trouble diagnostics toggle filter.buf=0<cr>',
        desc = '[L]SP Trouble buffer diagnostics',
      },
      {
        '<leader>ls',
        '<cmd>Trouble symbols toggle<cr>',
        desc = '[L]SP Document [S]ymbols (Trouble)',
      },
    },
    opts = {},
  },
}
