import gleam/list
import gleam/pair
import gleam/string

pub fn chunks_of(string: String, max_size max_size: Int) -> List(String) {
  string.split(string, on: " ")
  |> list.fold(
    from: #(0, [[]]),
    with: fn(acc, word) {
      let assert #(current_chunk_size, [current_chunk, ..rest] as chunks) = acc
      let word = word <> " "
      let word_size = string.length(word)
      case word_size + current_chunk_size > max_size {
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
  |> list.map(string.join(_, ""))
  |> list.reverse
}

pub fn split_at(string: String, at index: Int) -> #(String, String) {
  let length = string.length(string)
  let first = string.slice(string, at_index: 0, length: index + 1)
  let second = string.slice(string, at_index: index + 1, length: length)
  #(first, second)
}

/// Highlights a string from a starting column (1-based) to an ending column
/// (1-based)
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

/// Highlights a string from its start up to an ending column (1-based)
/// 
pub fn highlight_up_to(
  string: String,
  up_to: Int,
  in colour: fn(String) -> String,
) -> String {
  highlight_from_to(string, 1, up_to, colour)
}
