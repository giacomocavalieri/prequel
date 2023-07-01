import gleam/list
import gleam/option.{None, Option, Some}
import gleam/string
import gleam/string_builder.{StringBuilder}
import prequel/span.{Span}
import non_empty_list.{NonEmptyList}
import gleam/result
import gleam/pair
import gleam/int
import gleam/io

/// A token of the Prequel language.
/// 
type Token {
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
fn scan(source: String) -> List(#(Token, Span)) {
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

/// A module is the result obtained by parsing a file, it contains a list of
/// entities and relationships.
/// 
pub type Module {
  Module(entities: List(Entity), relationships: List(Relationship))
}

/// TODO: Cambiare in modo che abbia per costruzione sempre almeno due entità!!!
/// A relationship as described by the ER model. It involves some entities
/// and can also have attributes.
/// 
pub type Relationship {
  Relationship(
    span: Span,
    name: String,
    // TODO: Make this a nonempty list
    entities: List(RelationshipEntity),
    attributes: List(Attribute),
  )
}

/// An entity that takes part in a relationship with a given cardinality.
/// 
pub type RelationshipEntity {
  RelationshipEntity(span: Span, name: String, cardinality: Cardinality)
}

/// An entity as described by the ER model. It has a name, it can have 
/// zero or more attributes that can also act as keys.
/// The first key is always considered to be the primary key.
/// An entity can also be the root of a hierarchy of sub-entities.
/// 
pub type Entity {
  Entity(
    span: Span,
    name: String,
    keys: List(Key),
    attributes: List(Attribute),
    inner_relationships: List(Relationship),
    children: Option(Hierarchy),
  )
}

/// An attribute that can be part of an entity or a relationship.
/// It has a name, a cardinality and a type. 
/// 
pub type Attribute {
  Attribute(span: Span, name: String, cardinality: Cardinality, type_: Type)
}

/// The cardinality of an attribute or of an entity in a relationship.
/// 
pub type Cardinality {
  /// A cardinality where both upper and lower bound are numbers,
  /// for example `(0-1)`, `(1-1)` are both bounded.
  /// 
  Unbounded(minimum: Int)

  /// A cardinality where the upper bound is the letter `N`,
  /// for example `(1-N)`, `(0-N)` are both unbounded.
  Bounded(minimum: Int, maximum: Int)
}

/// The type of an attribute.
/// 
pub type Type {
  NoType
  ComposedAttribute(span: Span, attributes: List(Attribute))
}

/// The key of an entity, its composed of at least the name of one of the
/// attributes (or one of the relationships that can be used as external keys).
/// 
pub type Key {
  Key(span: Span, attributes: NonEmptyList(String))
}

/// A hierarchy of entities, it specifies wether it is overlapping or disjoint
/// and wether it is total or partial.
/// 
pub type Hierarchy {
  Hierarchy(
    span: Span,
    overlapping: Overlapping,
    totality: Totality,
    children: NonEmptyList(Entity),
  )
}

/// The totality of a hierarchy: it can either be `Total` or `Partial`.
/// 
pub type Totality {
  Total
  Partial
}

/// The overlapping of a hierarchy: it can either be `Overlapped` or `Disjoint`.
/// 
pub type Overlapping {
  Overlapped
  Disjoint
}

fn totality_from_string(string: String) -> Result(Totality, Nil) {
  case string {
    "total" -> Ok(Total)
    "partial" -> Ok(Partial)
    _ -> Error(Nil)
  }
}

fn overlapping_from_string(string: String) -> Result(Overlapping, Nil) {
  case string {
    "overlapped" -> Ok(Overlapped)
    "disjoint" -> Ok(Disjoint)
    _ -> Error(Nil)
  }
}

/// TODO!!!
pub fn parse(source: String) -> Result(Module, Nil) {
  use #(entities, relationships) <- result.map(do_parse(scan(source), [], []))
  Module(entities, relationships)
}

/// Tail recursive (hopefully, I should check it TODO) parser.
/// 
fn do_parse(
  tokens: List(#(Token, Span)),
  entities: List(Entity),
  relationships: List(Relationship),
) -> Result(#(List(Entity), List(Relationship)), Nil) {
  case tokens {
    [] -> Ok(#(list.reverse(entities), list.reverse(relationships)))
    [#(Word("entity"), _), ..tokens] -> {
      use #(entity, tokens) <- result.try(parse_entity(tokens))
      do_parse(tokens, [entity, ..entities], relationships)
    }
    [#(Word("relationship"), _), ..tokens] -> {
      use #(relationship, tokens) <- result.try(parse_relationship(tokens))
      do_parse(tokens, entities, [relationship, ..relationships])
    }
    [#(token, span), ..] -> todo("nice error")
  }
}

/// An intermediate result of the parsing process, if the parsing step succeeds it holds
/// a pair with the remaining tokens and a result of type `a`.
/// 
type ParseResult(a) =
  Result(#(a, List(#(Token, Span))), Nil)

/// Parse an entity once the 'entity' word was found.
/// 
fn parse_entity(tokens: List(#(Token, Span))) -> ParseResult(Entity) {
  case tokens {
    // If there is an open bracket '{', parses the body of the entity.
    [#(Word(name), name_span), #(OpenBracket, _), ..tokens] ->
      parse_entity_body(tokens, name, name_span, [], [], [], None)

    // Parses an entity with an empty body.
    [#(Word(name), name_span), ..tokens] ->
      Entity(name_span, name, [], [], [], None)
      |> pair.new(tokens)
      |> Ok

    [#(OpenBracket, _), ..] -> todo("error about missing name")
    [#(token, span), ..] -> todo("error about wrong name")
    [] -> todo("unexpected EOF")
  }
}

/// In the context of entity parsing, parses the body of an entity expecting a
/// closed bracked '}' at the end of it.
/// Returns the parsed entity.
/// 
fn parse_entity_body(
  tokens: List(#(Token, Span)),
  name: String,
  name_span: Span,
  keys: List(Key),
  attributes: List(Attribute),
  inner_relationships: List(Relationship),
  children: Option(Hierarchy),
) -> ParseResult(Entity) {
  case tokens {
    // When a close bracket '}' is found the entity parsing is done.
    // Returns the entity built from the function accumulators along with the
    // remaining tokens in the input.
    [#(CloseBracket, _), ..tokens] ->
      Entity(
        name_span,
        name,
        list.reverse(keys),
        list.reverse(attributes),
        list.reverse(inner_relationships),
        children,
      )
      |> pair.new(tokens)
      |> Ok

    // Parse any of the elements that can be found inside an entity body.
    [#(CircleLollipop, _), ..tokens] -> {
      use #(attribute, tokens) <- result.try(parse_attribute(tokens))
      parse_entity_body(
        tokens,
        name,
        name_span,
        keys,
        [attribute, ..attributes],
        inner_relationships,
        children,
      )
    }
    [#(StarLollipop, _), ..tokens] -> {
      use #(#(key, attribute), tokens) <- result.try(parse_key(tokens, []))
      case attribute {
        None ->
          parse_entity_body(
            tokens,
            name,
            name_span,
            [key, ..keys],
            attributes,
            inner_relationships,
            children,
          )
        Some(attribute) ->
          parse_entity_body(
            tokens,
            name,
            name_span,
            [key, ..keys],
            [attribute, ..attributes],
            inner_relationships,
            children,
          )
      }
    }
    [#(ArrowLollipop, _), ..tokens] -> {
      let result = parse_inner_relationship(tokens, name, name_span)
      use #(relationship, tokens) <- result.try(result)
      parse_entity_body(
        tokens,
        name,
        name_span,
        keys,
        attributes,
        [relationship, ..inner_relationships],
        children,
      )
    }
    [#(Word("total" as word), span), ..tokens]
    | [#(Word("partial" as word), span), ..tokens] -> {
      case children {
        Some(_) -> todo("error about duplicate hierarchy")
        None -> {
          use totality <- result.try(totality_from_string(word))
          //|> result.replace_error(todo("internal error should never happen")),
          let result = parse_hierarchy(tokens, span, totality)
          use #(children, tokens) <- result.try(result)
          parse_entity_body(
            tokens,
            name,
            name_span,
            keys,
            attributes,
            inner_relationships,
            Some(children),
          )
        }
      }
    }

    // Catch some common mistakes to provide better error messages: in case one writes
    // the lollipops with a space between the minus and its head it is reported as an
    // error with a suggestion to fix the mistake.
    [#(Minus, _), #(Word("o"), _), ..] -> todo("error message about typo")
    [#(Minus, _), #(Word("*"), _), ..] -> todo("error message about typo")
    [#(Minus, _), #(Word(">"), _), ..] -> todo("error message about typo")

    // Catch some common mistakes to provide better error messages: in case one writes
    // the hierarchy modifiers in the wrong order that is detected and reported as an
    // error with a suggestion to fix the mistake.
    [#(Word("overlapped"), span), ..] -> todo("error message about wrong order")
    [#(Word("overlapping"), span), ..] ->
      todo("error message about wrong order")
    [#(Word("disjoint"), span), ..] -> todo("error message about wrong order")

    [#(Word("hierarchy"), span), ..] -> todo("hierarchy should be qualified")

    [#(token, _), ..] -> todo("unexpected token")
    [] -> todo("unexpected EOF")
  }
}

/// Parses an attribute once the '-o' lollipop was found.
/// 
fn parse_attribute(tokens: List(#(Token, Span))) -> ParseResult(Attribute) {
  case tokens {
    // Parse an attribute that has a name and a type/cardinality annotation.
    [#(Word(name), name_span), #(Colon, _), ..tokens] -> {
      use #(type_, tokens) <- result.try(parse_attribute_type(tokens))
      let should_be_lenient = type_ != NoType
      let result = parse_cardinality(tokens, should_be_lenient)
      use #(cardinality, tokens) <- result.map(result)
      #(Attribute(name_span, name, cardinality, type_), tokens)
    }

    // Parse an attribute that has no type/cardinality annotation.
    [#(Word(name), name_span), ..tokens] ->
      Attribute(name_span, name, Bounded(1, 1), NoType)
      |> pair.new(tokens)
      |> Ok

    [#(token, span), ..] -> todo("unexpected token")
    [] -> todo("unexpected EOF")
  }
}

fn parse_attribute_type(tokens: List(#(Token, Span))) -> ParseResult(Type) {
  // TODO: actually parse a type! But I have to think long and hard about
  //       types before adding them.
  Ok(#(NoType, tokens))
}

/// Parses a cardinality. If `lenient` is true it can recover with a default cardinality
/// of (1-1). However, recovery is not guaranteed, for example in some cases there could
/// still be an error to provide better error messages; consider this example:
/// 
/// ```
/// -o attr : (1-
/// ```
/// 
/// The programmer here may have wanted to specify a cardinality, if the parsing failed
/// and recovered with a default cardinality of (1-1) then the error would be on
/// the incomplete '(1-' when the parser tries to parse the following attribute giving a
/// puzzling error along the lines of "I was expecting an attribute/key/...".
/// 
/// By not recovering we can provide a more insightful error about an _incomplete_
/// cardinality that is maybe missing a piece.
/// That is why, as soon as this function finds a '(' it becomes impossible to recover,
/// even if lenient is set to `True`.
/// 
fn parse_cardinality(
  tokens: List(#(Token, Span)),
  lenient: Bool,
) -> ParseResult(Cardinality) {
  case tokens {
    // Parse a bounded cardinality.
    [
      #(OpenParens, _),
      #(Number(raw_lower), _),
      #(Minus, _),
      #(Number(raw_upper), _),
      #(CloseParens, _),
      ..tokens
    ] -> {
      // An error here should never occur! Wrap it in a bug report error!
      use lower <- result.try(int.parse(raw_lower))
      use upper <- result.map(int.parse(raw_upper))
      #(Bounded(lower, upper), tokens)
    }

    // Parse an unbounded cardinality.
    [
      #(OpenParens, _),
      #(Number(raw_lower), _),
      #(Minus, _),
      #(Word("N"), _),
      #(CloseParens, _),
      ..tokens
    ] -> {
      use lower <- result.map(int.parse(raw_lower))
      #(Unbounded(lower), tokens)
    }

    // Catch some common mistakes to provide better error messages: in case one writes
    // the unbounded part of the cardinality with a letter different from N that is
    // detected and reported as an error to fix the mistake.
    [
      #(OpenParens, _),
      #(Number(raw_lower), _),
      #(Minus, _),
      #(Word(other), _),
      #(CloseParens, _),
      ..
    ] -> todo("wrong letter in unbounded cardinality")

    // TODO: document these choices
    [#(OpenParens, _), #(Number(_), _), #(Minus, _), #(Number(_), _), ..]
    | [#(OpenParens, _), #(Number(_), _), #(Minus, _), #(Word(_), _), ..] ->
      todo("there should be a closed parens here")
    [#(OpenParens, _), #(Number(_), _), #(Minus, _), ..] ->
      todo("there should be a number or an N here")
    [#(OpenParens, _), #(Number(_), _), ..] ->
      todo("there should be a minus here")
    [#(OpenParens, _), ..] -> todo("there should be a number here")

    [#(Number(n), _), ..] -> todo("probably missing open parens before number")

    [_, ..] if lenient -> Ok(#(Bounded(1, 1), tokens))
    [#(token, span), ..] -> todo("unexpected token")
    [] -> todo("unexpected EOF")
  }
}

fn parse_key(
  tokens: List(#(Token, Span)),
  keys: List(String),
) -> ParseResult(#(Key, Option(Attribute))) {
  case tokens {
    [#(Word(key), span), #(Ampersand, _), ..tokens] -> {
      let result = parse_multi_attribute_key(tokens, span, [key, ..keys])
      use #(key, tokens) <- result.map(result)
      #(#(key, None), tokens)
    }

    [#(Word(key), span), #(Colon, _), ..tokens] -> {
      use #(type_, tokens) <- result.map(parse_attribute_type(tokens))
      case type_ {
        NoType -> todo("fail there should be a type annotation there")
        _ -> {
          let attribute = Attribute(span, key, Bounded(1, 1), type_)
          let key = Key(span, non_empty_list.single(key))
          #(#(key, Some(attribute)), tokens)
        }
      }
    }

    [#(Word(key), span), ..tokens] ->
      Key(span, non_empty_list.new(key, keys))
      |> pair.new(None)
      |> pair.new(tokens)
      |> Ok

    [#(token, span), ..] -> todo("unexpected token")
    [] -> todo("unexpected EOF")
  }
}

fn parse_multi_attribute_key(
  tokens: List(#(Token, Span)),
  initial_span: Span,
  keys: List(String),
) -> ParseResult(Key) {
  case tokens {
    [#(Word(key), _), #(Ampersand, _), ..tokens] ->
      parse_multi_attribute_key(tokens, initial_span, [key, ..keys])

    [#(Word(_), _), #(Colon, _), ..] ->
      todo("error no type annotation in multi element key")

    [#(Word(key), final_span), ..tokens] ->
      initial_span
      |> span.merge(with: final_span)
      |> Key(non_empty_list.new(key, keys))
      |> pair.new(tokens)
      |> Ok

    [#(token, _), ..] -> todo("I was expecting a word here")
    [] -> todo("unexpected EOF")
  }
}

fn parse_inner_relationship(
  tokens: List(#(Token, Span)),
  entity_name: String,
  entity_span: Span,
) -> ParseResult(Relationship) {
  case tokens {
    // This function is a bit scary looking, I should refactor this not sure how
    // for now some comments will suffice :)
    //
    // First expect to find a word, the name of the relationship, and a colon...
    [#(Word(relationship_name), relationship_span), #(Colon, _), ..tokens] -> {
      // ...then there should be a cardinality...
      let result = parse_cardinality(tokens, False)
      use #(one_cardinality, tokens) <- result.try(result)

      case tokens {
        // ...followed by another name, that is the name of the second entity
        // taking part in the relationship.
        [#(Word(other_name), other_name_span), ..tokens] -> {
          // Then there should be its cardinality in the relationship.
          let result = parse_cardinality(tokens, False)
          use #(other_cardinality, tokens) <- result.try(result)

          let one_entity =
            RelationshipEntity(entity_span, entity_name, one_cardinality)
          let other_entity =
            RelationshipEntity(other_name_span, other_name, other_cardinality)
          let entities = [one_entity, other_entity]

          case tokens {
            // Finally if there's an open bracket we parse the relationship body...
            [#(OpenBracket, _), ..tokens] -> {
              let result = parse_inner_relationship_body(tokens, [])
              use #(attributes, tokens) <- result.map(result)
              relationship_span
              |> Relationship(relationship_name, entities, attributes)
              |> pair.new(tokens)
            }
            // Otherwise return a relationship with no body.
            _ ->
              relationship_span
              |> Relationship(relationship_name, entities, [])
              |> pair.new(tokens)
              |> Ok
          }
        }

        _ -> todo("expecting word")
      }
    }

    [#(Word(name), _), ..] ->
      todo("inner relationship missing cardinality annotation")

    [#(token, _), ..] -> todo("I was expecting a word here")

    [] -> todo("unexpected EOF")
  }
}

fn parse_inner_relationship_body(
  tokens: List(#(Token, Span)),
  attributes: List(Attribute),
) -> ParseResult(List(Attribute)) {
  case tokens {
    [#(CloseBracket, _), ..tokens] -> Ok(#(list.reverse(attributes), tokens))

    [#(CircleLollipop, _), ..tokens] -> {
      use #(attribute, tokens) <- result.try(parse_attribute(tokens))
      parse_inner_relationship_body(tokens, [attribute, ..attributes])
    }

    [#(StarLollipop, _), ..] -> todo("a relationship cannot have a key inside")
    [#(ArrowLollipop, _), ..] -> todo("a short rel cannot have other rels")
    [#(Minus, _), #(Word("o"), _), ..] -> todo("possible typo")

    [#(token, _), ..] -> todo("unexpected token")
    [] -> todo("unexpected EOF")
  }
}

fn parse_hierarchy(
  tokens: List(#(Token, Span)),
  initial_span: Span,
  totality: Totality,
) -> ParseResult(Hierarchy) {
  case tokens {
    [#(Word("overlapping"), _), ..tokens] -> todo("error about wrong spelling")
    [#(Word("hierarchy"), _), ..tokens] ->
      todo("error about missing overlapping")

    [
      #(Word("overlapped" as word), _),
      #(Word("hierarchy"), final_span),
      #(OpenBracket, _),
      ..tokens
    ]
    | [
      #(Word("disjoint" as word), _),
      #(Word("hierarchy"), final_span),
      #(OpenBracket, _),
      ..tokens
    ] -> {
      use overlapping <- result.try(overlapping_from_string(word))
      let result = parse_hierarchy_body(tokens, [])
      use #(entities, tokens) <- result.map(result)
      initial_span
      |> span.merge(with: final_span)
      |> Hierarchy(overlapping, totality, entities)
      |> pair.new(tokens)
    }

    [#(Word("overlapped"), _), #(OpenBracket, _), ..]
    | [#(Word("disjoint"), _), #(OpenBracket, _), ..] ->
      todo("missing hierarchy keyword error")

    [#(Word("overlapped"), _), #(Word("hierarchy"), _), ..]
    | [#(Word("disjoint"), _), #(Word("hierarchy"), _), ..] ->
      todo("missing hierarchy body with {}")

    [#(token, _), ..] -> todo("unexpected token")
    [] -> todo("unexpected EOF")
  }
}

fn parse_hierarchy_body(
  tokens: List(#(Token, Span)),
  entities: List(Entity),
) -> ParseResult(NonEmptyList(Entity)) {
  case tokens {
    [#(CloseBracket, _), ..tokens] -> {
      use entities <- result.map(
        entities
        |> list.reverse
        |> non_empty_list.from_list
        |> result.replace_error(Nil),
      )
      // Nice error about hierarchy not having empty body
      #(entities, tokens)
    }

    [#(Word("entity"), _), ..tokens] -> {
      use #(entity, tokens) <- result.try(parse_entity(tokens))
      parse_hierarchy_body(tokens, [entity, ..entities])
    }

    [#(Word("relationship"), _), ..] -> todo("error no rels inside hierarchy")
    [#(token, span), ..] -> todo("unexpected token")
    [] -> todo("unepected EOF")
  }
}

/// Relationship keyword already found.
/// 
fn parse_relationship(tokens: List(#(Token, Span))) -> ParseResult(Relationship) {
  case tokens {
    [#(Word(name), name_span), #(OpenBracket, _), ..tokens] ->
      parse_relationship_body(tokens, name, name_span, [], [])
    [#(Word(name), _), ..] -> todo("missing rel body")
    [#(OpenBracket, _), ..rest] -> todo("missing name error")
    [] -> todo("unexpected EOF")
  }
}

/// Open bracket already found.
/// 
fn parse_relationship_body(
  tokens: List(#(Token, Span)),
  name: String,
  name_span: Span,
  entities: List(RelationshipEntity),
  attributes: List(Attribute),
) -> ParseResult(Relationship) {
  case tokens {
    [#(CloseBracket, _), ..tokens] ->
      Relationship(name_span, name, entities, attributes)
      |> pair.new(tokens)
      |> Ok

    [#(CircleLollipop, _), ..tokens] -> {
      use #(attribute, tokens) <- result.try(parse_attribute(tokens))
      parse_relationship_body(
        tokens,
        name,
        name_span,
        entities,
        [attribute, ..attributes],
      )
    }

    [#(ArrowLollipop, _), ..tokens] -> {
      use #(entity, tokens) <- result.try(parse_relationship_entity(tokens))
      parse_relationship_body(
        tokens,
        name,
        name_span,
        [entity, ..entities],
        attributes,
      )
    }
    [#(StarLollipop, _), ..] -> todo("a relationship cannot have a key")
    [#(Minus, _), #(Word("o"), _), ..] -> todo("typo error")
    [#(Minus, _), #(Word(">"), _), ..] -> todo("typo error")

    [#(token, _), ..] -> {
      io.debug(token)
      todo("unexpected token")
    }
    [] -> todo("unexpected eof")
  }
}

/// -> was already found.
/// 
fn parse_relationship_entity(
  tokens: List(#(Token, Span)),
) -> ParseResult(RelationshipEntity) {
  case tokens {
    [#(Word(name), name_span), #(Colon, _), ..tokens] -> {
      use #(cardinality, tokens) <- result.map(parse_cardinality(tokens, False))
      #(RelationshipEntity(name_span, name, cardinality), tokens)
    }

    [#(Word(_), _), ..] -> todo("missing cardinality annotation")

    [#(token, _), ..] -> todo("unexpected token")
    [] -> todo("unexpected eof")
  }
}
