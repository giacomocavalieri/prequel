import gleam/int
import non_empty_list.{NonEmptyList}
import gleam/order.{Eq, Gt, Lt, Order}

// TODO: Span could be a single number indicating the nth grapheme in the file
// I have no idea which one could be better.

/// A span indicating a slice of a source code file.
/// 
pub type Span {
  Span(line_start: Int, line_end: Int, column_start: Int, column_end: Int)
}

pub fn new(
  line_start: Int,
  line_end: Int,
  column_start: Int,
  column_end: Int,
) -> Span {
  Span(line_start, line_end, column_start, column_end)
}

/// Creates a span taht spans over a single line and multiple columns.
/// 
pub fn segment(line: Int, column_start: Int, column_end: Int) -> Span {
  Span(line, line, column_start, column_end)
}

/// Creates a span that spans a single line and column.
/// 
pub fn point(line: Int, column: Int) -> Span {
  Span(line, line, column, column)
}

/// Merge two spans together obtaining the largest possible span:
/// it starts from the smallest line and column and ends at the largest line
/// and column.
/// 
pub fn merge(one: Span, with other: Span) -> Span {
  Span(
    int.min(one.line_start, other.line_start),
    int.max(one.line_end, other.line_end),
    int.min(one.column_start, other.column_start),
    int.max(one.column_end, other.column_end),
  )
}

/// Returns the greatest line in a non empty list of spans.
/// 
/// ## Examples
/// 
/// ```gleam
/// > non_empty_list.new(point(14, 1), [segment(2, 4, 5)])
/// > |> max_line
/// 14
/// ```
/// 
pub fn max_line(spans: NonEmptyList(Span)) -> Int {
  spans
  |> non_empty_list.flat_map(fn(span) {
    non_empty_list.new(span.line_start, [span.line_end])
  })
  |> non_empty_list.sort(by: fn(n, m) { inverse_order(int.compare(n, m)) })
  |> non_empty_list.first
}

/// Returns the smallest line in a non empty list of spans.
/// 
/// ## Examples
/// 
/// ```gleam
/// > non_empty_list.new(point(14, 1), [segment(2, 4, 5)])
/// > |> min_line
/// 2
/// ```
/// 
pub fn min_line(spans: NonEmptyList(Span)) -> Int {
  spans
  |> non_empty_list.flat_map(fn(span) {
    non_empty_list.new(span.line_start, [span.line_end])
  })
  |> non_empty_list.sort(by: int.compare)
  |> non_empty_list.first
}

fn inverse_order(order: Order) -> Order {
  case order {
    Gt -> Lt
    Eq -> Eq
    Lt -> Gt
  }
}
