import gleam/result
import non_empty_list
import prequel/ast.{Module}
import prequel/error/pipeline_error.{PipelineError}
import prequel/internals/checker
import prequel/internals/token
import prequel/internals/parser

/// Parses a string into a `Module`.
/// 
pub fn parse(source: String) -> Result(Module, PipelineError) {
  let parse_result =
    token.scan(source)
    |> parser.parse
    |> result.map_error(pipeline_error.ParsingFailure)

  use module <- result.then(parse_result)
  case checker.check_module(module) {
    [] -> Ok(module)
    [error, ..errors] ->
      Error(pipeline_error.ValidationFailure(non_empty_list.new(error, errors)))
  }
}
