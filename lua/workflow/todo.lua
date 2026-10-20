-- workflow.todo: Todos (cfait). Promoting Backlog items to Todos, and logging
-- done Todos to the daily note (todo-log-done, dotfiles-nixos todo/).

local M = {}

-- A link target as a URL cfait can open: a relative path is a Note, so a
-- file:// URL (zk may have dropped the .md)
local function link_url(target, dir)
  if target:match('^%a[%w+.-]*:') then
    return target
  end
  local path = vim.fs.normalize(vim.fs.joinpath(dir, target))
  if vim.fn.fnamemodify(path, ':e') == '' then
    path = path .. '.md'
  end
  return 'file://' .. path
end

--- A Backlog `line` as cfait input: `text` is the item with its markdown
--- links reduced to their labels, `url` the first link's target. `dir` is
--- the Backlog's folder.
function M.from_item(line, dir)
  local url
  local text = require('workflow.backlog').item_text(line):gsub('(!?)%[([^%]]*)%]%(([^)%s]+)%)', function(embed, label, target)
    if embed ~= '' then
      return nil
    end
    if not target:match('^#') then
      url = url or link_url(target, dir)
    end
    return label
  end)
  -- else a bare URL, without the punctuation ending a sentence
  url = url or (' ' .. text):match('%s(%a[%w+.-]*://%S+)')
  return { text = text, url = url and url:gsub('[.,;:!?]+$', '') }
end

--- The promote window's `text` without the snippet's tabstops left
--- `untouched` (its tokens as expanded, e.g. `@due`) or emptied (a bare `@`).
function M.clean(text, untouched)
  local words = vim.tbl_filter(function(word)
    return not vim.list_contains(untouched, word) and not word:match('^[!@^#~]+$')
  end, vim.split(text, '%s+', { trimempty = true }))
  return table.concat(words, ' ')
end

-- cfait's command line; tests point it at a scratch --root
M.cfait = { 'cfait' }

-- What a failed cfait run said, without its log lines and colours
local function said(result)
  local lines = vim.split(result.stdout .. '\n' .. result.stderr, '\n', { trimempty = true })
  lines = vim.tbl_filter(function(line)
    return not line:match('%[INFO%]')
  end, lines)
  return (table.concat(lines, ' '):gsub('\27%[[%d;]*m', ''))
end

-- `cfait add` each of `entries` ({ text, url }) in turn, then `done(added)`
-- with those that worked. The add may sync, so it runs in the background.
local function add_all(entries, done, added)
  added = added or {}
  local entry = table.remove(entries, 1)
  if not entry then
    return done(added)
  end
  local input = entry.text .. (entry.url and (' url:' .. entry.url) or '')
  vim.system(vim.list_extend(vim.deepcopy(M.cfait), { 'add', input }), { text = true }, function(result)
    vim.schedule(function()
      local uid = result.code == 0 and result.stdout:match('UID: (%x+)')
      if uid then
        -- the title: the input without smart-syntax tokens (!2, #tag, col:x)
        local title = vim.tbl_filter(function(word)
          return not word:match('^[!@^#~]') and (word:match('^%a[%w+.-]*://') or not word:match('^%l+:%S'))
        end, vim.split(entry.text, ' ', { trimempty = true }))
        vim.notify(('Todo: %s (%s)'):format(table.concat(title, ' '), uid))
        table.insert(added, entry)
      else
        vim.notify(('cfait add failed, the item stays: %s'):format(said(result)), vim.log.levels.ERROR)
      end
      add_all(entries, done, added)
    end)
  end)
end

-- The snippet `todo` for cfait input (luasnippets/cfait.lua), if LuaSnip has it
local function todo_snippet()
  local ok, luasnip = pcall(require, 'luasnip')
  if not ok then
    return nil
  end
  for _, snip in ipairs(luasnip.get_snippets('cfait') or {}) do
    if snip.trigger == 'todo' then
      return snip
    end
  end
end

-- A one-line window with `entry`'s text and the `todo` snippet expanded
-- after it; Enter calls `submit(text)` with the tabstops left untouched or
-- emptied dropped, q/Esc (normal mode) cancels.
local function edit_window(entry, submit)
  pcall(require, 'luasnip') -- so its lazy loader sees the filetype
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = 'cfait' -- also the tag completion (workflow.tags)
  local prefix = entry.text .. ' '
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, { prefix })
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'cursor',
    row = 1,
    col = 0,
    height = 1,
    width = math.max(40, math.min(100, vim.o.columns - 4)),
    style = 'minimal',
    border = 'rounded',
    title = ' Todo ',
    footer = entry.url and (' url: %s '):format(entry.url) or nil,
  })
  local untouched = {}
  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  local function send()
    -- only the fields after the item are cleaned (unless the item was edited)
    local line = vim.api.nvim_buf_get_lines(buf, 0, 1, true)[1]
    local item = line:sub(1, #prefix) == prefix and entry.text or ''
    local text = vim.trim(item .. ' ' .. M.clean(line:sub(#item + 1), untouched))
    vim.cmd.stopinsert()
    close()
    if text ~= '' then
      submit(text)
    end
  end
  vim.keymap.set({ 'n', 'i' }, '<CR>', send, { buffer = buf, desc = 'Add the Todo' })
  vim.keymap.set('n', 'q', close, { buffer = buf, desc = 'Cancel' })
  vim.keymap.set('n', '<Esc>', close, { buffer = buf, desc = 'Cancel' })
  vim.api.nvim_create_autocmd('WinLeave', { buffer = buf, once = true, callback = close })
  -- typing over a selected placeholder doesn't trigger nvim-cmp: ask it
  -- while a #tag is typed
  vim.api.nvim_create_autocmd('TextChangedI', {
    buffer = buf,
    callback = function()
      local ok, cmp = pcall(require, 'cmp')
      local col = vim.api.nvim_win_get_cursor(0)[2]
      if ok and not cmp.visible() and require('workflow.tags').hashtag_at(vim.api.nvim_get_current_line(), col) then
        cmp.complete()
      end
    end,
  })

  vim.api.nvim_win_set_cursor(win, { 1, #prefix })
  vim.cmd('startinsert!')
  local snip = todo_snippet()
  if snip then
    -- once in insert mode; what it expands to is what untouched looks like
    vim.schedule(function()
      require('luasnip').snip_expand(snip)
      local line = vim.api.nvim_buf_get_lines(buf, 0, 1, true)[1]
      untouched = vim.split(line:sub(#prefix + 1), '%s+', { trimempty = true })
    end)
  end
end

--- Promote Backlog lines `first`..`last` of the current buffer to Todos.
--- One item opens a window to add fields; a `visual` selection adds every
--- item as written. Each added item leaves the Backlog.
function M.promote(first, last, visual)
  local buf = vim.api.nvim_get_current_buf()
  local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(buf))
  local entries = {}
  for row = first, last do
    local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, true)[1]
    if vim.trim(line) ~= '' then
      table.insert(entries, vim.tbl_extend('force', M.from_item(line, dir), { row = row, line = line }))
    end
  end
  if #entries == 0 then
    return
  end
  local function remove(added)
    -- bottom up, so the rows above stay where they were
    table.sort(added, function(a, b)
      return a.row > b.row
    end)
    for _, entry in ipairs(added) do
      require('workflow.backlog').remove(buf, entry.row, { entry.line })
    end
  end
  if visual then
    return add_all(entries, remove)
  end
  edit_window(entries[1], function(text)
    entries[1].text = text
    add_all(entries, remove)
  end)
end

--- The date of the daily note at `path` (YYYY-MM-DD), or nil.
function M.daily_date(path)
  return path:match('journal/daily/(%d%d%d%d%-%d%d%-%d%d)%.md$')
end

local function loaded_buf(path)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_name(buf) == path then
      return buf
    end
  end
end

--- Log the Todos completed on `day` (default today) to its daily note
--- with todo-log-done. The note is saved first and reloaded after.
function M.log_done(day)
  day = day or os.date('%Y-%m-%d')
  local path = ('%s/journal/daily/%s.md'):format(require('workflow.backlog').notebook(), day)
  local buf = loaded_buf(path)
  if buf and vim.bo[buf].modified then
    vim.api.nvim_buf_call(buf, function()
      vim.cmd('silent write')
    end)
  end
  vim.notify(('Logging the Todos done on %s (cfait sync)…'):format(day))
  local ok, err = pcall(vim.system, { 'todo-log-done', day }, { text = true }, function(result)
    vim.schedule(function()
      if buf and vim.api.nvim_buf_is_loaded(buf) then
        vim.cmd.checktime(buf)
      end
      local failed = result.code ~= 0
      -- one line (offline adds one), so no hit-enter prompt
      local message = vim.trim(failed and result.stderr or result.stdout):gsub('\n', ' ')
      vim.notify(message, failed and vim.log.levels.ERROR or nil)
    end)
  end)
  if not ok then
    vim.notify(err, vim.log.levels.ERROR)
  end
end

function M.setup()
  -- the current daily note's day, else today, unless a date is given
  vim.api.nvim_create_user_command('LogDone', function(opts)
    M.log_done(opts.args ~= '' and opts.args or M.daily_date(vim.api.nvim_buf_get_name(0)))
  end, { nargs = '?', desc = 'Log the Todos done on this daily note’s day' })
  vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
    pattern = require('workflow.backlog').notebook() .. '/journal/daily/*.md',
    group = vim.api.nvim_create_augroup('workflow.todo', {}),
    callback = function(args)
      vim.keymap.set('n', '<localleader>ld', function()
        M.log_done(M.daily_date(vim.api.nvim_buf_get_name(args.buf)))
      end, { buffer = args.buf, desc = '[L]og [D]one Todos (cfait)' })
    end,
  })
end

return M
