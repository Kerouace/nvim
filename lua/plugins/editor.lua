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

  -- "gc"/"gcc" commenting is built into Neovim >= 0.10, so no plugin is needed.
  -- Comment.nvim was removed: on Neovim 0.12 vim.treesitter.get_parser() returns
  -- nil instead of erroring for buffers without a parser, which its pcall guard
  -- does not catch (Comment/ft.lua:280), so gcc silently failed in e.g. tex,
  -- systemverilog, json and org buffers.
}
