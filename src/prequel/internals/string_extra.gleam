import gleam/list
import gleam/pair
import gleam/string

/// Splits a string into a list of strings each one with length at most equal to
/// `max_size`, the splitting is performed on whitespace.
/// 
/// Pay attention that the `max_size` is not guaranteed if there is a word
/// longer than `max_size` since the splitting is performed on whitespace!
/// 
/// ## Examples
/// 
/// ```gleam
/// > chunks_of("hello, world! How are we feeling?", 10)
/// ["hello,", "world! How", "are we", "feeling?"]
/// ```
/// 
/// ```gleam
/// > chunks_of("hello, world", 3)
/// ["hello,", "world"]
/// ```
/// 
pub fn chunks_of(string: String, max_size max_size: Int) -> List(String) {
  // ⚠️ Possible pain point: this is just bad to read and probably super
  // inefficient but I couldn't come up with anything better, so until I have
  // problems with it and since it's not that crucial I'll leave it like this
  // and postpone any refactoring.
  string.split(string, on: " ")
  |> list.fold(
    from: #(0, [[]]),
    with: fn(acc, word) {
      let assert #(current_chunk_size, [current_chunk, ..rest] as chunks) = acc
      let word_size = string.length(word)
      case word_size + current_chunk_size + 1 > max_size {
        True -> #(word_size, [[word], ..chunks])
        False -> #(
          current_chunk_size + word_size,
          [[word, ..current_chunk], ..rest],
        )
      }
    },
  )
  |> pair.second
  |> list.map(list.reverse)
  |> list.map(string.join(_, " "))
  |> list.reverse
  |> list.filter(fn(string) { !string.is_empty(string) })
}

/// Splits a string at a given index.
/// 
/// ## Examples
/// 
/// ```gleam
/// > "hello" |> split_at(0)
/// #("h", "ello")
/// ```
/// 
/// ```gleam
/// > "hello" |> split_at(3)
/// #("hell", "o")
/// ```
/// 
/// ```gleam
/// > "hello" |> split_at(30)
/// #("hello", "")
/// ```
/// 
pub fn split_at(string: String, at index: Int) -> #(String, String) {
  let length = string.length(string)
  let first = string.slice(string, at_index: 0, length: index + 1)
  let second = string.slice(string, at_index: index + 1, length: length)
  #(first, second)
}

/// Highlights a string from a starting column (1-based) to an ending column
/// (1-based).
/// 
pub fn highlight_from_to(
  string: String,
  from: Int,
  to: Int,
  in colour: fn(String) -> String,
) -> String {
  let #(first, rest) = split_at(string, at: from - 2)
  let #(second, third) = split_at(rest, at: to - from)
  first <> colour(second) <> third
}

/// Highlights a string from a starting column (1-based) up to its end.
/// 
pub fn highlight_from(
  string: String,
  from: Int,
  in colour: fn(String) -> String,
) -> String {
  highlight_from_to(string, from, string.length(string), colour)
}

/// Highlights a string from its start up to an ending column (1-based).
/// 
pub fn highlight_up_to(
  string: String,
  up_to: Int,
  in colour: fn(String) -> String,
) -> String {
  highlight_from_to(string, 1, up_to, colour)
}
