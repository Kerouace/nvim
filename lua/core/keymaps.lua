-- Keymaps: General key bindings (non-plugin-specific)
-- Plugin-specific keymaps live in their respective plugin files

local map = vim.keymap.set

-- Disable space in normal/visual (since it's leader)
map({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Better movement with word wrap
map('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
map('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Substitute commands
map('n', '<leader>ss', ':%s//g<Left><Left>', { noremap = true, desc = '[S]ub[s]titute all' })
map('n', '<leader>sl', ':s//g<Left><Left>', { noremap = true, desc = '[S]ubstitute in [l]ine' })
map('v', '<leader>sl', ':s//g<Left><Left>', { noremap = true, desc = '[S]ubstitute in visual [l]ine' })
map('n', '<leader>sa', ':%s/\\<<C-r><C-w>\\>//g<Left><Left>', { noremap = true, desc = '[S]ubstitute [a]ll under cursor' })

-- Spell check toggles
map('n', '<F6>', ':setlocal spell! spelllang=de_de<CR>', { noremap = true, desc = 'Toggle German spell check' })
map('n', '<F7>', ':setlocal spell! spelllang=en_us<CR>', { noremap = true, desc = 'Toggle English spell check' })

-- Keep selection when indenting
map('v', '<', '<gv', { noremap = true })
map('v', '>', '>gv', { noremap = true })

-- Diagnostics
map('n', '[d', vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
map('n', ']d', vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
map('n', '<leader>e', vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
map('n', '<leader>q', vim.diagnostic.setloclist, { desc = "Open diagnostics list" })
