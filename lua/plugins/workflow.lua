-- workflow: local glue module in lua/workflow/ (no plugin to install)

return {
  'workflow',
  virtual = true,
  dependencies = { 'ibhagwan/fzf-lua', 'zk-org/zk-nvim' },
  config = function()
    require('workflow').setup()
  end,
}
