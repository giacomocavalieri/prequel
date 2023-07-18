import gleam/bool
import gleam/int
import non_empty_list.{NonEmptyList}

/// A span indicating a slice of a source code file.
/// 
pub type Span {
  Span(line_start: Int, line_end: Int, column_start: Int, column_end: Int)
}

/// Creates a new span given its start line, end line, start column and end
/// column.
/// 
/// ## Examples
/// 
/// ```gleam
/// > new(1, 2, 3, 4)
/// Span(1, 2, 3, 4)
/// ```
/// 
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
/// ## Examples
/// 
/// ```gleam
/// > segment(1, 2 ,5)
/// Span(1, 1, 2, 5)
/// ```
/// 
pub fn segment(line: Int, column_start: Int, column_end: Int) -> Span {
  Span(line, line, column_start, column_end)
}

/// Creates a span that spans over a single line and a single column.
/// 
/// ## Examples
/// 
/// ```gleam
/// > point(1, 2)
/// Span(1, 1, 2, 2)
/// ```
/// 
pub fn point(line: Int, column: Int) -> Span {
  Span(line, line, column, column)
}

/// Merge two spans together obtaining the largest possible span: it starts from
/// the smallest line and column and ends at the largest line and column.
/// 
/// ## Examples
/// 
/// ```gleam
/// > point(1, 2) |> merge(point(3, 1))
/// Span(1, 3, 1, 2)
/// ```
/// 
/// ```gleam
/// > new(1, 4, 3, 4) |> merge(new(3, 5, 2, 3))
/// Span(1, 5, 2, 4)
/// ```
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

/// Returns true if the given span is a single-line segment, that is if its
/// starting and ending line are the same.
/// 
/// ## Examples
/// 
/// ```gleam 
/// > is_segment(segment(1, 2, 3))
/// True
/// ```
/// 
/// ```gleam
/// > is_segment(point(2, 5))
/// True
/// ```
/// 
/// ```gleam
/// > is_segment(new(1, 2, 3, 4))
/// False
/// ```
/// 
pub fn is_segment(span: Span) -> Bool {
  span.line_start == span.line_end
}

/// Returns true if the span starts at the given line.
/// 
/// ## Examples
/// 
/// ```gleam
/// > point(1, 2) |> starts_at_line(1)
/// True
/// ```
/// 
/// ```gleam
/// > point(11, 1) |> starts_at_line(1)
/// False
/// ```
///
pub fn starts_at_line(span: Span, line: Int) -> Bool {
  span.line_start == line
}

/// Returns true if the span ends on the given line.
/// 
/// ## Examples
/// 
/// ```gleam
/// > point(1, 2) |> ends_on_line(1)
/// True
/// ```
/// 
/// ```gleam
/// > point(11, 2) |> ends_on_line(1)
/// False
/// ```
///
pub fn ends_on_line(span: Span, line: Int) -> Bool {
  span.line_end == line
}

/// Returns true if the given line is contained inside the span.
/// 
/// ## Examples
/// 
/// ```gleam
/// > new(1, 11, 2, 3) |> contains_line(1)
/// True
/// ```
/// 
/// ```gleam
/// > new(1, 11, 2, 3) |> contains_line(11)
/// True
/// ```
/// 
/// ```gleam
/// > new(1, 11, 2, 3) |> contains_line(10)
/// True
/// ```
/// 
/// ```gleam
/// > new(1, 11, 2, 3) |> contains_line(12)
/// False
/// ```
/// 
pub fn contains_line(span: Span, line: Int) -> Bool {
  span.line_start <= line && line <= span.line_end
}

/// The position of a line (or column) relative to a span: it could either be
/// its first or last line, it could be inside the span, or it could be outside
/// of it.
/// 
/// You can look at the `classify_line` for an example usage of this type.
/// 
pub type Position {
  First
  Inside
  Last
  Outside
}

/// Returns the position of a line relative to the given span:
/// - `First` means that the given line is the first line of the span
/// - `Last` means that the given line is the last line of the span
/// - `Inside` means that the line falls between the first and last lines of the
///   span
/// - `Outside` is for a line that is not contained inside the span
/// 
/// ## Examples
/// 
/// ```gleam
/// > classify_line(new(1, 3, 2, 2), 1)
/// First
/// ```
/// 
/// ```gleam
/// > classify_line(new(1, 3, 2, 2), 2)
/// Inside
/// ```
/// 
/// ```gleam
/// > classify_line(new(1, 3, 2, 2), 3)
/// Last
/// ```
/// 
/// ```gleam
/// > classify_line(new(1, 3, 2, 2), 4)
/// Outside
/// ```
/// 
pub fn classify_line(span: Span, line: Int) -> Position {
  use <- bool.guard(when: starts_at_line(span, line), return: First)
  use <- bool.guard(when: ends_on_line(span, line), return: Last)
  use <- bool.guard(when: contains_line(span, line), return: Inside)
  Outside
}
