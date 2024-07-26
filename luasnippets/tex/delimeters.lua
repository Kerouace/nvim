-- Abbreviation used in the LuaSnip docs
local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local d = ls.dynamic_node
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep

return {
  s( -- \section
    {trig=",sec", snippetType="autosnippet", dscr="Expands 'sec' into a \\section{}"},
    fmta(
      [[
        \\section<>{<>}
        <>
      ]],
       {
        i(1),
        i(2),
        i(3)
      }
    )
  ),
  s( -- \subsection
    {trig=",ssec", snippetType="autosnippet", dscr="Expands 'ssec' into a \\subsection{}"},
    fmta(
      [[
        \\subsection<>{<>}
        <>
      ]],
       {
        i(1),
        i(2),
        i(3)
      }
    )
  ),
  s( -- \subsubsection
    {trig=",sssec", snippetType="autosnippet", dscr="Expands 'sssec' into a \\subsubsection{}"},
    fmta(
      [[
        \\subsubsection<>{<>}
        <>
      ]],
      {
        i(1),
        i(2),
        i(3)
      }
    )
  ),
  s( -- \subsubsection
    {trig=",par", snippetType="autosnippet", dscr="Expands 'par' into a \\paragraph{}"},
    fmta(
      [[
        \\paragraph{<>}"
        <>
      ]],
      {
        i(1),
        i(2)
      }
    )
  ),
}
