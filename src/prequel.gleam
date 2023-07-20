import prequel/internals/token
import prequel/parse_error.{ParseError}
import prequel/ast.{Module}
import prequel/internals/parser

/// Parses a string into a `Module`.
/// 
pub fn parse(source: String) -> Result(Module, ParseError) {
  case parser.parse(token.scan(source), [], []) {
    Ok(#(#(entities, relationships), _)) -> Ok(Module(entities, relationships))
    Error(error) -> Error(error)
  }
}
