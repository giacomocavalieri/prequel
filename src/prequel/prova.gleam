import gleam/io
import gleam/result
import gleam_community/ansi
import prequel
import prequel/parse_error
import prequel/pretty_printer

pub fn main() {
  let str =
    "
entity classroom {
  -* number & letter
  
  -o number 
  -o letter
}

entity student {
  -* badge
  -o first_name
  -o last_name

  -> in_classroom : (1-1) classroom (1-30) {
    -o seat_number
  }
}

relationship in_classroom {
  -> prova : (1-1)
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
    parse_error.to_pretty_string(error, "foo.prequel", str)
    |> io.println
  })
}
