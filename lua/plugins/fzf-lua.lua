-- fzf-lua: Fuzzy finder for files, grep, LSP, etc. (replaces telescope)

return {
  'ibhagwan/fzf-lua',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    local fzf = require('fzf-lua')
    fzf.setup({
      files = {
        follow = true, -- Follow symlinks
      },
    })
    -- vim.ui.select (code actions, ...) through fzf-lua; the papis link menu
    -- takes its action letters directly
    fzf.register_ui_select(function(ui_opts, items)
      if ui_opts.kind == 'papis_action' then
        return require('workflow.papis').select_opts(items)
      end
      return {}
    end)

    -- Keymaps (same keys as the former telescope setup)
    local map = vim.keymap.set

    map('n', '<leader>?', fzf.oldfiles, { desc = '[?] Find recently opened files' })
    map('n', '<leader><space>', fzf.buffers, { desc = '[ ] Find existing buffers' })
    map('n', '<leader>/', function()
      fzf.blines({ previewer = false, winopts = { height = 0.4, width = 0.6 } })
    end, { desc = '[/] Fuzzily search in current buffer' })

    map('n', '<leader>ff', fzf.files, { desc = '[F]ind [F]iles' })
    map('n', '<leader>fg', fzf.live_grep, { desc = '[F]ind by [G]rep' })
    map('n', '<leader>fh', fzf.helptags, { desc = '[F]ind [H]elp' })
    map('n', '<leader>fw', fzf.grep_cword, { desc = '[F]ind current [W]ord' })
    map('n', '<leader>fd', fzf.diagnostics_workspace, { desc = '[F]ind [D]iagnostics' })
    map('n', '<leader>fG', fzf.git_files, { desc = '[F]ind [G]it files' })
  end,
}
