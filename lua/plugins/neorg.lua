return {
  "nvim-neorg/neorg",
  build = ":Neorg sync-parsers",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("neorg").setup {
      load = {
        ["core.defaults"] = {},   -- Loads default behaviour
        ["core.concealer"] = {    -- Adds pretty icons to your documents
        },
        ["core.dirman"] = {   -- Manages Neorg workspaces
          config = {
            workspaces = {
              work = "~/sync/work/notes",
              priv = "~/sync/priv/notes",
            },
            default_workspace = "work",
            index = "index.norg",
          },
        },
        ["core.journal"] = {
          config = {
            journal_folder = "journal",
            workspace = "work",
          },
        },
      },
    }
  end,
}
