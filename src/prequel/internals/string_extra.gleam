import gleam/list
import gleam/string
import gleam/pair

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
