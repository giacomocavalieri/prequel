import gleam/list
import gleeunit/should
import non_empty_list
import prequel/span.{First, Inside, Last, Outside, Span}

pub fn new_test() {
  span.new(1, 2, 3, 4)
  |> should.equal(Span(1, 2, 3, 4))
}

pub fn segment_test() {
  span.segment(1, 2, 3)
  |> should.equal(span.new(1, 1, 2, 3))
}

pub fn point_test() {
  span.point(1, 3)
  |> should.equal(span.new(1, 1, 3, 3))
}

pub fn merge_test() {
  span.new(1, 4, 2, 6)
  |> span.merge(span.new(2, 6, 1, 4))
  |> should.equal(span.new(1, 6, 1, 6))
}

pub fn max_line_test() {
  non_empty_list.new(
    span.new(1, 2, 3, 4),
    [span.new(5, 6, 7, 8), span.new(9, 10, 11, 12)],
  )
  |> span.max_line
  |> should.equal(10)
}

pub fn max_column_test() {
  non_empty_list.new(
    span.new(1, 2, 3, 4),
    [span.new(5, 6, 7, 8), span.new(9, 10, 11, 12)],
  )
  |> span.max_column
  |> should.equal(12)
}

pub fn min_line_test() {
  non_empty_list.new(
    span.new(1, 2, 3, 4),
    [span.new(5, 6, 7, 8), span.new(9, 10, 11, 12)],
  )
  |> span.min_line
  |> should.equal(1)
}

pub fn min_column_test() {
  non_empty_list.new(
    span.new(1, 2, 3, 4),
    [span.new(5, 6, 7, 8), span.new(9, 10, 11, 12)],
  )
  |> span.min_column
  |> should.equal(3)
}

pub fn lines_test() {
  let lines = non_empty_list.to_list(span.lines(span.new(1, 2, 3, 4)))
  list.length(lines)
  |> should.equal(2)
  list.contains(lines, 1)
  |> should.equal(True)
  list.contains(lines, 2)
  |> should.equal(True)
}

pub fn columns_test() {
  let columns = non_empty_list.to_list(span.columns(span.new(1, 2, 3, 4)))
  list.length(columns)
  |> should.equal(2)
  list.contains(columns, 3)
  |> should.equal(True)
  list.contains(columns, 4)
  |> should.equal(True)
}

pub fn is_segment_test() {
  span.new(1, 2, 3, 4)
  |> span.is_segment
  |> should.equal(False)

  span.new(1, 1, 3, 4)
  |> span.is_segment
  |> should.equal(True)
}

pub fn starts_at_line_test() {
  span.new(1, 2, 3, 4)
  |> span.starts_at_line(1)
  |> should.equal(True)

  span.new(1, 2, 3, 4)
  |> span.starts_at_line(2)
  |> should.equal(False)

  span.new(1, 2, 3, 4)
  |> span.starts_at_line(3)
  |> should.equal(False)

  span.new(1, 2, 3, 4)
  |> span.starts_at_line(4)
  |> should.equal(False)
}

pub fn ends_on_line_test() {
  span.new(1, 2, 3, 4)
  |> span.ends_on_line(1)
  |> should.equal(False)

  span.new(1, 2, 3, 4)
  |> span.ends_on_line(2)
  |> should.equal(True)

  span.new(1, 2, 3, 4)
  |> span.ends_on_line(3)
  |> should.equal(False)

  span.new(1, 2, 3, 4)
  |> span.ends_on_line(4)
  |> should.equal(False)
}

pub fn contains_line_test() {
  span.new(1, 3, 4, 5)
  |> span.contains_line(1)
  |> should.equal(True)

  span.new(1, 3, 4, 5)
  |> span.contains_line(2)
  |> should.equal(True)

  span.new(1, 3, 4, 5)
  |> span.contains_line(3)
  |> should.equal(True)

  span.new(1, 3, 4, 5)
  |> span.contains_line(4)
  |> should.equal(False)

  span.new(1, 3, 4, 5)
  |> span.contains_line(5)
  |> should.equal(False)
}

pub fn classify_line_test() {
  span.new(1, 3, 4, 5)
  |> span.classify_line(1)
  |> should.equal(First)

  span.new(1, 3, 4, 5)
  |> span.classify_line(2)
  |> should.equal(Inside)

  span.new(1, 3, 4, 5)
  |> span.classify_line(3)
  |> should.equal(Last)

  span.new(1, 3, 4, 5)
  |> span.classify_line(4)
  |> should.equal(Outside)

  span.new(1, 3, 4, 5)
  |> span.classify_line(5)
  |> should.equal(Outside)
}
