return {
  s({trig = "log", dscr="A simple logging function"},
    fmt(
      [[
        def log(verbose, level, message, param=[]):
            if(verbose >= level):
                print(message.format(param))
        {}
      ]],
      {i(0)},
      {}
    )
  ),
}
