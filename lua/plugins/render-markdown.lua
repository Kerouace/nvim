-- [render-markdown]
-- https://github.com/MeanderingProgrammer/render-markdown.nvim
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    cmd = { "RenderMarkdown" },
    keys = {
      { "<leader>mp", "<cmd>RenderMarkdown preview<cr>", desc = "[M]arkdown [P]review" },
    },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = {
      -- Don't render in any mode for main buffer (prevents jumping)
      render_modes = {},
      -- Enable in-process LSP for completions (checkboxes, callouts)
      completions = {
        lsp = { enabled = true },
      },
      -- Preview buffer will render in normal, command, and terminal modes
      overrides = {
        preview = {
          render_modes = { 'n', 'c', 't' },
        },
      },
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)
    end,
  },
}
