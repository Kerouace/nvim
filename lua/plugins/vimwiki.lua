
return {
  {
    'vimwiki/vimwiki',
    lazy = false,
    init = function()
      vim.g.vimwiki_list = {
        {
          path = '~/git/own/personal-wiki',
          syntax = 'markdown',
          ext = '.md',
        }
      }
      vim.g.vimwiki_global_ext = 1
    end
  }
}
