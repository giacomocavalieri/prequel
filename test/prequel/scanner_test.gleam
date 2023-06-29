import gleeunit/should
import prequel/span.{Span}
import gleam/string
///
///pub fn scan_single_token_test(literal, expected) {
///  let assert [#(token, span)] = scanner.scan(literal)
///  token
///  |> should.equal(expected)
///
///  span
///  |> should.equal(Span(1, 1, 1, string.length(literal)))
///}
///
///pub fn simple_tokens_test() {
///  scan_single_token_test("{", scanner.OpenBracket)
///  scan_single_token_test("}", scanner.CloseBracket)
///  scan_single_token_test("(", scanner.OpenParens)
///  scan_single_token_test(")", scanner.CloseParens)
///  scan_single_token_test(":", scanner.Colon)
///  scan_single_token_test("-o", scanner.CircleLollipop)
///  scan_single_token_test("-*", scanner.StarLollipop)
///  scan_single_token_test("->", scanner.ArrowLollipop)
///  scan_single_token_test("-", scanner.Minus)
///  scan_single_token_test("-", scanner.Minus)
///}
///
///pub fn number_tokens_test() {
///  scan_single_token_test("0", scanner.Number("0"))
///  scan_single_token_test("1", scanner.Number("1"))
///  scan_single_token_test("1234567890", scanner.Number("1234567890"))
///}
///
///pub fn word_tokens_test() {
///  scan_single_token_test("hierarchy", scanner.Word("hierarchy"))
///  scan_single_token_test("total", scanner.Word("total"))
///  scan_single_token_test("disjoint", scanner.Word("disjoint"))
///  scan_single_token_test("entity", scanner.Word("entity"))
///  scan_single_token_test("relationship", scanner.Word("relationship"))
///  scan_single_token_test("snake_case", scanner.Word("snake_case"))
///  scan_single_token_test("camelCase", scanner.Word("camelCase"))
///  scan_single_token_test("kebab-case", scanner.Word("kebab-case"))
///  scan_single_token_test("SHOUTING", scanner.Word("SHOUTING"))
///  scan_single_token_test("entity1", scanner.Word("entity1"))
///  scan_single_token_test("name-o", scanner.Word("name-o"))
///  scan_single_token_test("name-*", scanner.Word("name-*"))
///  scan_single_token_test("😀", scanner.Word("😀"))
///}
///
///pub fn comment_tokens_test() {
///  scan_single_token_test("//// foo", scanner.ModuleComment(" foo"))
///  scan_single_token_test("/// foo", scanner.TopLevelComment(" foo"))
///  scan_single_token_test("// foo", scanner.SimpleComment(" foo"))
///}
///
///pub fn multiline_tokens_test() {
///  "entity  foo {
///  -* bar : (1-1)
///  -o baz
///  total disjoint hierarchy {
///    entity baz
///    entity bar
///  }
///}
///"
///  |> scanner.scan
///  |> should.equal([
///    #(scanner.Word("entity"), span.segment(1, 1, 6)),
///    #(scanner.Word("foo"), span.segment(1, 9, 11)),
///    #(scanner.OpenBracket, span.point(1, 13)),
///    #(scanner.StarLollipop, span.segment(2, 3, 4)),
///    #(scanner.Word("bar"), span.segment(2, 6, 8)),
///    #(scanner.Colon, span.point(2, 10)),
///    #(scanner.OpenParens, span.point(2, 12)),
///    #(scanner.Number("1"), span.point(2, 13)),
///    #(scanner.Minus, span.point(2, 14)),
///    #(scanner.Number("1"), span.point(2, 15)),
///    #(scanner.CloseParens, span.point(2, 16)),
///    #(scanner.CircleLollipop, span.segment(3, 3, 4)),
///    #(scanner.Word("baz"), span.segment(3, 6, 8)),
///    #(scanner.Word("total"), span.segment(4, 3, 7)),
///    #(scanner.Word("disjoint"), span.segment(4, 9, 16)),
///    #(scanner.Word("hierarchy"), span.segment(4, 18, 26)),
///    #(scanner.OpenBracket, span.point(4, 28)),
///    #(scanner.Word("entity"), span.segment(5, 5, 10)),
///    #(scanner.Word("baz"), span.segment(5, 12, 14)),
///    #(scanner.Word("entity"), span.segment(6, 5, 10)),
///    #(scanner.Word("bar"), span.segment(6, 12, 14)),
///    #(scanner.CloseBracket, span.point(7, 3)),
///    #(scanner.CloseBracket, span.point(8, 1)),
///  ])
///}
///
