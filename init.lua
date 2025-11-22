-- Neovim Configuration
-- Structure:
--   lua/core/       - Core settings (options, keymaps, autocmds)
--   lua/plugins/    - Plugin configurations (one file per plugin/group)

-- Load core configuration
require('core.options')      -- vim.o settings, leader keys
require('core.nixos')        -- NixOS detection
require('core.keymaps')      -- Key bindings
require('core.autocmds')     -- Autocommands
require('core.redact_pass')  -- Disable backups for pass(1) passwords

-- Bootstrap lazy.nvim (plugin manager)
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git', 'clone', '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Load plugins from lua/plugins/
require('lazy').setup({ import = 'plugins' }, {})
