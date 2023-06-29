import gleam/int

// TODO: Span could be a single number indicating the nth grapheme in the file
pub type Span {
  Span(line_start: Int, line_end: Int, column_start: Int, column_end: Int)
}

pub fn segment(line: Int, column_start: Int, column_end: Int) -> Span {
  Span(line, line, column_start, column_end)
}

pub fn point(line: Int, column: Int) -> Span {
  Span(line, line, column, column)
}

pub fn merge(one: Span, with other: Span) -> Span {
  Span(
    int.min(one.line_start, other.line_start),
    int.max(one.line_end, other.line_end),
    int.min(one.column_start, other.column_start),
    int.max(one.column_end, other.column_end),
  )
}
