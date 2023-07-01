import gleam/list
import gleam/string
import gleam/string_builder.{StringBuilder}
import prequel/span.{Span}

/// A token of the Prequel language.
/// 
pub type Token {
  OpenBracket
  CloseBracket
  OpenParens
  CloseParens
  Colon
  CircleLollipop
  StarLollipop
  ArrowLollipop
  Minus
  Ampersand
  ModuleComment(content: String)
  TopLevelComment(content: String)
  SimpleComment(content: String)
  Number(value: String)
  Word(value: String)
}

/// Given a source code string scans it in a list of pairs composed of a
/// token and its span in the source code.
/// 
pub fn scan(source: String) -> List(#(Token, Span)) {
  do_scan(source, 1, 1, [])
}

/// A tail recursive version of scan that scans the source code in a list of
/// tokens and their respective span.
/// It has as additional state the current line and column inside the source
/// code and an accumulator with the tokens scanned so far.
/// 
fn do_scan(
  source: String,
  line: Int,
  column: Int,
  acc: List(#(Token, Span)),
) -> List(#(Token, Span)) {
  case source {
    "" -> list.reverse(acc)
    "\n" <> rest -> do_scan(rest, line + 1, 1, acc)
    " " <> rest | "\t" <> rest | "\r" <> rest ->
      do_scan(rest, line, column + 1, acc)
    "{" <> rest -> {
      let lexeme = #(OpenBracket, span.point(line, column))
      do_scan(rest, line, column + 1, [lexeme, ..acc])
    }
    "}" <> rest -> {
      let lexeme = #(CloseBracket, span.point(line, column))
      do_scan(rest, line, column + 1, [lexeme, ..acc])
    }
    "(" <> rest -> {
      let lexeme = #(OpenParens, span.point(line, column))
      do_scan(rest, line, column + 1, [lexeme, ..acc])
    }
    ")" <> rest -> {
      let lexeme = #(CloseParens, span.point(line, column))
      do_scan(rest, line, column + 1, [lexeme, ..acc])
    }
    ":" <> rest -> {
      let lexeme = #(Colon, span.point(line, column))
      do_scan(rest, line, column + 1, [lexeme, ..acc])
    }
    "-o" <> rest -> {
      let lexeme = #(CircleLollipop, span.segment(line, column, column + 1))
      do_scan(rest, line, column + 2, [lexeme, ..acc])
    }
    "-*" <> rest -> {
      let lexeme = #(StarLollipop, span.segment(line, column, column + 1))
      do_scan(rest, line, column + 2, [lexeme, ..acc])
    }
    "->" <> rest -> {
      let lexeme = #(ArrowLollipop, span.segment(line, column, column + 1))
      do_scan(rest, line, column + 2, [lexeme, ..acc])
    }
    "-" <> rest -> {
      let lexeme = #(Minus, span.point(line, column))
      do_scan(rest, line, column + 1, [lexeme, ..acc])
    }
    "&" <> rest -> {
      let lexeme = #(Ampersand, span.point(line, column))
      do_scan(rest, line, column + 1, [lexeme, ..acc])
    }
    "////" <> rest -> {
      let #(comment_body, size, rest) =
        scan_comment_body(string_builder.new(), 0, rest)
      let span = span.segment(line, column, column + size + 3)
      let lexeme = #(ModuleComment(comment_body), span)
      do_scan(rest, line + 1, 1, [lexeme, ..acc])
    }
    "///" <> rest -> {
      let #(comment_body, size, rest) =
        scan_comment_body(string_builder.new(), 0, rest)
      let span = span.segment(line, column, column + size + 2)
      let lexeme = #(TopLevelComment(comment_body), span)
      do_scan(rest, line + 1, 1, [lexeme, ..acc])
    }
    "//" <> rest -> {
      let #(comment_body, size, rest) =
        scan_comment_body(string_builder.new(), 0, rest)
      let span = span.segment(line, column, column + size + 1)
      let lexeme = #(SimpleComment(comment_body), span)
      do_scan(rest, line + 1, 1, [lexeme, ..acc])
    }
    "0" <> _
    | "1" <> _
    | "2" <> _
    | "3" <> _
    | "4" <> _
    | "5" <> _
    | "6" <> _
    | "7" <> _
    | "8" <> _
    | "9" <> _ -> {
      let #(number, size, rest) = scan_number(string_builder.new(), 0, source)
      let span = span.segment(line, column, column + size - 1)
      let lexeme = #(Number(number), span)
      do_scan(rest, line, column + size, [lexeme, ..acc])
    }
    rest -> {
      let #(word, size, rest) = scan_word(string_builder.new(), 0, rest)
      let lexeme = #(Word(word), span.segment(line, column, column + size - 1))
      do_scan(rest, line, column + size, [lexeme, ..acc])
    }
  }
}

/// A tail recursive function that scans the body of a comment stopping at the
/// first newline it finds. It has as additional state a string builder with
/// the body of the comment scanned so far and its size (in terms of number
/// of graphemes it's made of).
/// 
/// It returns the scanned comment body, its size and the remaining unscanned
/// source code.
/// 
fn scan_comment_body(
  acc: StringBuilder,
  size: Int,
  source: String,
) -> #(String, Int, String) {
  case source {
    "\r\n" <> rest | "\n" <> rest -> #(
      string_builder.to_string(acc),
      size,
      rest,
    )
    rest ->
      case string.pop_grapheme(rest) {
        Error(Nil) -> #(string_builder.to_string(acc), size, rest)
        Ok(#(grapheme, rest)) ->
          scan_comment_body(
            string_builder.append(acc, grapheme),
            size + 1,
            rest,
          )
      }
  }
}

/// A tail recursive function that scans a number.
/// It has as additional state a string builder with the number scanned so far
/// and the its size (in terms if number of digits).
/// 
/// It returns the scanned number, its size and the remaining unscanned source
/// code.
/// 
fn scan_number(
  acc: StringBuilder,
  size: Int,
  content: String,
) -> #(String, Int, String) {
  case content {
    "0" <> rest -> scan_number(string_builder.append(acc, "0"), size + 1, rest)
    "1" <> rest -> scan_number(string_builder.append(acc, "1"), size + 1, rest)
    "2" <> rest -> scan_number(string_builder.append(acc, "2"), size + 1, rest)
    "3" <> rest -> scan_number(string_builder.append(acc, "3"), size + 1, rest)
    "4" <> rest -> scan_number(string_builder.append(acc, "4"), size + 1, rest)
    "5" <> rest -> scan_number(string_builder.append(acc, "5"), size + 1, rest)
    "6" <> rest -> scan_number(string_builder.append(acc, "6"), size + 1, rest)
    "7" <> rest -> scan_number(string_builder.append(acc, "7"), size + 1, rest)
    "8" <> rest -> scan_number(string_builder.append(acc, "8"), size + 1, rest)
    "9" <> rest -> scan_number(string_builder.append(acc, "9"), size + 1, rest)
    rest -> #(string_builder.to_string(acc), size, rest)
  }
}

/// A tail recursive function that scans a word (any sequence of graphemes with
/// an exception for parentheses, colons, whitespaces and comments).
/// It has as additional state a string builder with the word scanned so far
/// and the its size (in terms if number of digits).
/// 
/// It returns the scanned word, its size and the remaining unscanned source code.
/// 
fn scan_word(
  acc: StringBuilder,
  size: Int,
  source: String,
) -> #(String, Int, String) {
  case source {
    "//" <> _
    | "///" <> _
    | "////" <> _
    | ":" <> _
    | "(" <> _
    | ")" <> _
    | "{" <> _
    | "}" <> _
    | " " <> _
    | "\n" <> _
    | "\r" <> _
    | "\t" <> _ -> #(string_builder.to_string(acc), size, source)
    rest ->
      case string.pop_grapheme(rest) {
        Error(Nil) -> #(string_builder.to_string(acc), size, rest)
        Ok(#(grapheme, rest)) ->
          scan_word(string_builder.append(acc, grapheme), size + 1, rest)
      }
  }
}
