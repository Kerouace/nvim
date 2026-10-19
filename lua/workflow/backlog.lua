-- workflow.backlog: the Backlog (backlog.md at the notebook root) and moving
-- its items into Notes.

local M = {}

local function parts(dir)
  return vim.split(dir, '/', { trimempty = true })
end

-- `path` (relative to folder `from`) as seen from folder `to`
local function rebase(path, from, to)
  local target = parts(from)
  for _, part in ipairs(parts(path)) do
    if part == '..' then
      table.remove(target)
    elseif part ~= '.' then
      table.insert(target, part)
    end
  end
  local base = parts(to)
  local common = 0
  while common < #base and common < #target - 1 and base[common + 1] == target[common + 1] do
    common = common + 1
  end
  local out = {}
  for _ = common + 1, #base do
    table.insert(out, '..')
  end
  for i = common + 1, #target do
    table.insert(out, target[i])
  end
  return table.concat(out, '/')
end

--- `text` with its relative links and embeds rewritten so they resolve from
--- folder `to` instead of `from` (both relative to the notebook root).
function M.relink(text, from, to)
  return (text:gsub('(%]%()([^)%s]+)', function(open, path)
    -- a URL (scheme:), an anchor in the same Note, or an absolute path
    if path:match('^%a[%w+.-]*:') or path:match('^[#/~]') then
      return nil
    end
    return open .. rebase(path, from, to)
  end))
end

-- `lines` without blank lines at the end
local function trimmed(lines)
  local last = #lines
  while last > 0 and vim.trim(lines[last]) == '' do
    last = last - 1
  end
  return vim.list_slice(lines, 1, last)
end

local function is_item(line)
  return line:match('^%s*[-*+] ') ~= nil
end

-- `items` added after `lines`, set off by a blank line unless a list ends them
local function join(lines, items)
  local out = trimmed(lines)
  if #out > 0 and not is_item(out[#out]) then
    table.insert(out, '')
  end
  return vim.list_extend(out, items)
end

--- A Note's `lines` with `items` appended at the end.
function M.append_end(lines, items)
  return join(lines, items)
end

--- A Note's `lines` with `items` at the end of the section headed `heading`.
function M.append_under(lines, heading, items)
  for i, line in ipairs(lines) do
    local level = line:match('^(#+)%s+' .. vim.pesc(heading) .. '%s*$')
    if level then
      -- the section ends at the next heading of the same or a higher level
      local stop = #lines + 1
      for j = i + 1, #lines do
        local other = lines[j]:match('^(#+)%s')
        if other and #other <= #level then
          stop = j
          break
        end
      end
      local out = join(vim.list_slice(lines, 1, stop - 1), items)
      if stop <= #lines then
        table.insert(out, '')
      end
      return vim.list_extend(out, lines, stop)
    end
  end
  return join(join(lines, { '## ' .. heading }), items)
end

--- A Backlog item's text: its line without the bullet.
function M.item_text(line)
  return vim.trim((line:gsub('^%s*[-*+]%s+', '')))
end

-- Today's daily note gets done items under this heading (daily.md template)
M.done_heading = 'What have I done today?'

function M.notebook()
  return vim.fs.normalize(vim.env.ZK_NOTEBOOK_DIR or '~/sync/zk')
end

function M.path()
  return M.notebook() .. '/backlog.md'
end

-- The folder of `path` relative to the notebook root ('' for the root)
local function folder(path)
  local dir = vim.fs.dirname(vim.fs.relpath(M.notebook(), path) or '')
  return dir == '.' and '' or dir
end

local function zk(args, stdin)
  local command = vim.list_extend({ 'zk', '--notebook-dir', M.notebook() }, args)
  local result = vim.system(command, { text = true, stdin = stdin }):wait()
  if result.code ~= 0 then
    vim.notify(vim.trim(result.stderr), vim.log.levels.ERROR)
    return nil
  end
  return vim.trim(result.stdout)
end

-- Rewrite the Note at `path` with `change(lines)`: through its buffer when
-- it is loaded (saved, like any edit), else straight in the file, so Notes
-- that aren't open are left exactly as they were apart from the items.
local function save(buf)
  vim.api.nvim_buf_call(buf, function()
    vim.cmd('silent write')
  end)
end

local function edit_note(path, change)
  -- by exact name: bufnr() would take `path` as a pattern
  local buf
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) and vim.api.nvim_buf_get_name(b) == path then
      buf = b
    end
  end
  if buf then
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, change(vim.api.nvim_buf_get_lines(buf, 0, -1, true)))
    save(buf)
  else
    vim.fn.writefile(change(vim.fn.readfile(path)), path)
  end
end

-- The Backlog lines `first`..`last` of the current buffer as moved items
-- (blank lines skipped), a function that removes them from the Backlog, and
-- the Backlog's folder.
local function take(first, last)
  local buf = vim.api.nvim_get_current_buf()
  local taken = vim.api.nvim_buf_get_lines(buf, first - 1, last, true)
  local lines = vim.tbl_filter(function(line)
    return vim.trim(line) ~= ''
  end, taken)
  local function remove()
    -- the Backlog may have changed while a picker was open
    if not vim.deep_equal(vim.api.nvim_buf_get_lines(buf, first - 1, last, false), taken) then
      return vim.notify('The Backlog changed: remove the moved lines by hand', vim.log.levels.WARN)
    end
    vim.api.nvim_buf_set_lines(buf, first - 1, last, true, {})
    save(buf)
  end
  return lines, remove, folder(vim.api.nvim_buf_get_name(buf))
end

local function relinked(items, from, to)
  return vim.tbl_map(function(item)
    return M.relink(item, from, to)
  end, items)
end

--- Move Backlog lines `first`..`last` to the end of a Note picked with zk.
function M.to_note(first, last)
  local items, remove, from = take(first, last)
  if #items == 0 then
    return
  end
  require('zk').pick_notes(
    { notebook_path = M.notebook(), excludeHrefs = { M.path() } },
    { title = 'Move to Note', multi_select = false },
    function(note)
      local to = folder(note.absPath)
      edit_note(note.absPath, function(lines)
        return M.append_end(lines, relinked(items, from, to))
      end)
      remove()
      vim.notify(('Moved %d to %s'):format(#items, note.title or note.path))
    end
  )
end

--- Move Backlog lines `first`..`last` into a new Note titled with the first
--- item, opened in a split.
function M.to_new(first, last)
  local items, remove, from = take(first, last)
  if #items == 0 then
    return
  end
  -- --interactive reads the content ({{content}} in the template) from stdin
  local path = zk(
    { 'new', '--no-input', '--print-path', '--interactive', '--title', M.item_text(items[1]), M.notebook() },
    table.concat(relinked(items, from, ''), '\n') .. '\n'
  )
  if not path then
    return
  end
  remove()
  vim.cmd.split(vim.fn.fnameescape(path))
end

--- Move Backlog lines `first`..`last` to today's daily note, under "What
--- have I done today?"; the note is created from the daily template if
--- missing.
function M.to_daily(first, last)
  local items, remove, from = take(first, last)
  if #items == 0 then
    return
  end
  local path = ('%s/journal/daily/%s.md'):format(M.notebook(), os.date('%Y-%m-%d'))
  if vim.fn.filereadable(path) == 0 then
    path = zk({ 'new', '--no-input', '--print-path', M.notebook() .. '/journal/daily' })
    if not path then
      return
    end
  end
  edit_note(path, function(lines)
    return M.append_under(lines, M.done_heading, relinked(items, from, folder(path)))
  end)
  remove()
  vim.notify(('Moved %d to %s'):format(#items, vim.fs.basename(path)))
end

-- A keymap for normal mode (the cursor line) and visual mode (the range)
local function map_range(buf, lhs, move, desc)
  vim.keymap.set('n', lhs, function()
    local row = vim.fn.line('.')
    move(row, row)
  end, { buffer = buf, desc = desc })
  vim.keymap.set('x', lhs, function()
    local first, last = vim.fn.line('v'), vim.fn.line('.')
    vim.cmd('normal! \27')
    move(math.min(first, last), math.max(first, last))
  end, { buffer = buf, desc = desc })
end

function M.setup()
  vim.api.nvim_create_user_command('Backlog', function(opts)
    vim.cmd({ cmd = 'edit', args = { vim.fn.fnameescape(M.path()) }, mods = opts.smods })
  end, { desc = 'Open the Backlog' })
  vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
    pattern = M.path(),
    group = vim.api.nvim_create_augroup('workflow.backlog', {}),
    callback = function(args)
      map_range(args.buf, '<localleader>mm', M.to_note, '[M]ove item to a Note')
      map_range(args.buf, '<localleader>mn', M.to_new, '[M]ove item to a [N]ew Note')
      map_range(args.buf, '<localleader>md', M.to_daily, '[M]ove item to the [D]aily note (done)')
    end,
  })
end

return M
