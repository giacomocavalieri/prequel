import gleam/int
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/pair
import gleam/result
import prequel/internals/scanner.{
  Ampersand, ArrowLollipop, CircleLollipop, CloseBracket, CloseParens, Colon,
  Minus, Number, OpenBracket, OpenParens, StarLollipop, Token, Word,
}
import prequel/span.{Span}
import non_empty_list.{NonEmptyList}

/// A module is the result obtained by parsing a file, it contains a list of
/// entities and relationships.
/// 
pub type Module {
  Module(entities: List(Entity), relationships: List(Relationship))
}

/// A relationship as described by the ER model. It always involves at least
/// two entities and can also have attributes.
/// 
pub type Relationship {
  Relationship(
    span: Span,
    name: String,
    entity: RelationshipEntity,
    entities: NonEmptyList(RelationshipEntity),
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

/// An attribute that can be found inside the body of an entity or a
/// relationship.
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

/// Parses a string into a `Totality` value.
/// 
fn totality_from_string(string: String) -> Result(Totality, Nil) {
  case string {
    "total" -> Ok(Total)
    "partial" -> Ok(Partial)
    _ -> Error(Nil)
  }
}

/// Parses a string into an `Overlapping` value.
/// 
fn overlapping_from_string(string: String) -> Result(Overlapping, Nil) {
  case string {
    "overlapped" -> Ok(Overlapped)
    "disjoint" -> Ok(Disjoint)
    _ -> Error(Nil)
  }
}

/// Parses a string into a `Module`.
/// 
pub fn parse(source: String) -> Result(Module, Nil) {
  use #(entities, relationships) <- result.map(do_parse(
    scanner.scan(source),
    [],
    [],
  ))
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

/// An intermediate result of the parsing process, if the parsing step succeeds
/// it holds a pair with the remaining tokens and a result of type `a`.
/// 
type ParseResult(a) =
  Result(#(a, List(#(Token, Span))), Nil)

/// Parse an entity once the `entity` keyword was already found.
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

/// Once an open bracket `{` is found, this function can be called to parse
/// the body of an entity. It expects the body to be closed by a closed
/// bracket `}`.
/// 
/// It returns the completely parsed entity using the `name` and `name_span`
/// passed as arguments.
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
    // If a '}' is found, the entity parsing is done.
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

    // If a `-o` is found, switches into attribute parsing.
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

    // If a `-*` is found, switches into key parsing. TODO REWORK THIS ONCE THE
    // AST IS CHANGED TO TAKE INTO ACCOUNT SHORTHAND KEYS
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

    // If a `->` is found, switches into relationship parsing.
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

    // If a `total` or `partial` word is found, switches into hierarchy parsing.
    [#(Word("total" as word), span), ..tokens]
    | [#(Word("partial" as word), span), ..tokens] -> {
      case children {
        Some(_) -> todo("error about duplicate hierarchy")
        None -> {
          use totality <- result.try(totality_from_string(word))
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

    // If someone writes `- o`, `- *` or `- >` it tells them there's possibly
    // a spelling mistake and suggests a fix.
    [#(Minus, _), #(Word("o"), _), ..] -> todo("error message about typo")
    [#(Minus, _), #(Word("*"), _), ..] -> todo("error message about typo")
    [#(Minus, _), #(Word(">"), _), ..] -> todo("error message about typo")

    // If someone writes the qualifiers of a hierarchy in the wrong order (i.e.
    // first overlapping and then the other) it tells them the correct order and
    // suggests a fix.
    [#(Word("overlapped"), span), ..] -> todo("error message about wrong order")
    [#(Word("overlapping"), span), ..] -> todo("wrong order")
    [#(Word("disjoint"), span), ..] -> todo("error message about wrong order")

    // If someone writes a hierarchy without the qualifiers it tells them that
    // it should have qualifiers like overlapping etc.
    [#(Word("hierarchy"), span), ..] -> todo("hierarchy should be qualified")

    [#(token, _), ..] -> todo("unexpected token")
    [] -> todo("unexpected EOF")
  }
}

/// Parses an attribute once the '-o' lollipop was found.
/// 
fn parse_attribute(tokens: List(#(Token, Span))) -> ParseResult(Attribute) {
  case tokens {
    // Parses an attribute that has a name and a type/cardinality annotation.
    // It is lenient and accepts no cardinality annotation only if there is a
    // type; otherwise it raises an error since the `:` is not followed by
    // anything.
    [#(Word(name), name_span), #(Colon, _), ..tokens] -> {
      use #(type_, tokens) <- result.try(parse_attribute_type(tokens))
      let should_be_lenient = type_ != NoType
      let result = parse_cardinality(tokens, should_be_lenient)
      use #(cardinality, tokens) <- result.map(result)
      #(Attribute(name_span, name, cardinality, type_), tokens)
    }

    // Parse an attribute that has no type/cardinality annotation, the default
    // cardinality of (1-1) is used.
    [#(Word(name), name_span), ..tokens] ->
      Attribute(name_span, name, Bounded(1, 1), NoType)
      |> pair.new(tokens)
      |> Ok

    [#(token, span), ..] -> todo("unexpected token")
    [] -> todo("unexpected EOF")
  }
}

/// Parses the type of an attribute once `:` is found.
/// 
fn parse_attribute_type(tokens: List(#(Token, Span))) -> ParseResult(Type) {
  // TODO: actually parse a type! But I have to think long and hard about
  //       types before adding them.
  Ok(#(NoType, tokens))
}

/// Parses a cardinality. If `lenient` is true it can recover with a default
/// cardinality of (1-1).
/// However, recovery is not guaranteed, for example in some cases there could
/// still be an error to provide better error messages; consider this example:
/// 
/// ```
/// -o attr : (1-
/// ```
/// 
/// The programmer here may have wanted to specify a cardinality, if the parsing
/// failed and recovered with a default cardinality of (1-1) then the error
/// would be on the incomplete `(1-` when the parser tries to parse the
/// following attribute giving a puzzling error along the lines of "I was
/// expecting an attribute/key/...".
/// 
/// By not recovering we can provide a more insightful error about an
/// _incomplete_ cardinality that is maybe missing a piece.
/// That is why, as soon as this function finds a `(` it becomes impossible to
/// recover, even if lenient is set to `True`.
/// 
fn parse_cardinality(
  tokens: List(#(Token, Span)),
  lenient: Bool,
) -> ParseResult(Cardinality) {
  case tokens {
    // Parses a bounded cardinality in the form `(<number> - <number>)`.
    [
      #(OpenParens, _),
      #(Number(raw_lower), _),
      #(Minus, _),
      #(Number(raw_upper), _),
      #(CloseParens, _),
      ..tokens
    ] -> {
      use lower <- result.try(int.parse(raw_lower))
      use upper <- result.map(int.parse(raw_upper))
      #(Bounded(lower, upper), tokens)
    }

    // Parse an unbounded cardinality in the form `(<number> - N)`.
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

    // If one writes a letter that is not `N` in an unbounded cardinality, it
    // tells them there's an error and suggests a fix.
    [
      #(OpenParens, _),
      #(Number(_), _),
      #(Minus, _),
      #(Word(_), _),
      #(CloseParens, _),
      ..
    ] -> todo("wrong letter in unbounded cardinality")

    // If the cardinality is correct but is missing the closing parentheses. 
    [#(OpenParens, _), #(Number(_), _), #(Minus, _), #(Number(_), _), ..]
    | [#(OpenParens, _), #(Number(_), _), #(Minus, _), #(Word(_), _), ..] ->
      todo("there should be a closed parens here")

    // If the cardinality is (mostly) correct but is missing the second number.
    [#(OpenParens, _), #(Number(_), _), #(Minus, _), ..] ->
      todo("there should be a number or an N here")

    // If the cardinality is (mostly) correct but is missing the `-`.
    [#(OpenParens, _), #(Number(_), _), ..] ->
      todo("there should be a minus here")

    // If there is an `(` but nothing else making it a cardinality.
    [#(OpenParens, _), ..] -> todo("there should be a number here")

    // If there is a number it suggests that they probably forgot the `(`.
    [#(Number(n), _), ..] -> todo("probably missing open parens before number")

    // If it is lenient and did not incur in any obvious mistake it defaults
    // to the `(1-1)` cardinality.
    [_, ..] if lenient -> Ok(#(Bounded(1, 1), tokens))

    [#(token, span), ..] -> todo("unexpected token")
    [] -> todo("unexpected EOF")
  }
}

/// Parses a key once the `-*` is found.
/// 
fn parse_key(
  tokens: List(#(Token, Span)),
  keys: List(String),
) -> ParseResult(#(Key, Option(Attribute))) {
  case tokens {
    // If there is a multi-item key with an `&` it switches to multi-key
    // parsing.
    [#(Word(key), span), #(Ampersand, _), ..tokens] -> {
      let result = parse_multi_attribute_key(tokens, span, [key, ..keys])
      use #(key, tokens) <- result.map(result)
      #(#(key, None), tokens)
    }

    // If there is a `:` after the key name it switches to parsing a key
    // shorthand for attribute definition.
    // TODO SISTEMARE
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

    // If there is only a word it switches to parsing a key shorthand for an
    // attribute definition. (But it may also be a key alone and attribute
    // is duplicate TODO)
    [#(Word(key), span), ..tokens] ->
      Key(span, non_empty_list.new(key, keys))
      |> pair.new(None)
      |> pair.new(tokens)
      |> Ok

    [#(token, span), ..] -> todo("unexpected token")
    [] -> todo("unexpected EOF")
  }
}

/// Parses a multi attribute key once an `&` is found.
/// 
fn parse_multi_attribute_key(
  tokens: List(#(Token, Span)),
  initial_span: Span,
  keys: List(String),
) -> ParseResult(Key) {
  case tokens {
    // If there is another `&` it keeps going.
    [#(Word(key), _), #(Ampersand, _), ..tokens] ->
      parse_multi_attribute_key(tokens, initial_span, [key, ..keys])

    // If there is a `:` it reports an error since a multi-key cannot
    // have a type annotation.
    [#(Word(_), _), #(Colon, _), ..] ->
      todo("error no type annotation in multi element key")

    // If there is a word not followed by `&` it is done parsing the key.
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

/// Parses a relationship shorthand after finding a `->` inside a relationship
/// body.
/// 
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
            |> non_empty_list.single

          case tokens {
            // Finally if there's an open bracket we parse the relationship body...
            [#(OpenBracket, _), ..tokens] -> {
              let result = parse_inner_relationship_body(tokens, [])
              use #(attributes, tokens) <- result.map(result)
              Relationship(
                relationship_span,
                relationship_name,
                one_entity,
                other_entity,
                attributes,
              )
              |> pair.new(tokens)
            }
            // Otherwise return a relationship with no body.
            _ ->
              relationship_span
              |> Relationship(relationship_name, one_entity, other_entity, [])
              |> pair.new(tokens)
              |> Ok
          }
        }

        _ -> todo("expecting word")
      }
    }

    // If there is no `:` it is reported as an error since a cardinality is
    // always needed.
    [#(Word(name), _), ..] ->
      todo("inner relationship missing cardinality annotation")

    [#(token, _), ..] -> todo("I was expecting a word here")
    [] -> todo("unexpected EOF")
  }
}

/// Parses the body of an inner relationship once its `{` is found.
/// 
fn parse_inner_relationship_body(
  tokens: List(#(Token, Span)),
  attributes: List(Attribute),
) -> ParseResult(List(Attribute)) {
  case tokens {
    // When a `}` is met, ends the parsing and returns the parsed attributes.
    [#(CloseBracket, _), ..tokens] -> Ok(#(list.reverse(attributes), tokens))

    // When a `-o` is met, switches to parsing an attribute.
    [#(CircleLollipop, _), ..tokens] -> {
      use #(attribute, tokens) <- result.try(parse_attribute(tokens))
      parse_inner_relationship_body(tokens, [attribute, ..attributes])
    }

    // When a `-*` is found reports an error since a relationship cannot
    // have a key inside.
    [#(StarLollipop, _), ..] -> todo("a relationship cannot have a key inside")

    // When a `->` is found reports an error since a relationship cannot
    // have another relationship inside.
    [#(ArrowLollipop, _), ..] -> todo("a short rel cannot have other rels")

    // If someone writes `- o` it tells them there's possibly
    // a spelling mistake and suggests a fix.
    [#(Minus, _), #(Word("o"), _), ..] -> todo("possible typo")

    [#(token, _), ..] -> todo("unexpected token")
    [] -> todo("unexpected EOF")
  }
}

/// Parses a hierarchy after finding the `total`/`partial` keyword.
/// 
fn parse_hierarchy(
  tokens: List(#(Token, Span)),
  initial_span: Span,
  totality: Totality,
) -> ParseResult(Hierarchy) {
  case tokens {
    // If someone writes `overlapping` instead of `overlapped`, tells them
    // this is a mistake and suggests the correct spelling.
    [#(Word("overlapping"), _), ..tokens] -> todo("error about wrong spelling")

    // If someone writes `hierarchy` without specifying the overlapping of
    // the hierarchy, tells them this is a mistake and suggests a correction.
    [#(Word("hierarchy"), _), ..tokens] ->
      todo("error about missing overlapping")

    // If the correct overlapping and the `hierarchy` keyword are found,
    // switches to parsing the hierarchy's body.
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

    // If there is the correct overlapping but no `hierarchy` keyword,
    // reports the missing keyword and suggests a fix.
    [#(Word("overlapped"), _), #(OpenBracket, _), ..]
    | [#(Word("disjoint"), _), #(OpenBracket, _), ..] ->
      todo("missing hierarchy keyword error")

    // If there is no `{`, reports the error since a hierarchy cannot
    // have an empty body.
    [#(Word("overlapped"), _), #(Word("hierarchy"), _), ..]
    | [#(Word("disjoint"), _), #(Word("hierarchy"), _), ..] ->
      todo("missing hierarchy body with {}")

    [#(token, _), ..] -> todo("unexpected token")
    [] -> todo("unexpected EOF")
  }
}

/// Parses the body of a hierarchy after finding its `{`.
/// 
fn parse_hierarchy_body(
  tokens: List(#(Token, Span)),
  entities: List(Entity),
) -> ParseResult(NonEmptyList(Entity)) {
  case tokens {
    // If a `}` is found ends the parsing process. A check is performed to
    // guarantee that there was at least an entity in the hierarchy's body.
    [#(CloseBracket, _), ..tokens] -> {
      use entities <- result.map(
        entities
        |> list.reverse
        |> non_empty_list.from_list
        |> result.replace_error(Nil),
      )
      #(entities, tokens)
    }

    // If the `entity` keyword is found, switches to entity parsing.
    [#(Word("entity"), _), ..tokens] -> {
      use #(entity, tokens) <- result.try(parse_entity(tokens))
      parse_hierarchy_body(tokens, [entity, ..entities])
    }

    // If the `relationship` keyword is found, reports it as an error since
    // a hierarchy cannot have a relationship defined inside it.
    [#(Word("relationship"), _), ..] -> todo("error no rels inside hierarchy")
    [#(token, span), ..] -> todo("unexpected token")
    [] -> todo("unepected EOF")
  }
}

/// Parses a relationship after finding the `relationship` keyword.
/// 
fn parse_relationship(tokens: List(#(Token, Span))) -> ParseResult(Relationship) {
  case tokens {
    // If there is the name and an `{` switches to parsing the relationship's
    // body.
    [#(Word(name), name_span), #(OpenBracket, _), ..tokens] ->
      parse_relationship_body(tokens, name, name_span, [], [])

    // If there is the relationship's name but no `{` reports it as an error
    // since a relationship must always have a body.
    [#(Word(name), _), ..] -> todo("missing rel body")

    // If there is no name before the `{`, reports the missing name as an error.
    [#(OpenBracket, _), ..rest] -> todo("missing name error")

    [#(token, _), ..] -> todo("unexpected token")
    [] -> todo("unexpected EOF")
  }
}

/// Parses the body of a relationship after finding a `{`.
/// 
fn parse_relationship_body(
  tokens: List(#(Token, Span)),
  name: String,
  name_span: Span,
  entities: List(RelationshipEntity),
  attributes: List(Attribute),
) -> ParseResult(Relationship) {
  case tokens {
    // If a `}` is found. Ends the parsing process and returns the parsed
    // relationship.
    [#(CloseBracket, _), ..tokens] ->
      case entities {
        [one_entity, other_entity, ..other_entities] ->
          non_empty_list.new(other_entity, other_entities)
          |> Relationship(name_span, name, one_entity, _, attributes)
          |> pair.new(tokens)
          |> Ok
        _ -> todo("not enough entities in the relationship")
      }

    // If a `-o` is found, switch to attribute parsing.
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

    // If a `->` is found, switch to entity parsing.
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

    // If a `-*` is found, reports the error since a relationship cannot have
    // a key.
    [#(StarLollipop, _), ..] -> todo("a relationship cannot have a key")

    // If someone writes `- o` or `- >` it tells them there's possibly
    // a spelling mistake and suggests a fix.
    [#(Minus, _), #(Word("o"), _), ..] -> todo("typo error")
    [#(Minus, _), #(Word(">"), _), ..] -> todo("typo error")

    [#(token, _), ..] -> todo("unexpected token")
    [] -> todo("unexpected eof")
  }
}

/// Parses an entity of a relationship after finding a `->`.
/// 
fn parse_relationship_entity(
  tokens: List(#(Token, Span)),
) -> ParseResult(RelationshipEntity) {
  case tokens {
    // In case the entity name and a `:` is found, switches to parsing
    // the cardinality of the entity.
    [#(Word(name), name_span), #(Colon, _), ..tokens] -> {
      use #(cardinality, tokens) <- result.map(parse_cardinality(tokens, False))
      #(RelationshipEntity(name_span, name, cardinality), tokens)
    }

    // In case there is no cardinality annotation, reports it as an error
    [#(Word(_), _), ..] -> todo("missing cardinality annotation")

    [#(token, _), ..] -> todo("unexpected token")
    [] -> todo("unexpected eof")
  }
}
