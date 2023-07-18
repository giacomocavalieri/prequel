import gleam/io
import gleam/result
import prequel
import prequel/parse_error
import prequel/pretty_printer
import simplifile

pub fn main() {
  let file_name = "prova.prequel"
  let assert Ok(source_code) = simplifile.read(file_name)

  prequel.parse(source_code)
  |> result.map(fn(module) {
    pretty_printer.pretty(module)
    |> io.println
  })
  |> result.map_error(fn(error) {
    parse_error.to_pretty_string(error, file_name, source_code)
    |> io.println
  })
}
