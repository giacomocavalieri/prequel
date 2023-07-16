import gleam/io
import prequel
import gleam/result
import prequel/pretty_printer
import prequel/parse_error
import gleam_community/ansi

pub fn main() {
  let str =
    "
entity studente {
  -* matricola

  -o nome
  -o
     cognome cane
  -o età

  -> in_classe : (1-1) classe (1-30) {
    -o numero_di_registro
  }

  total disjoint hierarchy {
    entity studente_intercultura {
      -o matricola_estera
    }
  }
}

entity classe {
  -* numero
   & sezione

  -o 
  -o sezione

  -> capoclasse: (0-1) studente (1-1)
}
  "

  str
  |> prequel.parse
  |> result.map(fn(module) {
    ansi.green("Pretty printed module\n")
    |> io.println
    pretty_printer.pretty(module)
    |> io.println
  })
  |> result.map_error(fn(error) {
    parse_error.pretty("in_memory_string", str, error)
    |> io.println
  })
}
