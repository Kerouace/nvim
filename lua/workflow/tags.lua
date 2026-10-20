-- workflow.tags: one nvim-cmp source completing existing tags, so a tag is
-- never typed blind. Each provider names the files it serves and the command
-- printing the existing values one per line: per YAML key, or for the `#tag`
-- being typed (cfait smart input). New values can still be typed; the list
-- only offers what exists.

local M = {}

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
    hashtag = { 'sh', '-c', "cfait list --all --fields categories 2>/dev/null | tr ',' '\\n' | sort -u" },
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

--- Whether the cursor (`col` 0-based) ends a `#tag` being typed in `line`.
function M.hashtag_at(line, col)
  return (' ' .. line:sub(1, col)):match('%s#[^%s#]*$') ~= nil
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
  if provider.hashtag then
    return M.hashtag_at(lines[row], col) and provider.hashtag or nil
  end
  local key = M.key_at(lines, row, col)
  return key and provider.keys[key]
end

-- One run per command and session; callbacks wait for a run in flight.
local cache, waiting = {}, {}

local function values(command, callback)
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
  return { ' ', '[', ',', '-', '#' }
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
    for _, value in ipairs(list) do
      table.insert(items, { label = value, kind = vim.lsp.protocol.CompletionItemKind.Keyword })
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
