return {
  "zk-org/zk-nvim",
  config = function()
    require("zk").setup({
      -- See Setup section below
       picker = "fzf_lua",
    })
  end
}
