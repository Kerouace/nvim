
return {
  {
    'lervag/vimtex',
    lazy = false,
    init = function()
      vim.g.vimtex_view_method = 'zathura';
      vim.g.vimtex_compiler_enable = 1;
      vim.g.vimtex_compiler_method = 'latexmk';
      --vim.g.vimtex_quickfix_ignore_filters = {""};
      --vim.g.vimtex_quickfix_method = 'pplatex';
      vim.g.vimtex_quickfix_mode = 2;
      vim.g.vimtex_quickfix_autoclose_after_keystrokes = 10;
      vim.g.vimtex_quickfix_open_on_warning = 0;
      vim.g.vimtex_quickfix_open_on_warning = 0;
    end
  }
}
