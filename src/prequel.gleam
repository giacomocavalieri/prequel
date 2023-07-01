import gleam/io
import prequel/parser
import prequel/pretty_printer
import gleam/result

pub fn main() {
  let str =
    "

entity pipo_ritto








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

  total overlapped hierarchy {
         entity bazz
    entity foo {
      -o prova
    }
    entity bar

    entity baz {
      partial disjoint hierarchy {
        entity dog
      }
    }
  }
}

relationship prova2 {
  -> ciao : (1-1)
  -> core : (2-1)

  -o prova
}

entity pipi_ritti




relationship prova {
  -> come : (1-1)
  -> stai : (0-N)
  -> cane : (3-N)
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
