-- cfait smart input: the window promoting a Backlog item to a Todo
-- (lua/workflow/todo.lua) expands `todo` after the item's text. Tabstops
-- left as they are or emptied are dropped before `cfait add`.
local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

return {
  s("todo", fmt("!{} @{} ^{} #{}", { i(1, "prio"), i(2, "due"), i(3, "start"), i(4, "tag") })),
}
