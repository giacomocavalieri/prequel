import gleam/list
import gleam/map
import non_empty_list.{NonEmptyList}

/// Maps a function that takes two values as input over a list of pairs.
/// The function is called with the elements of the pair as arguments.
/// 
/// ## Examples
/// 
/// ```gleam
/// [#(2, 1), #(3, 2), #(5, 4)]
/// |> list.map_pairs(fn(x, y) { x - y })
/// [1, 1, 1]
/// ```
/// 
pub fn map_pairs(over list: List(#(a, b)), with fun: fn(a, b) -> c) -> List(c) {
  list.map(list, fn(pair) { fun(pair.0, pair.1) })
}

/// Finds all the duplicates element in a given list according to a grouping
/// function.
/// If there are two or more elements that are mapped by the given function to
/// the same value, they will be in the resulting list.
/// 
/// ## Examples
/// 
/// ```gleam
/// [1, 2, 3, 4, 1, 1, 2, 5]
/// |> duplicates(by: fn(x) { x })
/// [#(1, [1, 1]), #(2, [2])]
/// ```
/// 
pub fn duplicates(
  in list: List(a),
  by fun: fn(a) -> b,
) -> List(#(a, NonEmptyList(a))) {
  list.group(list, fun)
  |> map.values
  |> list.filter_map(fn(entities) {
    // The list gets reversed to keep the same order in which the elements are
    // met in the original list since the stdlib's implementation returns them
    // in reverse order.
    case list.reverse(entities) {
      [one, two, ..more] -> Ok(#(one, non_empty_list.new(two, more)))
      _ -> Error(Nil)
    }
  })
}
