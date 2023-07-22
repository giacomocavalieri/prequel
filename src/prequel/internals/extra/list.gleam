import gleam/list

pub fn map_pair(over list: List(#(a, b)), with fun: fn(a, b) -> c) -> List(c) {
  list.map(list, fn(pair) { fun(pair.0, pair.1) })
}
