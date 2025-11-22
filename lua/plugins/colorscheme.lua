-- Colorscheme: Gruvbox theme and color utilities

return {
  -- Gruvbox colorscheme
  {
    'gruvbox-community/gruvbox',
    lazy = false,     -- Load immediately (not lazy)
    priority = 1000,  -- Load before other plugins
    config = function()
      vim.cmd.colorscheme('gruvbox')
    end,
  },

  -- Show colors for hex values, rgb(), etc.
  {
    'norcalli/nvim-colorizer.lua',
    config = function()
      require('colorizer').setup()
    end,
  },
}
