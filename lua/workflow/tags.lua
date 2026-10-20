-- workflow.tags: one nvim-cmp source completing existing tags, so a tag is
-- never typed blind. Each provider names the files it serves and the command
-- printing the existing values one per line: per YAML key, or per sigil of
-- the cfait smart-input word being typed (`#tag`; `!prio`, `@due` and
-- `^start` get fixed lists). New values can still be typed; the list only
-- offers what exists.

local M = {}

-- Dates cfait understands (checked against cfait 1.2), soonest first
local dates = {
  'today', 'tomorrow', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
  '2d', '1w', '2w', '1mo', '3mo', '1y',
}

M.providers = {
  {
    file = 'info.yaml', -- a papis Reference, e.g. from `papis edit`
    keys = {
      tags = { 'papis-tags' },
      project = { 'papis-tags', '--projects' },
    },
  },
  {
    filetype = 'cfait', -- the window promoting a Backlog item (workflow.todo)
    sigils = {
      ['#'] = { 'sh', '-c', "cfait list --all --fields categories 2>/dev/null | tr ',' '\\n' | sort -u" },
      ['!'] = { list = { '1', '2', '3', '4', '5', '6', '7', '8', '9' } }, -- 1 is the highest
      ['@'] = { list = dates },
      ['^'] = { list = dates },
    },
  },
}

--- The top-level YAML key whose value the cursor is in (`row` 1-based,
--- `col` 0-based), or nil while the key itself is being typed.
function M.key_at(lines, row, col)
  local key, colon = lines[row]:match('^([%w_-]+)():')
  if key then
    return col >= colon and key or nil
  end
  if not lines[row]:match('^[%s-]') then
    return nil
  end
  for r = row - 1, 1, -1 do
    key = lines[r]:match('^([%w_-]+):')
    if key then
      return key
    end
    if not lines[r]:match('^[%s-]') and lines[r] ~= '' then
      return nil
    end
  end
  return nil
end

--- The sigil (`#`, `!`, `@` or `^`) of the cfait smart-input word the
--- cursor (`col` 0-based) ends in `line`, or nil.
function M.sigil_at(line, col)
  return (' ' .. line:sub(1, col)):match('%s([#!@^])[^%s#!@^]*$')
end

local function provider_for(bufnr)
  local name = vim.fs.basename(vim.api.nvim_buf_get_name(bufnr))
  for _, provider in ipairs(M.providers) do
    if provider.file == name or provider.filetype == vim.bo[bufnr].filetype then
      return provider
    end
  end
end

-- The command completing at the cursor (`row` 1-based, `col` 0-based)
local function command_at(provider, lines, row, col)
  if provider.sigils then
    return provider.sigils[M.sigil_at(lines[row], col)]
  end
  local key = M.key_at(lines, row, col)
  return key and provider.keys[key]
end

-- One run per command and session; callbacks wait for a run in flight.
local cache, waiting = {}, {}

-- The values of `command`: its output, or its fixed `list`
local function values(command, callback)
  if command.list then
    return callback(command.list)
  end
  local cache_key = table.concat(command, ' ')
  if cache[cache_key] then
    return callback(cache[cache_key])
  end
  if waiting[cache_key] then
    return table.insert(waiting[cache_key], callback)
  end
  waiting[cache_key] = { callback }
  local ok = pcall(vim.system, command, { text = true }, function(result)
    local list = result.code == 0 and vim.split(result.stdout, '\n', { trimempty = true }) or {}
    vim.schedule(function()
      if result.code == 0 then
        cache[cache_key] = list
      end
      for _, waiter in ipairs(waiting[cache_key]) do
        waiter(list)
      end
      waiting[cache_key] = nil
    end)
  end)
  if not ok then -- command not installed
    waiting[cache_key] = nil
    callback({})
  end
end

local source = {}

function source:is_available()
  return provider_for(0) ~= nil
end

function source:get_debug_name()
  return 'workflow_tags'
end

function source:get_trigger_characters()
  return { ' ', '[', ',', '-', '#', '!', '@', '^' }
end

function source:get_keyword_pattern()
  return [[\%(\k\|[-.+/:]\)\+]] -- ':' for cfait's tag hierarchy
end

function source:complete(params, callback)
  local provider = provider_for(0)
  local row, col = params.context.cursor.row, params.context.cursor.col - 1
  local lines = vim.api.nvim_buf_get_lines(0, 0, row, false)
  local command = provider and command_at(provider, lines, row, col)
  if not command then
    return callback({ items = {}, isIncomplete = false })
  end
  values(command, function(list)
    local items = {}
    for i, value in ipairs(list) do
      -- a fixed list keeps its order (soonest date first)
      local sort = command.list and ('%02d'):format(i) or nil
      table.insert(items, { label = value, sortText = sort, kind = vim.lsp.protocol.CompletionItemKind.Keyword })
    end
    callback({ items = items, isIncomplete = false })
  end)
end

function M.setup()
  local ok, cmp = pcall(require, 'cmp')
  if ok then
    cmp.register_source('workflow_tags', source)
  end
end

return M
