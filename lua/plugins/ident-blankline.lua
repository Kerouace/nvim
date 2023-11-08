return{
  { -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim', -- [Okay?] replace by mini alternative? perhaps add show_current_context{_start}?
    -- Enable `lukas-reineke/indent-blankline.nvim`
    -- See `:help indent_blankline.txt`
    main = "ibl",
    opts = {
      -- char = '┊',
      -- show_trailing_blankline_indent = false,
      -- show_current_context = true,
      -- TODO: add rainbow brackets
    },
  }
}

