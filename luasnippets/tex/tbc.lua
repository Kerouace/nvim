return {

  s(
    {trig=",bf", snippetType="autosnippet", dscr="Bold Text"},
    fmta(
      [[
        \textbf{<>} <>
      ]],
      { i(1), i(2) }
    )
  ),

  s(
    {trig=",tt", snippetType="autosnippet", dscr="? Text"},
    fmta(
      [[
        \texttt{<>} <>
      ]],
      { i(1), i(2) }
    )
  ),

  s(
    {trig=",it", snippetType="autosnippet", dscr="Italic Text"},
    fmta(
      [[
        \textit{<>} <>
      ]],
      { i(1), i(2) }
    )
  ),

  s(
    {trig=",em", snippetType="autosnippet", dscr="Emphecise Text"},
    fmta(
      [[
        \emph{<>} <>
      ]],
      { i(1), i(2) }
    )
  ),

  s(
    {trig=",nc", snippetType="autosnippet", dscr="Create a new command"},
    fmta(
      [[
        \newcommand{<>}{<>}{<>}
      ]],
      { i(1, "cmd"), i(2, "num arg"), i(3, "exp") }
    )
  ),

  s(
    {trig=",ig", snippetType="autosnippet", dscr="Include a graphic"},
    fmta(
      [[
	    \includegraphics[width=<>\textwidth]{<>}
      ]],
      {
        i(1),
        i(2, "path"),
      }
    )
  ),
}
