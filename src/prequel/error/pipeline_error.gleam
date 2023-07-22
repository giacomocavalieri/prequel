import non_empty_list.{NonEmptyList}
import prequel/error/parse_error.{ParseError}
import prequel/error/validation_error.{ValidationError}

/// An error that may occur during the compilation pipeline.
/// 
pub type PipelineError {
  ParsingFailure(error: ParseError)
  ValidationFailure(errors: NonEmptyList(ValidationError))
}

pub fn format(error: PipelineError) -> String {
  todo
}
