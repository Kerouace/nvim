-- Formatting: Dedicated formatters for each language

-- Formatters to use (and install via Mason on non-NixOS)
local formatters = {
  lua = { 'stylua' },
  python = { 'black' },
  c = { 'clang-format' },
  cpp = { 'clang-format' },
  verilog = { 'verible_verilog_format' },
  systemverilog = { 'verible_verilog_format' },
  tex = { 'latexindent' },
  yaml = { 'yamlfmt' },
  nix = { 'alejandra' },
  markdown = { 'prettier' },
  json = { 'prettier' },
  javascript = { 'prettier' },
  typescript = { 'prettier' },
  html = { 'prettier' },
  css = { 'prettier' },
}

-- Mason package names (some differ from formatter names)
local mason_packages = {
  'stylua',
  'black',
  'clang-format',
  -- verible installed via lsp.lua
  'latexindent',
  'yamlfmt',
  'prettier',
}

return {
  -- Install formatters via Mason (non-NixOS only)
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    cond = function()
      return vim.g.system_id ~= 'nixos'
    end,
    opts = {
      ensure_installed = mason_packages,
    },
  },

  -- Formatter config
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>lf',
        function()
          require('conform').format({ async = true })
        end,
        mode = '',
        desc = '[L]SP [F]ormat buffer',
      },
    },
    opts = {
      formatters_by_ft = formatters,

      -- Format on save (optional - uncomment to enable)
      -- format_on_save = {
      --   timeout_ms = 500,
      -- },
    },
  },
}
