return {
  {
    'goolord/alpha-nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      local alpha = require('alpha')
      local dashboard = require('alpha.themes.dashboard')

      -- Set header
      dashboard.section.header.val = {
        [[                                      ]],
        [[                                      ]],
        [[  ███    ██ ███████  ██████  ██    ██ ██ ███    ███  ]],
        [[  ████   ██ ██      ██    ██ ██    ██ ██ ████  ████  ]],
        [[  ██ ██  ██ █████   ██    ██ ██    ██ ██ ██ ████ ██  ]],
        [[  ██  ██ ██ ██      ██    ██  ██  ██  ██ ██  ██  ██  ]],
        [[  ██   ████ ███████  ██████    ████   ██ ██      ██  ]],
        [[                                      ]],
        [[                                      ]],
      }

      -- Set menu
      dashboard.section.buttons.val = {
        dashboard.button('n', '  New file', ':lua vim.ui.input({prompt="New file: "}, function(name) if name then vim.cmd("e " .. name) else vim.cmd("enew") end end)<CR>'),
        dashboard.button('f', '  Find file', ':Telescope find_files <CR>'),
        dashboard.button('r', '  Recent files', ':Telescope oldfiles <CR>'),
        dashboard.button('g', '  Find text', ':Telescope live_grep <CR>'),
        dashboard.button('s', '  Restore Session', [[<cmd>lua require("persistence").load()<cr>]]),
        dashboard.button('c', '  Configuration', ':e $MYVIMRC<CR>'),
        dashboard.button('q', '  Quit', ':qa<CR>'),
      }

      -- Set footer
      local function footer()
        local total_plugins = require('lazy').stats().count
        local datetime = os.date(' %Y-%m-%d   %H:%M:%S')
        local version = vim.version()
        local nvim_version_info = '  v' .. version.major .. '.' .. version.minor .. '.' .. version.patch
        local cwd = vim.fn.getcwd()

        return datetime .. '   ' .. total_plugins .. ' plugins' .. nvim_version_info .. '\n' .. '  ' .. cwd
      end

      dashboard.section.footer.val = footer()

      -- Send config to alpha
      alpha.setup(dashboard.opts)

      -- Disable folding on alpha buffer
      vim.cmd([[
        autocmd FileType alpha setlocal nofoldenable
      ]])
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
