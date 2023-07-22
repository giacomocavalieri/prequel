import gleam/option.{Option}
import prequel/ast.{Cardinality}
import prequel/span.{Span}

/// TODO: add doc
pub type ValidationError {
  LowerBoundBiggerThanUpperBound(
    hint: Option(String),
    enclosing_definition: Span,
    cardinality: Cardinality,
  )
}
