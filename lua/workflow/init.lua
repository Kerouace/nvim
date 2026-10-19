-- workflow: glue between Notes (zk), References (papis), Todos (cfait),
-- Bookmarks and Drawings. Each area gets its own submodule here
-- (workflow.papis, workflow.backlog, workflow.media, ...); keymaps are
-- scoped by filetype or path and registered from setup().
--
-- The heavy lifting lives in Nix-built executables (dotfiles-nixos); these
-- modules only call them and edit buffers.

local M = {}

function M.setup()
  require('workflow.papis').setup()
  require('workflow.tags').setup()
end

return M
