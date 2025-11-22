-- Redact Pass: Disable leaky options when editing passwords in pass(1)
--
-- When editing a password file via `pass edit`, this disables:
-- - backup, writebackup, swapfile, undofile, shada (viminfo)
-- This prevents passwords from being cached on disk.
--
-- Original: Tom Ryder <tom@sanctum.geek.nz>

-- Don't load twice
if vim.g.loaded_redact_pass then
  return
end
vim.g.loaded_redact_pass = true

local function redact_pass()
  -- Only act if there's exactly one argument matching the file
  if vim.fn.argc() ~= 1 then
    return
  end

  local arg_path = vim.fn.fnamemodify(vim.fn.argv(0), ':p')
  local file_path = vim.fn.expand('<afile>:p')

  if arg_path ~= file_path then
    return
  end

  -- Disable all leaky options globally
  vim.opt.backup = false
  vim.opt.writebackup = false
  vim.opt.swapfile = false
  vim.opt.undofile = false
  vim.opt.shada = ''  -- 'viminfo' is called 'shada' in Neovim

  -- Notify user
  vim.notify('Editing password file -- disabled leaky options!', vim.log.levels.WARN)
  vim.g.redact_pass_redacted = true
end

-- Pattern matches pass(1) temp files:
-- /dev/shm/pass.XXX/file.txt, /tmp/pass.XXX/file.txt, $TMPDIR/pass.XXX/file.txt
local patterns = {
  '/dev/shm/pass.?*/?*.txt',
  '/tmp/pass.?*/?*.txt',
}

-- Add $TMPDIR pattern if set
if vim.env.TMPDIR then
  table.insert(patterns, vim.env.TMPDIR .. '/pass.?*/?*.txt')
end

vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('redact_pass', { clear = true }),
  pattern = patterns,
  callback = redact_pass,
  desc = 'Disable backups when editing pass(1) passwords',
})
