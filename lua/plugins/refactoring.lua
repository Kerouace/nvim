return {
  "ThePrimeagen/refactoring.nvim",
  -- Disabled: current version does `require "async"` (an external luarocks
  -- module) that isn't installed, so its config crashes on startup. Re-enable
  -- once the async dependency is sorted (or pin to a pre-async commit).
  enabled = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("refactoring").setup()
  end,
}
