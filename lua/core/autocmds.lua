-- Autocommands: Automatic actions on events

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- Delete trailing whitespace on save
autocmd('BufWritePre', {
  pattern = '*',
  command = [[%s/\s\+$//e]],
})

-- Highlight text briefly after yanking
local highlight_group = augroup('YankHighlight', { clear = true })
autocmd('TextYankPost', {
  group = highlight_group,
  pattern = '*',
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Show diagnostics in floating window on hover
autocmd('CursorHold', {
  callback = function()
    vim.diagnostic.open_float(nil, {
      focusable = false,
      close_events = { 'BufLeave', 'CursorMoved', 'InsertEnter', 'FocusLost' },
      border = 'rounded',
      source = 'always',
      prefix = ' ',
      scope = 'cursor',
    })
  end,
})
