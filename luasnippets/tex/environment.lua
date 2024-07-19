-- Abbreviations used in this article and the LuaSnip docs
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
  s( --
    {trig=",env", snippetType="autosnippet", dscr="Expands 'env' into an environment"},
    fmta(
       [[
         \begin{<>}
             <>
         \end{<>}
       ]],
       {
        i(1),
        i(2),
        rep(1),
      }
    )
  ),

  s(
    {trig=",fr", snippetType="autosnippet", dscr="Expands 'fr' into a frame"},
    fmta(
      [[
        \begin{frame}
          \frametitle{<>}
          \framesubtitle{\insertsection}

          <>
        \end{frame}
        <>
      ]],
      {
        i(1),
        i(2),
        i(3),
      }
    )
  ),

  s(
    {trig=",ni", snippetType="autosnippet", dscr="Expands 'ni' to a note item for a beamer slide"},
    fmta(
      [[
        \note[item]<<<>>>{<>}
        <>
      ]],
      {
      i(1),
      i(2),
      i(3),
      }
    )
  ),

  s(
    {trig=",cl", snippetType="autosnippet", dscr="Expands 'cl' into a columns environment"},
    fmta(
      [[
      \begin{columns}[c]
        \column{<>\textwidth}
          <>
        \end{columns}
      ]],
      {
        i(1),
        i(2),
      }
    )
  ),

  s(
    {trig=",fig", snippetType="autosnippet", dscr="Expands 'fig' into a figure"},
    fmta(
       [[
         \begin{figure}
          <>
         \end{figure}
       ]],
       {
        i(1),
      }
    )
  ),

  s(
    {trig=",ta", snippetType="autosnippet", dscr="Expands 'ta' into a table"},
    fmta(
      [[
         \begin{table}[<>]
          \centering
          \begin{tabular}{<>}
            <>
          \end{tabular}
          \caption{<>}
          \label{tab:<>}
         \end{table}
      ]],
       {
        i(1),
        i(2, "c|c"),
        i(3),
        i(5),
        i(4)
      }
    )
  ),

  s(
    {trig=",tikz", snippetType="autosnippet", dscr="Expands 'tikz' into a tikzpicture inside a figure"},
    fmta(
      [[
        \begin{figure}
            \centering
            \begin{tikzpicture}
              <>
            \end{tikzpicture}
        \end{figure}
      ]],
       {
        i(1),
      }
    )
  ),

  s(
    {trig=",ol", snippetType="autosnippet", dscr="Enumeration"},
    fmta(
      [[
        \begin{enumerate}
          \item <>
          <>
        \end{enumerate}
      ]],
      { i(1), i(2) }
    )
  ),

  s(
    {trig=",ul", snippetType="autosnippet", dscr="Itemize"},
    fmta(
       [[
        \begin{itemize}
          \item <>
          <>
        \end{itemize}
       ]],
       { i(1), i(2) }
    )
  ),

  s(
    {trig=",li", snippetType="autosnippet", dscr="List Item"},
    fmta(
       [[
        \item <>
       ]],
       { i(1) }
    )
  ),

  -- Math environment
  s(
    {trig=",eq", snippetType="autosnippet", dscr="Expands 'eq' into an equation environment"},
    fmta(
       [[
         \begin{equation*}
             <>
         \end{equation*}
       ]],
       { i(1) }
    )
  ),

}
