import gleam/option.{None, Option}
import non_empty_list.{NonEmptyList}
import prequel/ast.{Cardinality, Entity}
import prequel/span.{Span}
import prequel/internals/report.{ContextBlock, ErrorBlock, Report, ReportBlock}

/// TODO: add doc
pub type ValidationError {
  LowerBoundGreaterThanUpperBound(
    hint: Option(String),
    enclosing_definition: Span,
    cardinality: Cardinality,
  )
  DuplicateEntityName(
    hint: Option(String),
    first_entity: Entity,
    other_entity: Entity,
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
    DuplicateEntityName(_, _, other_entity) -> other_entity.span
  }
}

fn name(of error: ValidationError) -> String {
  case error {
    LowerBoundGreaterThanUpperBound(_, _, _) ->
      "Lower bound greater than upper bound"
    DuplicateEntityName(_, _, _) -> "Duplicate entity name"
  }
}

fn code(of error: ValidationError) -> String {
  case error {
    LowerBoundGreaterThanUpperBound(_, _, _) -> "VE001"
    DuplicateEntityName(_, _, _) -> "VE002"
  }
}

fn blocks(of error: ValidationError) -> NonEmptyList(ReportBlock) {
  case error {
    LowerBoundGreaterThanUpperBound(_, enclosing_entity, cardinality) ->
      non_empty_list.new(
        ContextBlock(enclosing_entity),
        [ErrorBlock(cardinality.span, None, message(error))],
      )
    DuplicateEntityName(_, one, other) ->
      non_empty_list.new(
        ErrorBlock(one.span, None, message(error)),
        [ErrorBlock(other.span, None, "...and here is the other one")],
      )
  }
}

fn message(error: ValidationError) -> String {
  case error {
    LowerBoundGreaterThanUpperBound(_, _, _) ->
      "The lower bound of a cardinality should always be lower than its upper bound"
    DuplicateEntityName(_, _, _) ->
      "Two entities cannot have the same name. Here is the first one..."
  }
}
