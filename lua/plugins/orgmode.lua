local org_path = function(path)
  local org_directory = '~/sync/org'
  return ('%s/%s'):format(org_directory, path)
end

local orgmode = {
  'nvim-orgmode/orgmode',
  enabled = false,
  dependencies = {
    {
      -- checkout further plugins
      'akinsho/org-bullets.nvim', lazy = true
    },
  },
  keys = {
    '<leader>oa',
    '<leader>oc',
  },
  config = function()
    require('orgmode').setup({
      org_agenda_files = org_path('*.org'),
      org_default_notes_file = org_path('refile.org'),
      org_hide_emphasis_markers = true,
      org_agenda_text_search_extra_files = { 'agenda-archives' },
      org_todo_keywords = { 'TODO(t)', 'PROGRESS(p)', '|', 'DONE(d)', 'REJECTED(r)' },
      org_capture_templates = {
        t = {
          description = 'Refile',
          template = '* TODO %?\n  DEADLINE: %T',
        },
        T = {
          description = 'Todo',
          template = '* TODO %?\n  DEADLINE: %T',
          target = org_path('todos.org'),
        },
        w = {
          description = 'Work todo',
          template = '* TODO %?\n  DEADLINE: %T',
          target = org_path('work.org'),
        },
        d = {
          description = 'Daily',
          template = '* Daily %U \n  %?',
          target = org_path('work.org'),
          headline = 'Meetings',
        },
      },
    })
    require('org-bullets').setup({
      concealcursor = false,
      symbols = {
        checkboxes = {
          half = { '', 'OrgTSCheckboxHalfChecked' },
          done = { '✓', 'OrgDone' },
          todo = { '˟', 'OrgTODO' },
        },
      },
    })
  end
}

return orgmode
