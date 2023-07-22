import gleam/list
import gleam/string_builder.{StringBuilder}
import non_empty_list.{NonEmptyList}
import prequel/error/parse_error.{ParseError}
import prequel/error/validation_error.{ValidationError}
import prequel/internals/report

/// An error that may occur during the compilation pipeline.
/// 
pub type PipelineError {
  ParsingFailure(error: ParseError)
  ValidationFailure(errors: NonEmptyList(ValidationError))
}

pub fn format(
  error: PipelineError,
  file_name: String,
  source_code: String,
) -> StringBuilder {
  case error {
    ParsingFailure(error) ->
      parse_error.to_report(error, file_name, source_code)
      |> report.format
    ValidationFailure(errors) ->
      errors
      |> non_empty_list.to_list
      |> list.map(validation_error.to_report(_, file_name, source_code))
      |> list.map(report.format)
      |> string_builder.join(with: "\n\n\n")
  }
}
