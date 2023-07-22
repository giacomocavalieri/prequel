import gleam/io
import gleam/result
import gleam/string_builder
import prequel
import prequel/error/pipeline_error
import prequel/pretty_printer
import simplifile

pub fn main() {
  let file_name = "prova.prequel"
  let assert Ok(source_code) = simplifile.read(file_name)

  prequel.parse(source_code)
  |> result.map(pretty_printer.format)
  |> result.map_error(pipeline_error.format(_, file_name, source_code))
  |> result.unwrap_both
  |> string_builder.to_string
  |> io.println
}
