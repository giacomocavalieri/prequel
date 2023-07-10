import gleeunit/should
import non_empty_list
import prequel/span

pub fn max_line_test() {
  non_empty_list.new(
    span.point(1, 1),
    [span.segment(10, 2, 3), span.new(3, 11, 2, 1)],
  )
  |> span.max_line
  |> should.equal(11)
}

pub fn min_line_test() {
  non_empty_list.new(
    span.point(1, 1),
    [span.segment(10, 2, 3), span.new(3, 11, 2, 1)],
  )
  |> span.min_line
  |> should.equal(1)
}
