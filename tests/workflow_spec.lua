-- Tests for the pure parts of lua/workflow/. Run from the config root:
--   nvim -l tests/workflow_spec.lua

vim.opt.rtp:prepend(vim.fn.getcwd())

local failures, count = 0, 0

local function test(name, fn)
  count = count + 1
  local ok, err = pcall(fn)
  if not ok then
    failures = failures + 1
    print('FAIL ' .. name .. '\n  ' .. tostring(err))
  end
end

local function eq(actual, expected)
  if not vim.deep_equal(actual, expected) then
    error(('expected %s, got %s'):format(vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

local papis = require('workflow.papis')

-- link_at(line, col): col is 0-based, as nvim_win_get_cursor gives it
local two = 'see [ishai2003](papis://aaa111) and [dhooghe2022](papis://bbb222).'

test('cursor on the link text gives that Reference ID', function()
  eq(papis.link_at(two, two:find('ishai') - 1), 'aaa111')
end)

test('cursor on the link target gives that Reference ID', function()
  eq(papis.link_at(two, two:find('bbb') - 1), 'bbb222')
end)

test('cursor on the brackets counts as on the link', function()
  eq(papis.link_at(two, two:find('%[dhooghe') - 1), 'bbb222')
  eq(papis.link_at(two, two:find('%)%.') - 1), 'bbb222')
end)

test('an action URI gives the Reference ID', function()
  local line = '[annotate](papis://ccc333/annotate)'
  eq(papis.link_at(line, 3), 'ccc333')
end)

test('a bare papis:// URL counts as a link', function()
  local line = 'url: papis://ddd444'
  eq(papis.link_at(line, #line - 1), 'ddd444')
end)

test('off the links, the only link on the line is taken', function()
  local line = 'Reference: [k](papis://eee555)'
  eq(papis.link_at(line, 0), 'eee555')
end)

test('off the links with several on the line gives nothing', function()
  eq(papis.link_at(two, 0), nil)
end)

test('no link gives nothing', function()
  eq(papis.link_at('plain [text](other.md)', 2), nil)
end)

local tags = require('workflow.tags')

-- key_at(lines, row, col): the top-level YAML key whose value the cursor is
-- in (row 1-based, col 0-based), nil on a key itself
local info = {
  'author_list:',
  '- family: Dhooghe',
  '  given: Siemen',
  'project: hw-sec',
  'tags:',
  '- FIA',
  '- ',
  'title: The Random Fault Model',
}

test('a block list item belongs to the key above it', function()
  eq(tags.key_at(info, 6, 3), 'tags')
  eq(tags.key_at(info, 7, 2), 'tags')
end)

test('a nested list belongs to its own key', function()
  eq(tags.key_at(info, 3, 9), 'author_list')
end)

test('a scalar value belongs to its key', function()
  eq(tags.key_at(info, 4, 12), 'project')
  eq(tags.key_at(info, 8, 10), 'title')
end)

test('an inline list belongs to its key', function()
  eq(tags.key_at({ 'tags: [FIA, ]' }, 1, 12), 'tags')
end)

test('typing the key itself is not a value', function()
  eq(tags.key_at({ 'tag' }, 1, 3), nil)
  eq(tags.key_at({ 'tags:' }, 1, 3), nil)
end)

-- sigil_at(line, col): col 0-based, the text before it is what was typed
test('a #tag, !prio, @due or ^start being typed gives its sigil', function()
  eq(tags.sigil_at('read RFM #', 10), '#')
  eq(tags.sigil_at('#wo', 3), '#')
  eq(tags.sigil_at('read #work:te !2', 13), '#')
  eq(tags.sigil_at('read !', 6), '!')
  eq(tags.sigil_at('read !2 @tom', 12), '@')
  eq(tags.sigil_at('read ^mon', 9), '^')
end)

test('outside such a word, or a sigil inside a word, is none', function()
  eq(tags.sigil_at('read #work now', 14), nil)
  eq(tags.sigil_at('issue#4', 7), nil)
  eq(tags.sigil_at('read #work', 3), nil)
  eq(tags.sigil_at('mail me@host', 12), nil)
  eq(tags.sigil_at('read @@home', 11), nil)
end)

local bib = require('workflow.bib')

test('one key is cited alone', function()
  eq(bib.cite_text({ 'Ishai2003' }), '\\cite{Ishai2003}')
end)

test('several keys share one \\cite', function()
  eq(bib.cite_text({ 'Ishai2003', 'DBLP:conf/ches/X' }), '\\cite{Ishai2003,DBLP:conf/ches/X}')
end)

test('the sync diff goes from papis to the .bib', function()
  local lines = bib.diff_lines({
    papis_id = 'aaa111',
    papis = '@article{K,\n  year = {1973},\n}',
    bib = '@article{K,\n  year = {1974},\n}',
  })
  eq(lines, {
    '--- papis',
    '+++ bib/bibliography.bib',
    '@@ -2 +2 @@',
    '-  year = {1973},',
    '+  year = {1974},',
  })
end)

local backlog = require('workflow.backlog')

-- relink(text, from, to): folders relative to the notebook root, '' is the root
test('a link moved into a subfolder climbs back to the root', function()
  eq(backlog.relink('- see [x](0d09.md)', '', 'journal/meeting'), '- see [x](../../0d09.md)')
end)

test('URLs, anchors and absolute paths are left alone', function()
  local text = '[k](papis://aaa111) [w](https://x.org/a) [h](#top) [a](/etc/x) [m](mailto:a@b.c)'
  eq(backlog.relink(text, '', 'journal/meeting'), text)
end)

test('an embed keeps its title and a link its section', function()
  eq(
    backlog.relink('![fig](media/a.png "A") [s](0d09.md#idea)', '', 'journal/meeting'),
    '![fig](../../media/a.png "A") [s](../../0d09.md#idea)'
  )
end)

test('between sibling folders only the differing part changes', function()
  eq(backlog.relink('[m](../meeting/x.md) [r](../../0d09.md)', 'journal/daily', 'journal/meeting'), '[m](x.md) [r](../../0d09.md)')
end)

test('nothing changes when both are the root', function()
  eq(backlog.relink('[x](media/a.png)', '', ''), '[x](media/a.png)')
end)

test('items go after the last line, trailing blank lines dropped', function()
  eq(backlog.append_end({ '# T', '', 'text', '', '' }, { '- a', '- b' }), { '# T', '', 'text', '', '- a', '- b' })
end)

test('items join a list that ends the Note', function()
  eq(backlog.append_end({ '# T', '', '- x' }, { '- a' }), { '# T', '', '- x', '- a' })
end)

local done = backlog.done_heading

test('items fill an empty section of a fresh daily note', function()
  local daily = { '# 2026-10-19', '', '## What have I done today?', '', '', '## Open Questions.' }
  eq(backlog.append_under(daily, done, { '- a' }), {
    '# 2026-10-19',
    '',
    '## What have I done today?',
    '',
    '- a',
    '',
    '## Open Questions.',
  })
end)

test('items follow what is already logged, subheadings included', function()
  local daily = { '## What have I done today?', '- x', '### detail', '- y', '', '', '## Open Questions.', '- q' }
  eq(backlog.append_under(daily, done, { '- a', '- b' }), {
    '## What have I done today?',
    '- x',
    '### detail',
    '- y',
    '- a',
    '- b',
    '',
    '## Open Questions.',
    '- q',
  })
end)

test('a missing heading is added at the end', function()
  eq(backlog.append_under({ '# 2026-10-19', '', 'notes' }, done, { '- a' }), {
    '# 2026-10-19',
    '',
    'notes',
    '',
    '## What have I done today?',
    '',
    '- a',
  })
end)

test('an item is its line without the bullet', function()
  eq(backlog.item_text('- read the RFM paper'), 'read the RFM paper')
  eq(backlog.item_text('  * nested '), 'nested')
  eq(backlog.item_text('no bullet'), 'no bullet')
end)

local todo = require('workflow.todo')

-- from_item(line, dir): dir is the Backlog's folder
test('a papis link becomes the url and its label stays in the title', function()
  eq(todo.from_item('- read [Ishai2003](papis://aaa111) again', '/nb'), { text = 'read Ishai2003 again', url = 'papis://aaa111' })
end)

test('a Note link becomes a file:// url, .md added when zk dropped it', function()
  eq(todo.from_item('- see [idea](0d09.md)', '/nb').url, 'file:///nb/0d09.md')
  eq(todo.from_item('- see [idea](journal/x)', '/nb').url, 'file:///nb/journal/x.md')
  eq(todo.from_item('- see [idea](../up.md)', '/nb/sub').url, 'file:///nb/up.md')
end)

test('the first link is the url; anchors and embeds are not links to a context', function()
  eq(todo.from_item('- [a](https://a.org) and [b](papis://b)', '/nb'), { text = 'a and b', url = 'https://a.org' })
  eq(todo.from_item('- [s](#top) ![fig](media/a.png) plain', '/nb'), { text = 's ![fig](media/a.png) plain' })
end)

test('a bare URL is the url and stays in the title', function()
  eq(todo.from_item('- https://x.org/a#b read later', '/nb'), { text = 'https://x.org/a#b read later', url = 'https://x.org/a#b' })
  eq(todo.from_item('- see papis://ccc333.', '/nb').url, 'papis://ccc333')
end)

test('a markdown link before a bare URL wins', function()
  eq(todo.from_item('- [k](papis://a) https://x.org', '/nb').url, 'papis://a')
end)

-- clean(text, untouched): untouched are the snippet's tokens as expanded
local snippet = { '!prio', '@due', '^start', '#tag' }

test('untouched and emptied tabstops are dropped, filled ones kept', function()
  eq(todo.clean('read RFM !2 @due ^ #work', snippet), 'read RFM !2 #work')
  eq(todo.clean('read RFM !prio @due ^start #tag', snippet), 'read RFM')
end)

local media = require('workflow.media')

test('a media name is the description slugged plus the hash', function()
  eq(media.name('Leakage in Montgomery reduction', '52ade0dd'), 'leakage-in-montgomery-reduction-52ade0dd')
  eq(media.name('  FSM: idle -> run (v2)! ', 'abcdef01'), 'fsm-idle-run-v2-abcdef01')
end)

test('umlauts and ß are spelled out in a media name', function()
  eq(media.name('Größe über Ärger', '00000000'), 'groesse-ueber-aerger-00000000')
end)

-- embed(description, note, file): both absolute paths
test('an embed in a Note at the root points into ./media', function()
  eq(media.embed('A sketch', '/nb/0d09.md', '/nb/media/a-sketch-1.png'), '![A sketch](./media/a-sketch-1.png)')
end)

test('an embed in a Note in a subfolder climbs out to media', function()
  eq(media.embed('x', '/nb/journal/daily/2026-10-20.md', '/nb/media/x-1.png'), '![x](../../media/x-1.png)')
end)

test('brackets in the description are escaped in the embed', function()
  eq(media.embed('a [b] c', '/nb/n.md', '/nb/media/m.png'), '![a \\[b\\] c](./media/m.png)')
end)

-- embed_at(line, col, note): col is 0-based, note the Note's absolute path
local pair = '![one](./media/one.png) and ![two](../media/two.png)'

test('the embed under the cursor resolves from the Note\'s folder', function()
  eq(media.embed_at(pair, pair:find('one') - 1, '/nb/n.md'), '/nb/media/one.png')
  eq(media.embed_at(pair, pair:find('two%.') - 1, '/nb/journal/n.md'), '/nb/media/two.png')
end)

test('off the embeds, the only embed on the line is taken', function()
  local line = 'Figure: ![x](./media/x.png "Leakage 10.000 samples")'
  eq(media.embed_at(line, 0, '/nb/n.md'), '/nb/media/x.png')
end)

test('off the embeds with several on the line, or a link, gives nothing', function()
  eq(media.embed_at(pair, pair:find(' and ') - 1, '/nb/n.md'), nil)
  eq(media.embed_at('[note](0d09.md)', 2, '/nb/n.md'), nil)
end)

test('an embed with a .xopp beside it opens the Drawing, else the image', function()
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, 'p')
  vim.fn.writefile({}, dir .. '/d-1.xopp')
  eq(media.open_command(dir .. '/d-1.png'), { 'drawing-edit', dir .. '/d-1.xopp' })
  eq(media.open_command(dir .. '/s-2.png'), { 'swayimg', dir .. '/s-2.png' })
  vim.fn.delete(dir, 'rf')
end)

print(('%d tests, %d failed'):format(count, failures))
os.exit(failures == 0 and 0 or 1)
