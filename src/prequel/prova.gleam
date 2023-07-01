import gleam/io
import prequel
import gleam/result
import prequel/pretty_printer

pub fn main() {
  let str = ""
  io.println(str <> "\n-------BIBIDI-BOBOBIDI-BU-------\n")
  str
  |> prequel.parse
  |> result.map(fn(module) {
    pretty_printer.pretty(module)
    |> io.println
  })
}
