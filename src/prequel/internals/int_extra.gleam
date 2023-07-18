import gleam/int
import gleam/list

/// Return the number of digits of the given number.
/// 
/// ## Examples
/// 
/// ```gleam
/// > count_digits(9)
/// 1
/// ```
/// 
/// ```gleam
/// > count_digits(99)
/// 2
/// ```
/// 
pub fn count_digits(n: Int) -> Int {
  let assert Ok(digits) = int.digits(n, 10)
  list.length(digits)
}

/// Returns true if the first number comes immediately before or after the
/// other.
/// 
/// ## Examples
/// 
/// ```gleam
/// > 1 |> is_next_to(2)
/// True
/// ```
/// 
/// ```gleam
/// > 1 |> is_next_to(11)
/// False
/// ```
/// 
pub fn is_next_to(n: Int, m: Int) -> Bool {
  n + 1 == m || n - 1 == m
}
