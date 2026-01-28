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

-- Comment styles per filetype
local comment_chars = {
  lua = "--",
  python = "#",
  verilog = "//",
  systemverilog = "//",
  vhdl = "--",
  c = "//",
  cpp = "//",
  make = "#",
}

local function get_comment_char()
  return comment_chars[vim.bo.filetype] or "#"
end

local function gpl_header()
  local c = get_comment_char()
  local year = os.date("%Y")
  return sn(nil, {
    t(c .. " Copyright (C) " .. year .. " "),
    i(1, "Your Name"),
    t({
      "",
      c,
      c .. " This program is free software: you can redistribute it and/or modify",
      c .. " it under the terms of the GNU General Public License as published by",
      c .. " the Free Software Foundation, either version 3 of the License, or",
      c .. " (at your option) any later version.",
      c,
      c .. " This program is distributed in the hope that it will be useful,",
      c .. " but WITHOUT ANY WARRANTY; without even the implied warranty of",
      c .. " MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the",
      c .. " GNU General Public License for more details.",
      c,
      c .. " You should have received a copy of the GNU General Public License",
      c .. " along with this program. If not, see <https://www.gnu.org/licenses/>.",
      "",
    }),
  })
end

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

  s(
    {
      trig = "gpl",
      dscr = "GPL-3.0-or-later copyright header",
      snippetType = "snippet",
    },
    { d(1, gpl_header) }
  ),
}
