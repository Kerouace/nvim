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

local function save(buf)
  vim.api.nvim_buf_call(buf, function()
    vim.cmd('silent write')
  end)
end

-- The loaded buffer of the Note at `path`, by exact name (bufnr() would
-- take `path` as a pattern)
local function note_buf(path)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_name(buf) == path then
      return buf
    end
  end
end

local function read_note(path)
  local buf = note_buf(path)
  return buf and vim.api.nvim_buf_get_lines(buf, 0, -1, true) or vim.fn.readfile(path)
end

-- Through the Note's buffer when it is loaded (saved, like any edit), else
-- straight in the file, so Notes that aren't open are left exactly as they
-- were apart from the items.
local function write_note(path, lines)
  local buf = note_buf(path)
  if buf then
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
    save(buf)
  else
    vim.fn.writefile(lines, path)
  end
end

-- The last move, for undo(): the Backlog lines it took (`removed` once they
-- left the Backlog) and the target Note before and after.
local last_move

-- Rewrite the Note at `path` with `change(lines)` and remember the move.
local function edit_note(path, change, move)
  local before = read_note(path)
  local after = change(before)
  write_note(path, after)
  last_move = vim.tbl_extend('force', move, { path = path, before = before, after = after })
end

--- Remove `lines` from the Backlog buffer `buf`, where they were from line
--- `first` on, and save it; false (and a warning) when the Backlog changed
--- there meanwhile, e.g. while a picker was open.
function M.remove(buf, first, lines)
  local last = first + #lines - 1
  if not vim.deep_equal(vim.api.nvim_buf_get_lines(buf, first - 1, last, false), lines) then
    vim.notify('The Backlog changed: remove the moved lines by hand', vim.log.levels.WARN)
    return false
  end
  vim.api.nvim_buf_set_lines(buf, first - 1, last, true, {})
  save(buf)
  return true
end

-- The Backlog lines `first`..`last` of the current buffer as moved items
-- (blank lines skipped), a function that removes them from the Backlog, the
-- Backlog's folder, and the move so far (for undo).
local function take(first, last)
  local buf = vim.api.nvim_get_current_buf()
  local taken = vim.api.nvim_buf_get_lines(buf, first - 1, last, true)
  local lines = vim.tbl_filter(function(line)
    return vim.trim(line) ~= ''
  end, taken)
  local move = { backlog = buf, first = first, taken = taken }
  local function remove()
    if M.remove(buf, first, taken) and last_move then
      last_move.removed = true
    end
  end
  return lines, remove, folder(vim.api.nvim_buf_get_name(buf)), move
end

local function relinked(items, from, to)
  return vim.tbl_map(function(item)
    return M.relink(item, from, to)
  end, items)
end

--- Move Backlog lines `first`..`last` to the end of a Note picked with zk.
function M.to_note(first, last)
  local items, remove, from, move = take(first, last)
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
      end, move)
      remove()
      vim.notify(('Moved %d to %s'):format(#items, note.title or note.path))
    end
  )
end

--- Move Backlog lines `first`..`last` into a new Note titled with the first
--- item, opened in a split.
function M.to_new(first, last)
  local items, remove, from, move = take(first, last)
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
  last_move = vim.tbl_extend('force', move, { path = path, created = true, after = vim.fn.readfile(path) })
  remove()
  vim.cmd.split(vim.fn.fnameescape(path))
end

--- Move Backlog lines `first`..`last` to today's daily note, under "What
--- have I done today?"; the note is created from the daily template if
--- missing.
function M.to_daily(first, last)
  local items, remove, from, move = take(first, last)
  if #items == 0 then
    return
  end
  local path = ('%s/journal/daily/%s.md'):format(M.notebook(), os.date('%Y-%m-%d'))
  if vim.fn.filereadable(path) == 0 then
    path = zk({ 'new', '--no-input', '--print-path', M.notebook() .. '/journal/daily' })
    if not path then
      return
    end
    -- undo deletes a daily note this move created
    move.created = true
  end
  edit_note(path, function(lines)
    return M.append_under(lines, M.done_heading, relinked(items, from, folder(path)))
  end, move)
  remove()
  vim.notify(('Moved %d to %s'):format(#items, vim.fs.basename(path)))
end

--- Undo the last move of this session: the items go back into the Backlog
--- and leave the target Note (a Note the move created is deleted). Only
--- while the target is as the move left it, so no later edit is lost.
function M.undo()
  local move = last_move
  if not move then
    return vim.notify('No Backlog move to undo', vim.log.levels.WARN)
  end
  local name = vim.fs.basename(move.path)
  if vim.fn.filereadable(move.path) == 0 or not vim.deep_equal(read_note(move.path), move.after) then
    return vim.notify(name .. ' changed since the move: undo it there by hand', vim.log.levels.WARN)
  end
  if move.created then
    local buf = note_buf(move.path)
    if buf then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    vim.fn.delete(move.path)
  else
    write_note(move.path, move.before)
  end
  if move.removed and vim.api.nvim_buf_is_loaded(move.backlog) then
    local row = math.min(move.first - 1, vim.api.nvim_buf_line_count(move.backlog))
    vim.api.nvim_buf_set_lines(move.backlog, row, row, true, move.taken)
    save(move.backlog)
  end
  last_move = nil
  vim.notify(('Undid the move to %s%s'):format(name, move.created and ' (deleted)' or ''))
end

-- A keymap for normal mode (the cursor line) and visual mode (the range;
-- `move` gets true as a third argument)
local function map_range(buf, lhs, move, desc)
  vim.keymap.set('n', lhs, function()
    local row = vim.fn.line('.')
    move(row, row)
  end, { buffer = buf, desc = desc })
  vim.keymap.set('x', lhs, function()
    local first, last = vim.fn.line('v'), vim.fn.line('.')
    vim.cmd('normal! \27')
    move(math.min(first, last), math.max(first, last), true)
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
      map_range(args.buf, '<localleader>mt', require('workflow.todo').promote, '[M]ove item to a [T]odo (cfait)')
    end,
  })
  -- in any Note, since ,mn leaves the cursor in the new Note
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'markdown',
    group = vim.api.nvim_create_augroup('workflow.backlog.undo', {}),
    callback = function(args)
      vim.keymap.set('n', '<localleader>mu', M.undo, { buffer = args.buf, desc = '[M]ove: [U]ndo the last Backlog move' })
    end,
  })
end

return M
