import gleeunit/should
import prequel/internals/int_extra

pub fn count_digits_test() -> Nil {
  int_extra.count_digits(0)
  |> should.equal(1)

  int_extra.count_digits(11)
  |> should.equal(2)

  int_extra.count_digits(123)
  |> should.equal(3)

  int_extra.count_digits(123_456_789)
  |> should.equal(9)

  int_extra.count_digits(-11)
  |> should.equal(2)

  int_extra.count_digits(-123)
  |> should.equal(3)

  int_extra.count_digits(-123_456_789)
  |> should.equal(9)
}

pub fn is_next_to_test() -> Nil {
  1
  |> int_extra.is_next_to(2)
  |> should.equal(True)

  1
  |> int_extra.is_next_to(0)
  |> should.equal(True)

  1
  |> int_extra.is_next_to(11)
  |> should.equal(False)
}
