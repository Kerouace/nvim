return {
  { -- Set lualine as statusline
    'nvim-lualine/lualine.nvim', --[Okay?]
    -- See `:help lualine.txt`
    opts = {
      options = {
        icons_enabled = true,
        theme = 'gruvbox',
        component_separators = '|',
        section_separators = '',
      },
    },
  }
}
