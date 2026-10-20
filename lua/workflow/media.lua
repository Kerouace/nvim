-- workflow.media: Drawings in Notes, sketched in xournalpp or screenshots.
-- Each is a file `<slug>-<hash>` in the notebook's media folder
-- ($ZK_MEDIA), embedded as `![description](relative path)`.

local M = {}

-- lower() leaves non-ASCII letters alone
local spelled = { ['ä'] = 'ae', ['ö'] = 'oe', ['ü'] = 'ue', ['Ä'] = 'ae', ['Ö'] = 'oe', ['Ü'] = 'ue', ['ß'] = 'ss' }

--- The media file name (no extension) for `description`: its slug plus the
--- 8-hex `hash`.
function M.name(description, hash)
  local slug = description:gsub('[\195][\128-\191]', spelled):lower()
  slug = slug:gsub('[^%w]+', '-'):gsub('^-+', ''):gsub('-+$', '')
  return slug .. '-' .. hash
end

-- `path` relative to folder `dir` (both absolute), `./` in front when it
-- doesn't climb out, as the notebook's existing embeds have it
local function relative(dir, path)
  local from = vim.split(dir, '/', { trimempty = true })
  local to = vim.split(path, '/', { trimempty = true })
  local common = 0
  while common < #from and common < #to - 1 and from[common + 1] == to[common + 1] do
    common = common + 1
  end
  local out = {}
  for _ = common + 1, #from do
    table.insert(out, '..')
  end
  vim.list_extend(out, to, common + 1)
  local rel = table.concat(out, '/')
  return rel:match('^%.%./') and rel or './' .. rel
end

--- The embed line for media `file` in the Note at `note` (absolute paths).
function M.embed(description, note, file)
  local alt = description:gsub('[%[%]]', '\\%0')
  return ('![%s](%s)'):format(alt, relative(vim.fs.dirname(note), file))
end

-- The embeds on `line` as { start, end, target } (1-based, inclusive)
local function embeds(line)
  local found = {}
  for start, target, stop in line:gmatch('()!%[[^%]]*%]%(([^)%s]+)[^)]*%)()') do
    table.insert(found, { start, stop - 1, target })
  end
  return found
end

--- The absolute path of the embed under the cursor (0-based `col`) on
--- `line`, else of the only embed on the line, in the Note at `note`.
function M.embed_at(line, col, note)
  local found = embeds(line)
  local target
  for _, embed in ipairs(found) do
    if col + 1 >= embed[1] and col + 1 <= embed[2] then
      target = embed[3]
    end
  end
  target = target or (#found == 1 and found[1][3])
  return target and vim.fs.normalize(vim.fs.joinpath(vim.fs.dirname(note), target)) or nil
end

--- What opens the embedded `file`: a Drawing (a .xopp beside it) in
--- xournalpp, exported again on close; any other image in swayimg.
function M.open_command(file)
  local source = vim.fn.fnamemodify(file, ':r') .. '.xopp'
  if vim.fn.filereadable(source) == 1 then
    return { 'drawing-edit', source }
  end
  return { 'swayimg', file }
end

function M.dir()
  local dir = vim.env.ZK_MEDIA or (require('workflow.backlog').notebook() .. '/media')
  return vim.fs.normalize(dir)
end

-- A fresh 8-hex hash, as the existing media names have
local function hash(description)
  return vim.fn.sha256(description .. vim.uv.hrtime()):sub(1, 8)
end

-- `command` in the background, detached so a Drawing is still exported when
-- Neovim quits first; a failure is notified with the last line it printed
-- (xournalpp's window logs a lot)
local function run(command)
  local ok, err = pcall(vim.system, command, { text = true, detach = true }, function(result)
    if result.code ~= 0 then
      local lines = vim.split(vim.trim(result.stderr), '\n')
      vim.schedule(function()
        vim.notify(('%s failed: %s'):format(command[1], lines[#lines]), vim.log.levels.ERROR)
      end)
    end
  end)
  if not ok then
    vim.notify(err, vim.log.levels.ERROR)
  end
end

-- The current buffer's Note, or nil (and a warning) when it has no file
local function note()
  local path = vim.api.nvim_buf_get_name(0)
  if path == '' then
    vim.notify('Save the Note first: embeds are relative to its folder', vim.log.levels.WARN)
    return nil
  end
  return path
end

-- Ask for the description, then `make(name)` the media file (name: its
-- path without extension) and insert its embed below the cursor
-- line. `make` returns the file, or nil when it failed.
local function add(prompt, make)
  local path = note()
  if not path then
    return
  end
  local buf, row = vim.api.nvim_get_current_buf(), vim.fn.line('.')
  vim.ui.input({ prompt = prompt }, function(description)
    description = description and vim.trim(description)
    if not description or description == '' then
      return
    end
    local dir = M.dir()
    vim.fn.mkdir(dir, 'p')
    local file = make(dir .. '/' .. M.name(description, hash(description)))
    if not file then
      return
    end
    vim.api.nvim_buf_set_lines(buf, row, row, true, { M.embed(description, path, file) })
    if vim.api.nvim_get_current_buf() == buf then
      vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
    end
  end)
end

--- A new Drawing: embedded right away, opened in xournalpp, and exported
--- to the embedded PNG when its window closes.
function M.new_drawing()
  add('Drawing: ', function(name)
    run({ 'drawing-edit', name .. '.xopp' })
    return name .. '.png'
  end)
end

--- Embed the image on the clipboard (e.g. a flameshot or grimshot capture).
function M.paste()
  local result = vim.system({ 'wl-paste', '--no-newline', '--type', 'image/png' }):wait()
  if result.code ~= 0 then
    return vim.notify('No image on the clipboard', vim.log.levels.WARN)
  end
  add('Screenshot (clipboard): ', function(name)
    local file = io.open(name .. '.png', 'wb')
    if not file then
      vim.notify('Cannot write ' .. name .. '.png', vim.log.levels.ERROR)
      return nil
    end
    file:write(result.stdout)
    file:close()
    return name .. '.png'
  end)
end

--- Embed a copy of the newest screenshot in $SCREENSHOT_DIR.
function M.latest()
  local found = vim.system({ 'latest-screenshot' }, { text = true }):wait()
  if found.code ~= 0 then
    return vim.notify(vim.trim(found.stderr), vim.log.levels.WARN)
  end
  local shot = vim.trim(found.stdout)
  add(('Screenshot (%s): '):format(vim.fs.basename(shot)), function(name)
    local ext = shot:match('%.%w+$') or '.png'
    local copied = vim.system({ 'latest-screenshot', '--copy', name .. ext }, { text = true }):wait()
    if copied.code ~= 0 then
      vim.notify(vim.trim(copied.stderr), vim.log.levels.ERROR)
      return nil
    end
    return vim.trim(copied.stdout)
  end)
end

--- Open the embed under the cursor: a Drawing in xournalpp (exported again
--- on close), any other image in swayimg.
function M.open()
  local path = note()
  if not path then
    return
  end
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local file = M.embed_at(vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1], col, path)
  if not file then
    return vim.notify('No image embed under the cursor', vim.log.levels.WARN)
  end
  local command = M.open_command(file)
  if command[1] == 'swayimg' and vim.fn.filereadable(file) == 0 then
    return vim.notify('Missing: ' .. file, vim.log.levels.WARN)
  end
  run(command)
end

function M.setup()
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'markdown',
    group = vim.api.nvim_create_augroup('workflow.media', {}),
    callback = function(args)
      local map = function(lhs, rhs, desc)
        vim.keymap.set('n', lhs, rhs, { buffer = args.buf, desc = desc })
      end
      map('<localleader>dn', M.new_drawing, '[D]rawing: [N]ew, embedded below')
      map('<localleader>do', M.open, '[D]rawing: [O]pen the embed (xournalpp, else swayimg)')
      map('<localleader>dp', M.paste, '[D]rawing: [P]aste the clipboard image')
      map('<localleader>ds', M.latest, '[D]rawing: the latest [S]creenshot')
    end,
  })
end

return M
