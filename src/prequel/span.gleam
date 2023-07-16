import gleam/int
import non_empty_list.{NonEmptyList}

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
  non_empty_list.flat_map(spans, lines)
  |> non_empty_list.reduce(int.max)
}

/// Returns the smallest line in a non empty list of spans.
/// 
/// ## Examples
/// 
/// ```gleam
/// > non_empty_list.new(point(14, 1), [segment(2, 4, 5)])
/// > |> max_column
/// 5
/// ```
/// 
pub fn max_column(spans: NonEmptyList(Span)) -> Int {
  non_empty_list.flat_map(spans, columns)
  |> non_empty_list.reduce(int.max)
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
  non_empty_list.flat_map(spans, lines)
  |> non_empty_list.reduce(int.min)
}

/// Returns the smallest column in a non empty list of spans.
/// 
/// ## Examples
/// 
/// ```gleam
/// > non_empty_list.new(point(14, 1), [segment(2, 4, 5)])
/// > |> min_column
/// 1
/// ```
/// 
pub fn min_column(spans: NonEmptyList(Span)) -> Int {
  non_empty_list.flat_map(spans, columns)
  |> non_empty_list.reduce(int.min)
}

/// Returns a non empty list with the starting and ending lines of a span.
/// 
/// ## Examples
/// 
/// ```gleam
/// > lines(point(11, 1)) |> non_empty_list.to_list
/// [11]
/// ```
/// 
/// ```gleam
/// > lines(new(11, 15, 2, 4)) |> non_empty_list.to_list
/// [11, 15]
/// ```
/// 
pub fn lines(span: Span) -> NonEmptyList(Int) {
  non_empty_list.new(span.line_start, [span.line_end])
  |> non_empty_list.unique
}

/// Returns a non empty list with the starting and ending columns of a span.
/// 
/// ## Examples
/// 
/// ```gleam
/// > lines(point(11, 1)) |> non_empty_list.to_list
/// [1]
/// ```
/// 
/// ```gleam
/// > lines(new(11, 15, 2, 4)) |> non_empty_list.to_list
/// [2, 4]
/// ```
/// 
pub fn columns(span: Span) -> NonEmptyList(Int) {
  non_empty_list.new(span.column_start, [span.column_end])
  |> non_empty_list.unique
}
