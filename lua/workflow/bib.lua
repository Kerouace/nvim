-- workflow.bib: cite References in LaTeX and keep the project's
-- bib/bibliography.bib in sync.
--
-- A project is the folder with project.yaml (`name: X`). The .bib work lives
-- in papis-bib (dotfiles-nixos papis/); this module only picks, inserts and
-- asks. latexmk appends the project's missing entries on each run (the hook
-- in latexmkrc), so citing only has to add the project to the Reference.

local M = {}

M.bib_file = 'bib/bibliography.bib'

--- The \cite for these keys.
function M.cite_text(keys)
  return ('\\cite{%s}'):format(table.concat(keys, ','))
end

--- A sync plan item ({papis_id, key, papis, bib}) as diff lines, from papis'
--- export to the entry in the .bib.
function M.diff_lines(item)
  local hunks = vim.diff(item.papis .. '\n', item.bib .. '\n', { ctxlen = 0 })
  local lines = { '--- papis', '+++ ' .. M.bib_file }
  vim.list_extend(lines, vim.split(hunks, '\n', { trimempty = true }))
  return lines
end

local function root()
  local dir = vim.fs.root(0, 'project.yaml')
  if not dir then
    vim.notify('no project.yaml above this file', vim.log.levels.WARN)
  end
  return dir
end

-- papis-bib in the project root; its stderr (warnings) is reported
local function papis_bib(dir, args)
  local result = vim.system(vim.list_extend({ 'papis-bib' }, args), { cwd = dir, text = true }):wait()
  local messages = vim.trim(result.stderr or '')
  if messages ~= '' then
    vim.notify(messages, result.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
  end
  return result.code == 0 and result.stdout or nil
end

--- Pick References; Enter inserts \cite{key,...} at the cursor and adds
--- the project to each Reference. A Reference the .bib already has under a
--- coauthor's key (same DOI) is cited by that key instead.
function M.cite()
  local dir = root()
  if not dir then
    return
  end
  require('workflow.papis').pick(function(ids)
    local out = papis_bib(dir, vim.list_extend({ 'cite' }, ids))
    if out then
      vim.api.nvim_put({ M.cite_text(vim.split(out, '\n', { trimempty = true })) }, 'c', true, true)
    end
  end)
end

-- The .bib's buffer, if loaded, so edits there are saved first and reloaded
-- after
local function bib_buffer(dir)
  local buf = vim.fn.bufnr(vim.fs.joinpath(dir, M.bib_file))
  return buf ~= -1 and vim.api.nvim_buf_is_loaded(buf) and buf or nil
end

-- Show one entry's diff and ask what to do: 'refresh', 'push' or nil (skip)
local function ask(item)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, M.diff_lines(item))
  vim.bo[buf].filetype = 'diff'
  vim.cmd('botright split')
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.cmd.redraw()
  local choice = vim.fn.confirm(
    ('%s differs from papis (- papis, + .bib)'):format(item.key),
    '&refresh .bib from papis\n&push .bib to papis\n&skip',
    3
  )
  vim.api.nvim_win_close(win, true)
  vim.api.nvim_buf_delete(buf, { force = true })
  return ({ 'refresh', 'push' })[choice]
end

--- :PapisBibSync. For each papis-owned entry that differs from papis, show
--- the diff and refresh it from papis, push its edits back, or skip; then
--- append the missing entries and check for duplicates. Foreign entries are
--- never touched.
function M.sync()
  local dir = root()
  if not dir then
    return
  end
  local buf = bib_buffer(dir)
  if buf then
    vim.api.nvim_buf_call(buf, function()
      vim.cmd('silent update')
    end)
  end
  local plan = papis_bib(dir, { 'sync', '--plan' })
  if not plan then
    return
  end
  local chosen = { refresh = {}, push = {} }
  for _, item in ipairs(vim.json.decode(plan)) do
    local action = ask(item)
    if action then
      table.insert(chosen[action], item.papis_id)
    end
  end
  if #chosen.push > 0 then
    papis_bib(dir, vim.list_extend({ 'push' }, chosen.push))
  end
  -- pushed entries too, so they take papis' form and don't show up again
  local refreshed = vim.list_extend(vim.list_extend({}, chosen.refresh), chosen.push)
  if #refreshed > 0 then
    papis_bib(dir, vim.list_extend({ 'refresh' }, refreshed))
  end
  papis_bib(dir, { 'append' })
  if buf then
    vim.cmd.checktime(buf)
  end
  vim.notify(('PapisBibSync: %d refreshed, %d pushed'):format(#chosen.refresh, #chosen.push))
end

function M.setup()
  vim.api.nvim_create_user_command('PapisBibSync', M.sync, { desc = "Sync the project's .bib with papis" })
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'tex',
    group = vim.api.nvim_create_augroup('workflow.bib', {}),
    callback = function(args)
      vim.keymap.set('n', '<localleader>r', M.cite, { buffer = args.buf, desc = 'Cite a [R]eference' })
    end,
  })
end

return M
