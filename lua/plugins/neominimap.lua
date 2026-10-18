return {
  -- zoomed-out "pixel" map of the buffer, with diagnostic/git/search markers
  {
    'Isrothy/neominimap.nvim',
    version = 'v3.x.x',
    lazy = false, -- config must be set before the plugin loads
    keys = {
      { '<leader>vv', '<cmd>Neominimap Toggle<cr>',      desc = 'Minimap: toggle (global)' },
      { '<leader>vb', '<cmd>Neominimap BufToggle<cr>',   desc = 'Minimap: toggle (buffer)' },
      { '<leader>vf', '<cmd>Neominimap ToggleFocus<cr>', desc = 'Minimap: toggle focus' },
      { '<leader>vr', '<cmd>Neominimap Refresh<cr>',     desc = 'Minimap: refresh' },
    },
    init = function()
      vim.g.neominimap = {
        auto_enable = true,
        layout = 'float',
        float = {
          minimap_width = 16,
          window_border = 'none',
        },
        exclude_filetypes = {
          'help',
          'bigfile',
          'alpha',
          'neo-tree',
          'oil',
          'trouble',
          'undotree',
          'diff',
          'dapui_scopes',
          'dapui_breakpoints',
          'dapui_stacks',
          'dapui_watches',
          'dapui_console',
          'dap-repl',
          'lazy',
          'mason',
        },
        -- markers rendered into the map
        diagnostic = { enabled = true, mode = 'line' },
        git = { enabled = true, mode = 'sign' },
        search = { enabled = true, mode = 'line' },
        treesitter = { enabled = true },
      }
    end,
  },
}
