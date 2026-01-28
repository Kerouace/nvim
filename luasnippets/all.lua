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
    t(c .. " SPDX-FileCopyrightText: " .. year .. " "),
    i(1, "Your Name"),
    t(" <"),
    i(2, "email@example.com"),
    t({
      ">",
      c .. " SPDX-License-Identifier: GPL-3.0-or-later",
      c,
      c .. " Copyright (C) " .. year .. " ",
    }),
    rep(1),
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

local function cern_ohl_s_header()
  local c = get_comment_char()
  local year = os.date("%Y")
  return sn(nil, {
    t(c .. " SPDX-FileCopyrightText: " .. year .. " "),
    i(1, "Your Name"),
    t(" <"),
    i(2, "email@example.com"),
    t({
      ">",
      c .. " SPDX-License-Identifier: CERN-OHL-S-2.0",
      c,
      c .. " Copyright (C) " .. year .. " ",
    }),
    rep(1),
    t({
      "",
      c,
      c .. " This source describes Open Hardware and is licensed under the CERN-OHL-S v2.",
      c,
      c .. " You may redistribute and modify this source and make products using it under",
      c .. " the terms of the CERN-OHL-S v2 (https://ohwr.org/cern_ohl_s_v2.txt).",
      c,
      c .. " This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY,",
      c .. " INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A",
      c .. " PARTICULAR PURPOSE. Please see the CERN-OHL-S v2 for applicable conditions.",
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

  s(
    {
      trig = "cern",
      dscr = "CERN-OHL-S v2 copyright header",
      snippetType = "snippet",
    },
    { d(1, cern_ohl_s_header) }
  ),
}
