-- workflow.check: :WorkflowCheck loads workflow-check's findings (dotfiles-nixos
-- maintenance/) into the quickfix list. Its lines are quickfix format, with
-- paths relative to Neovim's cwd when they are inside it.

local M = {}

function M.run(args)
  vim.notify('workflow-check…')
  local command = vim.list_extend({ 'workflow-check' }, args or {})
  local ok = pcall(vim.system, command, { text = true }, function(result)
    vim.schedule(function()
      -- 1: something found, 2: the check failed
      if result.code > 1 then
        return vim.notify('workflow-check failed: ' .. vim.trim(result.stderr), vim.log.levels.ERROR)
      end
      local lines = vim.split(result.stdout, '\n', { trimempty = true })
      vim.fn.setqflist({}, ' ', { title = 'workflow-check', lines = lines, efm = '%f:%l:%c: %m,%f:%l: %m' })
      if #lines == 0 then
        return vim.notify('workflow-check: nothing found')
      end
      vim.cmd('botright copen')
    end)
  end)
  if not ok then
    vim.notify('workflow-check is not installed', vim.log.levels.ERROR)
  end
end

function M.setup()
  -- :WorkflowCheck --no-pdf narrows it to References without a PDF; other
  -- flags print lines that are not quickfix
  vim.api.nvim_create_user_command('WorkflowCheck', function(opts)
    if opts.args ~= '' and opts.args ~= '--no-pdf' then
      return vim.notify('WorkflowCheck takes only --no-pdf', vim.log.levels.ERROR)
    end
    M.run(opts.fargs)
  end, { nargs = '?', complete = function() return { '--no-pdf' } end, desc = 'Load workflow-check findings into quickfix' })
end

return M
