import gleeunit/should
import prequel/internals/string_extra

pub fn split_at_test() {
  "hello"
  |> string_extra.split_at(2)
  |> should.equal(#("hel", "lo"))

  "hello"
  |> string_extra.split_at(1)
  |> should.equal(#("he", "llo"))

  "hello"
  |> string_extra.split_at(0)
  |> should.equal(#("h", "ello"))
}
