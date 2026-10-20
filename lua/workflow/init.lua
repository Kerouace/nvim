-- workflow: glue between Notes (zk), References (papis), Todos (cfait),
-- Bookmarks and Drawings. Each area gets its own submodule here
-- (workflow.papis, workflow.backlog, workflow.todo, ...); keymaps are
-- scoped by filetype or path and registered from setup().
--
-- The heavy lifting lives in Nix-built executables (dotfiles-nixos); these
-- modules only call them and edit buffers.

local M = {}

-- The workflow cheat sheet, kept with the glue it describes
M.help_file = vim.fn.expand('~/git/dotfiles-nixos/docs/workflow.md')

function M.setup()
  -- opens in a split like :help; :vert WorkflowHelp, :tab WorkflowHelp work
  vim.api.nvim_create_user_command('WorkflowHelp', function(opts)
    vim.cmd({ cmd = 'split', args = { vim.fn.fnameescape(M.help_file) }, mods = opts.smods })
  end, { desc = 'Open the workflow cheat sheet' })
  require('workflow.papis').setup()
  require('workflow.tags').setup()
  require('workflow.bib').setup()
  require('workflow.backlog').setup()
  require('workflow.todo').setup()
end

return M
