import gleam/list
import gleam/pair
import gleeunit/should
import prequel/span.{Span}
import prequel/internals/token.{Token}

fn example_single_tokens() {
  [
    #("{", #(token.OpenBracket, span.point(1, 1))),
    #("}", #(token.CloseBracket, span.point(1, 1))),
    #("(", #(token.OpenParens, span.point(1, 1))),
    #(")", #(token.CloseParens, span.point(1, 1))),
    #(":", #(token.Colon, span.point(1, 1))),
    #("-o", #(token.CircleLollipop, span.segment(1, 1, 2))),
    #("-*", #(token.StarLollipop, span.segment(1, 1, 2))),
    #("->", #(token.ArrowLollipop, span.segment(1, 1, 2))),
    #("-", #(token.Minus, span.point(1, 1))),
    #("&", #(token.Ampersand, span.point(1, 1))),
    #("// baz", #(token.SimpleComment(" baz"), span.segment(1, 1, 6))),
    #("//baz", #(token.SimpleComment("baz"), span.segment(1, 1, 5))),
    #("123", #(token.Number("123"), span.segment(1, 1, 3))),
    #("0", #(token.Number("0"), span.point(1, 1))),
    #("hello", #(token.Word("hello"), span.segment(1, 1, 5))),
    #("entity", #(token.Word("entity"), span.segment(1, 1, 6))),
    #("relationship", #(token.Word("relationship"), span.segment(1, 1, 12))),
    #("total", #(token.Word("total"), span.segment(1, 1, 5))),
    #("disjoint", #(token.Word("disjoint"), span.segment(1, 1, 8))),
    #("partial", #(token.Word("partial"), span.segment(1, 1, 7))),
    #("overlapping", #(token.Word("overlapping"), span.segment(1, 1, 11))),
    #("kebab-case", #(token.Word("kebab-case"), span.segment(1, 1, 10))),
    #("camelCase", #(token.Word("camelCase"), span.segment(1, 1, 9))),
    #("PascalCase", #(token.Word("PascalCase"), span.segment(1, 1, 10))),
    #("snake_case", #(token.Word("snake_case"), span.segment(1, 1, 10))),
    #("SHOUTING", #(token.Word("SHOUTING"), span.segment(1, 1, 8))),
    #("実体", #(token.Word("実体"), span.segment(1, 1, 2))),
    #("関連", #(token.Word("関連"), span.segment(1, 1, 2))),
    #("💜💖💓", #(token.Word("💜💖💓"), span.segment(1, 1, 3))),
  ]
}

// Returns the first scanned token
fn scan_single_token(source: String) -> #(Token, Span) {
  let assert [result, ..] = token.scan(source)
  result
}

pub fn to_string_inverse_of_scan_test() -> Nil {
  // TODO: this would be so nice with a property-based testing library
  example_single_tokens()
  |> list.map(pair.first)
  |> list.each(check_to_string_inverse_of_scan)
}

fn check_to_string_inverse_of_scan(source: String) -> Nil {
  scan_single_token(source)
  |> pair.first
  |> token.to_string
  |> should.equal(source)
}

pub fn scan_single_token_test() -> Nil {
  // TODO: this would be so nice with a property-based testing library
  use #(source, #(token, span)) <- list.each(example_single_tokens())
  check_scan_returns_expected_token_and_span(source, token, span)
}

fn check_scan_returns_expected_token_and_span(
  source: String,
  expected_token: Token,
  expected_scan: Span,
) -> Nil {
  scan_single_token(source)
  |> should.equal(#(expected_token, expected_scan))
}

pub fn scan_ignores_whitespace_test() -> Nil {
  token.scan("foo\n-o   baz\n\r\n123")
  |> should.equal([
    #(token.Word("foo"), span.segment(1, 1, 3)),
    #(token.CircleLollipop, span.segment(2, 1, 2)),
    #(token.Word("baz"), span.segment(2, 6, 8)),
    #(token.Number("123"), span.segment(4, 1, 3)),
  ])
}

pub fn comments_end_on_newline_test() -> Nil {
  token.scan("// comment\r\nentity")
  |> should.equal([
    #(token.SimpleComment(" comment"), span.segment(1, 1, 10)),
    #(token.Word("entity"), span.segment(2, 1, 6)),
  ])

  token.scan("// comment\nentity")
  |> should.equal([
    #(token.SimpleComment(" comment"), span.segment(1, 1, 10)),
    #(token.Word("entity"), span.segment(2, 1, 6)),
  ])
}
