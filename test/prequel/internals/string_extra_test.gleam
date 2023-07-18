import gleeunit/should
import gleam_community/ansi
import prequel/internals/string_extra
import gleam/io

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
