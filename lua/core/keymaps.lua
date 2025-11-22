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
map('n', '<leader>zg', ':setlocal spell! spelllang=de_de<CR>', { noremap = true, desc = 'Spell check [G]erman' })
map('n', '<leader>ze', ':setlocal spell! spelllang=en_us<CR>', { noremap = true, desc = 'Spell check [E]nglish' })

-- Keep selection when indenting
map('v', '<', '<gv', { noremap = true })
map('v', '>', '>gv', { noremap = true })

-- Diagnostics
map('n', '[d', vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
map('n', ']d', vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
map('n', '<leader>le', vim.diagnostic.open_float, { desc = "[L]SP Diagnostic float" })
map('n', '<leader>lq', vim.diagnostic.setloclist, { desc = "[L]SP Diagnostics list" })
