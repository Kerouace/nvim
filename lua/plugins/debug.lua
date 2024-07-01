-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

return {
  -- NOTE: Yes, you can install new plugins here!
  'mfussenegger/nvim-dap',
  -- NOTE: And you can specify dependencies as well
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    -- Installs the debug adapters for you
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Add your own debuggers here
    'leoluz/nvim-dap-go',

    -- Telescope [Custom]
    'nvim-telescope/telescope.nvim',
    'nvim-telescope/telescope-dap.nvim',
  },
  ft = { 'c', 'go', }, --'lua', 'python' },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        'delve',
      },
    }

    -- Taken from  https://git.cryptomilk.org/users/asn/dotfiles.git/tree/dot_config/nvim/lua/plugins/dap/init.lua
    -- idk if needed
    -- Store the config for 'dap.last_run()'
    dap.listeners.after.event_initialized['store_config'] = function(session)
      if session.config then
        last_run = {
          config = session.config,
        }
      end
    end

    -- Reimplement last_run to store the config
    -- https://github.com/mfussenegger/nvim-dap/issues/1025#issuecomment-1695852355
    local function dap_run_last()
      if last_run and last_run.config then
        dap.run(last_run.config)
      else
        dap.continue()
      end
    end

    -- Basic debugging keymaps, feel free to change to your liking!
    vim.keymap.set('n', '<F4>', dap.pause, { desc = 'Debug: Pause (thread)' })
    vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: Start/Continue' })
    vim.keymap.set('n', '<F6>', dap.step_into, { desc = 'Debug: Step Into' })
    vim.keymap.set('n', '<F7>', dap.step_over, { desc = 'Debug: Step Over' })
    vim.keymap.set('n', '<F8>', dap.step_out, { desc = 'Debug: Step Out' })
    vim.keymap.set('n', '<F9>', dap.step_back, { desc = 'Debug: Step Back' })
    vim.keymap.set('n', '<F10>', function() dap_run_last() end, { desc = 'Debug: run last' }) --idk
    vim.keymap.set('n', '<F11>', dap.terminate, { desc = 'Debug: Terminate' })

    vim.keymap.set('n', '<leader>dd', -- idk
      function() dap.disconnect({ terminateDebuggee = false }) end,
      { desc = 'Debug: disconnect' }
    )

    vim.keymap.set('n', '<leader>dt', -- idk
      function() dap.disconnect({ terminateDebuggee = true }) end,
      { desc = 'Debug: disconnect and terminate' }
    )
    vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
    vim.keymap.set('n', '<leader>dB',
      function()
        dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end,
      { desc = 'Debug: Set Breakpoint' }
    )
    vim.keymap.set('n', '<leader>dp', function() -- idk
      dap.set_breakpoint(nil, nil, vim.fn.input 'Log point message: ') -- no clue what this is used for
    end, { desc = 'Debug: Set Breakpoint' })

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    dapui.setup {
      -- Set icons to characters that are more likely to work in every terminal.
      --    Feel free to remove or use ones that you like more! :)
      --    Don't feel like these are good choices.
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    vim.keymap.set('n', '<F3>', dapui.toggle, { desc = 'Debug: toggle UI' })
    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    vim.keymap.set('n', '<F12>', dapui.toggle, { desc = 'Debug: See last session result.' })

    -- Is this smart? Or are there better options?
    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    -- idk
    --local telescope_dap = require('telescope').extensions.dap

    vim.keymap.set({ 'n' }, '<leader>d?', function()
        telescope_dap.commands({})
    end, { silent = true, desc = 'DAP builtin commands' })

    vim.keymap.set({ 'n' }, '<leader>dl', function()
        telescope_dap.list_breakpoints({})
    end, { silent = true, desc = 'DAP breakpoint list' })

    vim.keymap.set({ 'n' }, '<leader>df', function()
        telescope_dap.frames()
    end, { silent = true, desc = 'DAP frames' })

    vim.keymap.set({ 'n' }, '<leader>dv', function()
        telescope_dap.variables()
    end, { silent = true, desc = 'DAP variables' })

    vim.keymap.set({ 'n' }, '<leader>dc', function()
        telescope_dap.configurations()
    end, { silent = true, desc = 'DAP debugger configurations' })

    --require('telescope').load_extension('dap') -- I think this must be called after telescope
    --setup so it cannot be called here.
    -- But it does not work. I do not know why.


    --
    -- configure dap-ui and language adapaters
    --

    -- C
    if vim.fn.executable('gdb') == 1 then
      require('plugins.dap.c')
    end

    -- Install golang specific config
    require('dap-go').setup {
      delve = {
        -- On Windows delve must be run attached or it crashes.
        -- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
        detached = vim.fn.has 'win32' == 0,
      },
    }
  end,
}
