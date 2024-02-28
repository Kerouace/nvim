
return {
  {
    'lervag/vimtex',
    lazy = false,
    init = function()
      vim.g.vimtex_view_method = 'zathura';
      --vim.g.vimtex_quickfix_ignore_filters = {""};
      --vim.g.vimtex_quickfix_method = 'pplatex';
      vim.g.vimtex_quickfix_mode = 2;
      vim.g.vimtex_quickfix_autoclose_after_keystrokes = 20;
      vim.g.vimtex_quickfix_open_on_warning = 1;
    end
  }
}
