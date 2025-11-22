-- Editor: General editing utilities and UI plugins

return {
  -- Icons (dependency for many plugins)
  { 'nvim-tree/nvim-web-devicons' },
  { 'MunifTanjim/nui.nvim' },

  -- Git integration
  { 'tpope/vim-fugitive' },
  { 'tpope/vim-rhubarb' },

  -- Show pending keybinds
  { 'folke/which-key.nvim', opts = {} },

  -- "gc" to comment lines
  { 'numToStr/Comment.nvim', opts = {} },
}
