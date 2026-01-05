-- persistence.lua
--
-- Simple session management for Neovim
-- Auto-saves and restores your editor state per directory
-- NOTE: If the auto-saveing is anoing I will probably switch to https://github.com/natecraddock/sessions.nvim
-- If I want to inegrate workspace functionality I will probably go with https://github.com/natecraddock/workspaces.nvim
-- However, currently I think I will not use vim for managing workspaces/projects but a dedicated
-- tool in combination with tmux.

return {
  "folke/persistence.nvim",
  event = "BufReadPre", -- Load before reading files
  opts = {
    -- Directory where session files are saved
    dir = vim.fn.expand(vim.fn.stdpath("state") .. "/sessions/"),
    -- Options to save in the session
    options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp" },
    -- Pre-save hook to clean up before saving
    pre_save = nil,
  },
  keys = {
    {
      "<leader>qs",
      function() require("persistence").load() end,
      desc = "Restore Session"
    },
    {
      "<leader>ql",
      function() require("persistence").load({ last = true }) end,
      desc = "Restore Last Session"
    },
    {
      "<leader>qd",
      function() require("persistence").stop() end,
      desc = "Don't Save Current Session"
    },
  },
}
