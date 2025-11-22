-- Options: All vim.o / vim.opt settings
-- These control Neovim's behavior and appearance

local o = vim.o

-- Leader keys (must be set before plugins load)
vim.g.mapleader = ' '
vim.g.maplocalleader = ','

-- Mouse and clipboard
o.mouse = 'a'
o.clipboard = 'unnamedplus'  -- Sync with system clipboard

-- Tabs and indentation
o.expandtab = true   -- Use spaces instead of tabs
o.shiftwidth = 2     -- Indent by 2 spaces
o.tabstop = 2        -- Tab = 2 spaces

-- Window splits
o.splitbelow = true  -- Open horizontal splits below
o.splitright = true  -- Open vertical splits to the right

-- Search
o.ignorecase = true  -- Case insensitive search
o.smartcase = true   -- Unless uppercase is used

-- Appearance
o.termguicolors = true
o.cursorline = true
o.scrolloff = 10      -- Lines above/below cursor
o.sidescrolloff = 8   -- Columns left/right of cursor

-- Line numbers
vim.wo.number = true
vim.wo.relativenumber = true
vim.wo.signcolumn = 'yes'

-- Performance
o.updatetime = 250
o.timeout = true
o.timeoutlen = 300

-- Undo persistence
o.undofile = true
o.undodir = vim.env.XDG_CACHE_HOME .. "/nvim/undo"

-- Misc
o.hlsearch = false    -- Don't highlight search results
o.breakindent = true  -- Wrapped lines keep indentation

-- Completion
o.completeopt = 'menuone,noselect'
o.wildmode = 'longest:full,full'

-- Folding (disabled by default)
o.foldexpr = 'expr'
o.foldenable = false

-- Custom filetypes
vim.filetype.add({
  extension = {
    sage = 'python',  -- Treat .sage files as Python
  }
})
