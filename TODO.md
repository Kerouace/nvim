# Neovim Config TODOs

## Pending Decisions

### Trouble vs setloclist workflow
- Test both workflows with real code
- Decide whether to:
  1. Keep both `<leader>lq` (loclist) and `<leader>lx` (Trouble)
  2. Choose one and remove the other
  3. Add more Trouble features (references, symbols, quickfix, etc.)

Current keymaps:
- `<leader>lq` - vim.diagnostic.setloclist (traditional Vim loclist)
- `<leader>lx` - Trouble workspace diagnostics
- `<leader>lX` - Trouble buffer diagnostics

Potential Trouble additions to consider:
- `<leader>lr` - LSP references in Trouble
- `<leader>ls` - Document symbols/outline in Trouble
- `<leader>fq` - Quickfix in Trouble
- `<leader>ft` - Telescope results in Trouble
