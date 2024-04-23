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
  s(
    { -- Table 1: snippet parameters
      trig="today",
      dscr="This snippet adds the corrent date (yyyy-mm-dd).",
      regTrig=false,          -- tirgger is not lua regex (default)
      priority=100,           -- default is 1000
      snippetType="snippet",  -- autosnippet/snippet; snippet is default
    },
    { -- Table 2: snippet nodes
      f(function()
          return os.date "%Y-%m-%d"
      end),
    }
  ),
}
