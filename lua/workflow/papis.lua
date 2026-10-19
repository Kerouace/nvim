-- workflow.papis: References (papis) in Notes.
--
-- A Note links a Reference as [<Citation key>](papis://<Reference ID>).
-- The Reference actions themselves live in papis-action (dotfiles-nixos
-- papis/); this module only picks, parses links and calls it.

local M = {}

-- Spans {first, last, id} (1-based, inclusive) of the papis:// links on a
-- line: a markdown link as a whole, or a bare URL.
local function links(line)
  local found = {}
  for first, id, last in line:gmatch('()%[[^%]]*%]%(papis://(%w+)[^)]*%)()') do
    table.insert(found, { first, last - 1, id })
  end
  for first, id, last in line:gmatch('()papis://(%w+)[^%s)]*()') do
    local inside = false
    for _, link in ipairs(found) do
      inside = inside or (first >= link[1] and first <= link[2])
    end
    if not inside then
      table.insert(found, { first, last - 1, id })
    end
  end
  return found
end

--- The Reference ID of the link at byte column `col` (0-based) of `line`,
--- or of the only link on the line when the cursor is on none.
function M.link_at(line, col)
  local found = links(line)
  for _, link in ipairs(found) do
    if col + 1 >= link[1] and col + 1 <= link[2] then
      return link[3]
    end
  end
  return #found == 1 and found[1][3] or nil
end

local function system(command)
  local result = vim.system(command, { text = true }):wait()
  if result.code ~= 0 then
    vim.notify(vim.trim(result.stderr), vim.log.levels.ERROR)
    return nil
  end
  return result.stdout
end

-- The papis picker's own fzf bindings (normal mode, action letters) and
-- flags (fields, preview), read once per session.
local fzf_args

--- Pick References as the papis picker does; Enter inserts their links at
--- the cursor. The picker's action letters work as in the shell.
function M.insert_link()
  if not fzf_args then
    local json = system({ 'papis-action', '--fzf-args' })
    if not json then
      return
    end
    fzf_args = vim.tbl_map(vim.fn.shellescape, vim.json.decode(json))
  end
  local buf, win = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
  require('fzf-lua').fzf_exec('papis-action --fzf-rows', {
    fzf_args = fzf_args,
    -- esc is papis' normal mode (bound in fzf_args), so fzf-lua's hide
    -- profile and its esc action stay off; q or ctrl-c abort
    no_hide = true,
    actions = {
      esc = false,
      default = function(selected)
        local inserted = {}
        for _, line in ipairs(selected) do
          local id = vim.split(line, '@@', { plain = true })[2]
          local key = system({ 'papis', 'list', '--all', '--format', '{doc[ref]}', 'papis_id:' .. id })
          table.insert(inserted, ('[%s](papis://%s)'):format(vim.trim(key or id), id))
        end
        if #inserted > 0 and vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_set_current_win(win)
          vim.api.nvim_win_set_buf(win, buf)
          vim.api.nvim_put({ table.concat(inserted, ', ') }, 'c', true, true)
        end
      end,
    },
  })
end

-- letter, name, key, mode, description; from papis-action's action table
local actions

local function list_actions()
  if not actions then
    local out = system({ 'papis-action', '--list' })
    if not out then
      return nil
    end
    actions = {}
    for _, row in ipairs(vim.split(out, '\n', { trimempty = true })) do
      local letter, name, _, mode, description = unpack(vim.split(row, '\t'))
      table.insert(actions, { letter = letter, name = name, mode = mode, description = description })
    end
  end
  return actions
end

-- A papis-action that needs a terminal (papis edit, papis-explore), in a float.
local function in_terminal(command)
  local buf = vim.api.nvim_create_buf(false, true)
  local width, height = math.floor(vim.o.columns * 0.9), math.floor(vim.o.lines * 0.85)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    border = 'rounded',
  })
  vim.fn.jobstart(command, {
    term = true,
    on_exit = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end,
  })
  vim.cmd.startinsert()
end

--- Run one Reference action on a Reference ID.
function M.run(action, id)
  if action.name == 'literature' then
    local path = system({ 'papis-action', 'literature', '--print', id })
    if path then
      vim.cmd.edit(vim.fn.fnameescape(vim.trim(path)))
    end
  elseif action.name == 'backlinks' then
    require('zk').edit({ match = { 'papis://' .. id }, matchStrategy = 'exact' }, { title = 'Notes linking here' })
  elseif action.mode == 'return' then
    in_terminal({ 'papis-action', action.name, id })
  else
    -- papis-action reports by notification itself
    vim.system({ 'papis-action', action.name, id }, { detach = true })
  end
end

--- fzf-lua options for the menu (vim.ui.select kind 'papis_action'): each
--- action letter runs its action right away.
function M.select_opts(items)
  local keys = {}
  for i, action in ipairs(items) do
    keys[action.letter] = ('pos(%d)+accept'):format(i)
  end
  return { prompt = 'Reference (letter)> ', keymap = { fzf = keys } }
end

--- The action menu for the papis:// link under the cursor.
function M.menu()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local id = M.link_at(vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1], col)
  if not id then
    return vim.notify('no papis:// link under the cursor', vim.log.levels.WARN)
  end
  local items = list_actions()
  if not items then
    return
  end
  vim.ui.select(items, {
    prompt = 'Reference',
    kind = 'papis_action',
    format_item = function(action)
      return action.letter .. '  ' .. action.description
    end,
  }, function(action)
    if action then
      M.run(action, id)
    end
  end)
end

-- Neovim's gx, opening each URL once: on a markdown link its URL list holds
-- the link and the bare URL in it, so the PDF would open twice. papis://
-- goes through the xdg handler (papis-open-uri).
local function open_urls()
  local seen = {}
  for _, url in ipairs(require('vim.ui')._get_urls()) do
    if not seen[url] then
      seen[url] = true
      local _, err = vim.ui.open(url)
      if err then
        vim.notify(err, vim.log.levels.ERROR)
      end
    end
  end
end

function M.setup()
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'markdown',
    group = vim.api.nvim_create_augroup('workflow.papis', {}),
    callback = function(args)
      local map = function(lhs, rhs, desc)
        vim.keymap.set('n', lhs, rhs, { buffer = args.buf, desc = desc })
      end
      map('gx', open_urls, 'Open the link under the cursor')
      map('<localleader>r', M.insert_link, 'Insert [R]eference link')
      map('<localleader>p', M.menu, '[P]apis actions on the link')
    end,
  })
end

return M
