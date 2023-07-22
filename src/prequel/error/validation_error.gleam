import gleam/option.{None, Option, Some}
import non_empty_list.{NonEmptyList}
import prequel/ast.{Cardinality}
import prequel/span.{Span}
import prequel/internals/report.{Report}

/// TODO: add doc
pub type ValidationError {
  LowerBoundGreaterThanUpperBound(
    hint: Option(String),
    enclosing_definition: Span,
    cardinality: Cardinality,
  )
}

pub fn to_report(
  error: ValidationError,
  file_name: String,
  source_code: String,
) -> Report {
  let main_span = main_span(error)
  let start = main_span.start_line
  let end = main_span.end_line
  let name = name(of: error)
  let code = code(of: error)
  let blocks = blocks(of: error)
  Report(file_name, source_code, name, code, start, end, blocks, error.hint)
}

fn main_span(error: ValidationError) -> Span {
  case error {
    LowerBoundGreaterThanUpperBound(_, _, cardinality) -> cardinality.span
  }
}

fn name(of error: ValidationError) -> String {
  case error {
    LowerBoundGreaterThanUpperBound(_, _, _) ->
      "Lower bound greater than upper bound"
  }
}

fn code(of error: ValidationError) -> String {
  case error {
    LowerBoundGreaterThanUpperBound(_, _, _) -> "VE001"
  }
}

fn blocks(of error: ValidationError) -> NonEmptyList(report.ReportBlock) {
  case error {
    LowerBoundGreaterThanUpperBound(_, enclosing_entity, cardinality) -> {
      todo
    }
  }
}
