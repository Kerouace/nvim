return {
  {
    "stevearc/oil.nvim",
    config = function()
      require('oil').setup({
        win_options = {
          signcolumn = "yes:2",
        },
        columns = {
          "icon",
          -- "permissions",
          -- "size",
          -- "mtime",
        },
        view_options = {
          show_hidden = true,
        },
        keymaps = {
          ["~"] = false,
          ["gd"] = {
                desc = "Toggle file detail view",
                callback = function()
                  detail = not detail
                  if detail then
                    require("oil").set_columns({ "icon", "permissions", "size", "mtime" })
                  else
                    require("oil").set_columns({ "icon" })
                  end
                end,
              },
        },
      })
      local map = vim.keymap.set
      map('n', '<leader>ef', require("oil").open_float, { desc = "Open [E]xplorer [F]loating" })
    end
  },

  {
  "refractalize/oil-git-status.nvim",

  dependencies = {
    "stevearc/oil.nvim",
  },
  config = true,
},
}
