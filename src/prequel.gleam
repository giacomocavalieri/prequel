import gleam/io
import prequel/parser
import prequel/pretty_printer
import gleam/result

pub fn main() {
  let str =
    "
entity prova {
      -o prova
  -* 
prova
  -> rel2:(1-1) pupu (1-N)
  -* prova & pippo
  -o   pluto : 
  (1-1)


  -> rel : (1-1) pippo (0-N) {
    -o prova
  }


  -> rel3:(1-1) papa (1-N)
}
"

  io.println(str <> "\n-------BIBIDI-BOBOBIDI-BU-------\n")
  str
  |> parser.parse
  |> result.map(fn(module) {
    pretty_printer.pretty(module)
    |> io.println
  })
}
