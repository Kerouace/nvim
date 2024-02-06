return{
  "danymat/neogen",
  dependencies = "nvim-treesitter/nvim-treesitter",
  keys = {{"<Leader>nc", ":lua require('neogen').generate()<CR>", desc = "Generate a docstring"}},
  config = function ()
    require('neogen').setup({snippet_engine = "luasnip"})
  end,
  version = "*"
}

-- vim: ts=2 sts=2 sw=2 et
