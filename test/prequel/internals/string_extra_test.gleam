import gleeunit/should
import prequel/internals/string_extra

pub fn split_at_test() {
  "hello"
  |> string_extra.split_at(0)
  |> should.equal(#("h", "ello"))

  "hello"
  |> string_extra.split_at(1)
  |> should.equal(#("he", "llo"))

  "hello"
  |> string_extra.split_at(2)
  |> should.equal(#("hel", "lo"))

  "hello"
  |> string_extra.split_at(3)
  |> should.equal(#("hell", "o"))

  "hello"
  |> string_extra.split_at(4)
  |> should.equal(#("hello", ""))

  "hello"
  |> string_extra.split_at(5)
  |> should.equal(#("hello", ""))
}

pub fn chunks_of_test() {
  "hello, how are you?"
  |> string_extra.chunks_of(max_size: 10)
  |> should.equal(["hello, how", "are you?"])

  "hello, how are you?"
  |> string_extra.chunks_of(max_size: 3)
  |> should.equal(["hello,", "how", "are", "you?"])

  "superlongword"
  |> string_extra.chunks_of(max_size: 3)
  |> should.equal(["superlongword"])

  "a pretty long text  with some spaces\nAnd newlines   as well!"
  |> string_extra.chunks_of(1000)
  |> should.equal([
    "a pretty long text  with some spaces\nAnd newlines   as well!",
  ])
}
