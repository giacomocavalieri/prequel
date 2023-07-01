import gleam/int

// TODO: Span could be a single number indicating the nth grapheme in the file
// I have no idea which one could be better.

/// A span indicating a slice of a source code file.
/// 
pub type Span {
  Span(line_start: Int, line_end: Int, column_start: Int, column_end: Int)
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
