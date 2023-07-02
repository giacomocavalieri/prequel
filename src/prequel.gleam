import gleam/list
import gleam/option.{None, Option, Some}
import gleam/pair
import prequel/internals/token.{
  Ampersand, ArrowLollipop, CircleLollipop, CloseBracket, CloseParens, Colon,
  Minus, Number, OpenBracket, OpenParens, StarLollipop, Token, Word,
}
import prequel/span.{Span}
import prequel/parse_error.{ParseError}
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
  case do_parse(token.scan(source), [], []) {
    #(Ok(#(entities, relationships)), _) -> Ok(Module(entities, relationships))
    #(Error(_), _) -> Error(Nil)
  }
}

/// Tail recursive (hopefully, I should check it TODO) parser.
/// 
fn do_parse(
  tokens: List(#(Token, Span)),
  entities: List(Entity),
  relationships: List(Relationship),
) -> ParseResult(#(List(Entity), List(Relationship))) {
  case tokens {
    [] -> #(Ok(#(list.reverse(entities), list.reverse(relationships))), [])
    [#(Word("entity"), entity_span), ..tokens] -> {
      use entity, tokens <- try(parse_entity(tokens, entity_span))
      do_parse(tokens, [entity, ..entities], relationships)
    }
    [#(Word("relationship"), relationship_span), ..tokens] -> {
      use relationship, tokens <- try(parse_relationship(
        tokens,
        relationship_span,
      ))
      do_parse(tokens, entities, [relationship, ..relationships])
    }
    [#(token, span), ..] -> todo("nice error")
  }
}

/// An intermediate result of the parsing process, if the parsing step succeeds
/// it holds a pair with the remaining tokens and a result of type `a`.
/// 
type ParseResult(a) =
  #(Result(a, List(ParseError)), List(#(Token, Span)))

fn try(
  result: ParseResult(a),
  do: fn(a, List(#(Token, Span))) -> ParseResult(b),
) -> ParseResult(b) {
  let #(value, tokens) = result
  case value {
    Ok(a) -> do(a, tokens)
    Error(error) -> #(Error(error), tokens)
  }
}

fn fail(error: ParseError) -> ParseResult(a) {
  #(Error([error]), [])
}

/// Parse an entity once the `entity` keyword was already found.
/// 
fn parse_entity(
  tokens: List(#(Token, Span)),
  entity_span: Span,
) -> ParseResult(Entity) {
  case tokens {
    // If there is an open bracket '{', parses the body of the entity.
    [#(Word(name), name_span), #(OpenBracket, _), ..tokens] ->
      parse_entity_body(tokens, name, name_span, [], [], [], None)

    // Parses an entity with an empty body.
    [#(Word(name), name_span), ..tokens] ->
      Entity(name_span, name, [], [], [], None)
      |> Ok
      |> pair.new(tokens)

    [#(token, span), ..] ->
      parse_error.WrongEntityName(
        enclosing_definition: None,
        before_wrong_name: entity_span,
        wrong_name: token.to_string(token),
        wrong_name_span: span,
        hint: None,
      )
      |> fail

    [] -> todo("E003-entity")
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
      |> Ok
      |> pair.new(tokens)

    // If a `-o` is found, switches into attribute parsing.
    [#(CircleLollipop, span), ..tokens] -> {
      use attribute, tokens <- try(parse_attribute(tokens, name_span, span))
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
    [#(StarLollipop, lollipop_span), ..tokens] -> {
      use #(key, attribute), tokens <- try(parse_key(
        tokens,
        [],
        name_span,
        lollipop_span,
      ))
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
    [#(ArrowLollipop, lollipop_span), ..tokens] -> {
      use relationship, tokens <- try(parse_inner_relationship(
        tokens,
        name,
        name_span,
        lollipop_span,
      ))
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
        Some(_) ->
          todo("E004 move this down once a real hierarchy is found otherwise it would only highlight the first word and not everything like in the example")
        None -> {
          // Todo wrap in an internal error!
          let assert Ok(totality) = totality_from_string(word)
          use children, tokens <- try(parse_hierarchy(tokens, span, totality))
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
    [#(Minus, minus_span), #(Word("o"), o_span), ..] ->
      parse_error.PossibleCircleLollipopTypo(
        enclosing_definition: name_span,
        typo_span: span.merge(minus_span, o_span),
        hint: None,
      )
      |> fail

    [#(Minus, minus_span), #(Word("*"), star_span), ..] ->
      parse_error.PossibleStarLollipopTypo(
        enclosing_definition: name_span,
        typo_span: span.merge(minus_span, star_span),
        hint: None,
      )
      |> fail

    [#(Minus, minus_span), #(Word(">"), arrow_span), ..] ->
      parse_error.PossibleArrowLollipopTypo(
        enclosing_definition: name_span,
        typo_span: span.merge(minus_span, arrow_span),
        hint: None,
      )
      |> fail

    // If someone writes the qualifiers of a hierarchy in the wrong order (i.e.
    // first overlapping and then the other) it tells them the correct order and
    // suggests a fix.
    [#(Word(first), first_span), #(Word(second), second_span), ..] if {
      first == "overlapped" || first == "overlapping" || first == "disjoint"
    } && { second == "total" || second == "partial" } ->
      parse_error.WrongOrderOfHierarchyQualifiers(
        enclosing_entity: name_span,
        qualifiers_span: span.merge(first_span, second_span),
        first_qualifier: first,
        second_qualifier: second,
        hint: None,
      )
      |> fail

    // If someone writes a hierarchy without the qualifiers it tells them that
    // it should have qualifiers like overlapping etc.
    [#(Word("hierarchy"), span), ..] ->
      parse_error.UnqualifiedHierarchy(
        enclosing_entity: name_span,
        hierarchy_span: span,
        hint: None,
      )
      |> fail

    [#(_token, token_span), ..] ->
      parse_error.UnexpectedTokenInEntityBody(
        enclosing_entity: name_span,
        token_span: token_span,
        hint: None,
      )
      |> fail

    [] -> todo("E003 (while parsing the body of this entity)")
  }
}

/// Parses an attribute once the '-o' lollipop was found.
/// 
fn parse_attribute(
  tokens: List(#(Token, Span)),
  enclosing_span: Span,
  lollipop_span: Span,
) -> ParseResult(Attribute) {
  case tokens {
    // Parses an attribute that has a name and a type/cardinality annotation.
    // It is lenient and accepts no cardinality annotation only if there is a
    // type; otherwise it raises an error since the `:` would not be followed
    // by anything.
    [#(Word(name), name_span), #(Colon, colon_span), ..tokens] -> {
      use type_, tokens <- try(parse_attribute_type(tokens))
      use cardinality, tokens <- try(parse_cardinality(
        tokens,
        type_ != NoType,
        enclosing_span,
        colon_span,
      ))
      #(Ok(Attribute(name_span, name, cardinality, type_)), tokens)
    }

    // Parse an attribute that has no type/cardinality annotation, the default
    // cardinality of (1-1) is used.
    [#(Word(name), name_span), ..tokens] ->
      Attribute(name_span, name, Bounded(1, 1), NoType)
      |> Ok
      |> pair.new(tokens)

    [#(token, span), ..] ->
      parse_error.WrongAttributeName(
        enclosing_definition: enclosing_span,
        lollipop_span: lollipop_span,
        wrong_name: token.to_string(token),
        wrong_name_span: span,
        hint: None,
      )
      |> fail

    [] -> todo("E003 (attribute)")
  }
}

/// Parses the type of an attribute once `:` is found.
/// 
fn parse_attribute_type(tokens: List(#(Token, Span))) -> ParseResult(Type) {
  // TODO: actually parse a type! But I have to think long and hard about
  //       types before adding them.
  #(Ok(NoType), tokens)
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
  enclosing_span: Span,
  before_span: Span,
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
      //use lower <- result.try(int.parse(raw_lower))
      // todo("E014")
      //use upper <- result.map(int.parse(raw_upper))
      // todo("E014")
      //#(Bounded(lower, upper), tokens)
      todo
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
      //use lower <- result.map(int.parse(raw_lower))
      // todo("E014")
      //#(Unbounded(lower), tokens)
      todo
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
    ] -> todo("E015")

    // If the cardinality is correct but is missing the closing parentheses. 
    [#(OpenParens, _), #(Number(_), _), #(Minus, _), #(Number(_), _), ..]
    | [#(OpenParens, _), #(Number(_), _), #(Minus, _), #(Word(_), _), ..] ->
      todo("E016")

    // If the cardinality is (mostly) correct but is missing the second number.
    [#(OpenParens, _), #(Number(_), _), #(Minus, _), ..] -> todo("E016")

    // If the cardinality is (mostly) correct but is missing the `-`.
    [#(OpenParens, _), #(Number(_), _), ..] -> todo("E016")

    // If there is an `(` but nothing else making it a cardinality.
    [#(OpenParens, _), ..] -> todo("E016")

    // If there is a number it suggests that they probably forgot the `(`.
    [#(Number(n), _), ..] -> todo("E016")

    // If it is lenient and did not incur in any obvious mistake it defaults
    // to the `(1-1)` cardinality.
    [_, ..] if lenient -> #(Ok(Bounded(1, 1)), tokens)

    [#(token, span), ..] ->
      parse_error.WrongCardinalityAnnotation(
        enclosing_definition: enclosing_span,
        before_wrong_cardinality: before_span,
        wrong_cardinality: token.to_string(token),
        wrong_cardinality_span: span,
        hint: None,
      )
      |> fail

    [] -> todo("E003")
  }
}

/// Parses a key once the `-*` is found.
/// 
fn parse_key(
  tokens: List(#(Token, Span)),
  keys: List(String),
  entity_span: Span,
  lollipop_span: Span,
) -> ParseResult(#(Key, Option(Attribute))) {
  case tokens {
    // If there is a multi-item key with an `&` it switches to multi-key
    // parsing.
    [#(Word(key), first_word_span), #(Ampersand, _), ..tokens] -> {
      use key, tokens <- try(parse_multi_attribute_key(
        tokens,
        entity_span,
        lollipop_span,
        first_word_span,
        [key, ..keys],
      ))
      #(Ok(#(key, None)), tokens)
    }

    // If there is a `:` after the key name it switches to parsing a key
    // shorthand for attribute definition.
    // TODO SISTEMARE
    [#(Word(key), span), #(Colon, _), ..tokens] -> {
      use type_, tokens <- try(parse_attribute_type(tokens))
      let attribute = Attribute(span, key, Bounded(1, 1), type_)
      let key = Key(span, non_empty_list.single(key))
      #(Ok(#(key, Some(attribute))), tokens)
    }

    // If there is only a word it switches to parsing a key shorthand for an
    // attribute definition. (But it may also be a key alone and attribute
    // is duplicate TODO)
    [#(Word(key), span), ..tokens] ->
      Key(span, non_empty_list.new(key, keys))
      |> pair.new(None)
      |> Ok
      |> pair.new(tokens)

    [#(token, span), ..] ->
      parse_error.WrongKeyName(
        enclosing_entity: entity_span,
        lollipop_span: lollipop_span,
        wrong_key: token.to_string(token),
        wrong_key_span: span,
        hint: None,
      )
      |> fail

    [] -> todo("E003 (parsing key)")
  }
}

/// Parses a multi attribute key once an `&` is found.
/// 
fn parse_multi_attribute_key(
  tokens: List(#(Token, Span)),
  entity_span: Span,
  lollipop_span: Span,
  first_word_span: Span,
  keys: List(String),
) -> ParseResult(Key) {
  case tokens {
    // If there is another `&` it keeps going.
    [#(Word(key), _), #(Ampersand, _), ..tokens] ->
      parse_multi_attribute_key(
        tokens,
        entity_span,
        lollipop_span,
        first_word_span,
        [key, ..keys],
      )

    // If there is a `:` it reports an error since a multi-key cannot
    // have a type annotation.
    [#(Word(_), last_word_span), #(Colon, colon_span), ..] ->
      parse_error.TypeAnnotationOnMultiItemKey(
        enclosing_entity: entity_span,
        key_words_span: span.merge(first_word_span, last_word_span),
        colon_span: colon_span,
        hint: None,
      )
      |> fail

    // If there is a word not followed by `&` it is done parsing the key.
    [#(Word(key), last_word_span), ..tokens] ->
      first_word_span
      |> span.merge(with: last_word_span)
      |> Key(non_empty_list.new(key, keys))
      |> Ok
      |> pair.new(tokens)

    [#(token, span), ..] ->
      parse_error.WrongKeyName(
        enclosing_entity: entity_span,
        lollipop_span: lollipop_span,
        wrong_key: token.to_string(token),
        wrong_key_span: span,
        hint: None,
      )
      |> fail

    [] -> todo("E003 (parsing key)")
  }
}

/// Parses a relationship shorthand after finding a `->` inside a relationship
/// body.
/// 
fn parse_inner_relationship(
  tokens: List(#(Token, Span)),
  entity_name: String,
  entity_span: Span,
  lollipop_span: Span,
) -> ParseResult(Relationship) {
  case tokens {
    // This function is a bit scary looking, I should refactor this not sure how
    // for now some comments will suffice :)
    //
    // First expect to find a word, the name of the relationship, and a colon...
    [
      #(Word(relationship_name), relationship_span),
      #(Colon, colon_span),
      ..tokens
    ] -> {
      // ...then there should be a cardinality...
      use one_cardinality, tokens <- try(parse_cardinality(
        tokens,
        False,
        entity_span,
        colon_span,
      ))
      // TODO HERE I COULD CHANGE THE HINT TO SOMETHING ELSE BUT KEEP THE SAME ERROR

      case tokens {
        // ...followed by another name, that is the name of the second entity
        // taking part in the relationship.
        [#(Word(other_name), other_name_span), ..tokens] -> {
          // Then there should be its cardinality in the relationship.
          use other_cardinality, tokens <- try(parse_cardinality(
            tokens,
            False,
            entity_span,
            other_name_span,
          ))
          // TODO HERE I COULD CHANGE THE HINT TO SOMETHING ELSE BUT KEEP THE SAME ERROR

          let one_entity =
            RelationshipEntity(entity_span, entity_name, one_cardinality)
          let other_entity =
            RelationshipEntity(other_name_span, other_name, other_cardinality)
            |> non_empty_list.single

          case tokens {
            // Finally if there's an open bracket we parse the relationship body...
            [#(OpenBracket, _), ..tokens] -> {
              use attributes, tokens <- try(parse_inner_relationship_body(
                tokens,
                [],
                relationship_span,
              ))
              Relationship(
                relationship_span,
                relationship_name,
                one_entity,
                other_entity,
                attributes,
              )
              |> Ok
              |> pair.new(tokens)
            }
            // Otherwise return a relationship with no body.
            _ ->
              relationship_span
              |> Relationship(relationship_name, one_entity, other_entity, [])
              |> Ok
              |> pair.new(tokens)
          }
        }

        [#(token, span), ..] ->
          parse_error.WrongEntityName(
            enclosing_definition: Some(entity_span),
            before_wrong_name: todo("it should be the span of the cardinality!"),
            wrong_name: token.to_string(token),
            wrong_name_span: span,
            hint: None,
          )
          |> fail

        [] -> todo("E003 while parsing binary relationship")
      }
    }

    // If there is no `:` it is reported as an error since a cardinality is
    // always needed.
    [#(Word(_), name_span), ..] ->
      parse_error.MissingCardinalityAnnotation(
        enclosing_definition: entity_span,
        before_span: name_span,
        hint: None,
      )
      |> fail

    [#(token, span), ..] ->
      parse_error.WrongRelationshipName(
        enclosing_definition: Some(entity_span),
        before_wrong_name: lollipop_span,
        wrong_name: token.to_string(token),
        wrong_name_span: span,
        hint: None,
      )
      |> fail
    [] -> todo("E003")
  }
}

/// Parses the body of an inner relationship once its `{` is found.
/// 
fn parse_inner_relationship_body(
  tokens: List(#(Token, Span)),
  attributes: List(Attribute),
  relationship_span: Span,
) -> ParseResult(List(Attribute)) {
  case tokens {
    // When a `}` is met, ends the parsing and returns the parsed attributes.
    [#(CloseBracket, _), ..tokens] -> #(Ok(list.reverse(attributes)), tokens)

    // When a `-o` is met, switches to parsing an attribute.
    [#(CircleLollipop, span), ..tokens] -> {
      use attribute, tokens <- try(parse_attribute(
        tokens,
        relationship_span,
        span,
      ))
      parse_inner_relationship_body(
        tokens,
        [attribute, ..attributes],
        relationship_span,
      )
    }

    // When a `-*` is found reports an error since a relationship cannot
    // have a key inside.
    [#(StarLollipop, _), ..] -> todo("E024")

    // When a `->` is found reports an error since a relationship cannot
    // have another relationship inside.
    [#(ArrowLollipop, _), ..] -> todo("E025")

    // If someone writes `- o` it tells them there's possibly
    // a spelling mistake and suggests a fix.
    [#(Minus, minus_span), #(Word("o"), o_span), ..] ->
      parse_error.PossibleCircleLollipopTypo(
        enclosing_definition: relationship_span,
        typo_span: span.merge(minus_span, o_span),
        hint: None,
      )
      |> fail

    [#(token, _), ..] -> todo("E026")
    [] -> todo("E003")
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
      let assert Ok(overlapping) = overlapping_from_string(word)
      use entities, tokens <- try(parse_hierarchy_body(tokens, []))
      initial_span
      |> span.merge(with: final_span)
      |> Hierarchy(overlapping, totality, entities)
      |> Ok
      |> pair.new(tokens)
    }

    // If there is no `{`, reports the error since a hierarchy cannot
    // have an empty body.
    [#(Word("overlapped"), _), #(Word("hierarchy"), _), ..]
    | [#(Word("disjoint"), _), #(Word("hierarchy"), _), ..] -> todo("E029")

    // If there is the correct overlapping but no `hierarchy` keyword,
    // reports the missing keyword and suggests a fix.
    [#(Word("overlapped"), _), ..] | [#(Word("disjoint"), _), ..] ->
      todo("E028")

    [#(token, _), ..] -> todo("E027")
    [] -> todo("E003")
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
      // Todo replace with internal error
      let assert Ok(entities) =
        entities
        |> list.reverse
        |> non_empty_list.from_list
      #(Ok(entities), tokens)
    }

    // If the `entity` keyword is found, switches to entity parsing.
    [#(Word("entity"), span), ..tokens] -> {
      use entity, tokens <- try(parse_entity(tokens, span))
      parse_hierarchy_body(tokens, [entity, ..entities])
    }

    [#(token, span), ..] -> todo("E031")
    [] -> todo("E003")
  }
}

/// Parses a relationship after finding the `relationship` keyword.
/// 
fn parse_relationship(
  tokens: List(#(Token, Span)),
  relationship_span: Span,
) -> ParseResult(Relationship) {
  case tokens {
    // If there is the name and an `{` switches to parsing the relationship's
    // body.
    [#(Word(name), name_span), #(OpenBracket, _), ..tokens] ->
      parse_relationship_body(tokens, name, name_span, [], [])

    // If there is the relationship's name but no `{` reports it as an error
    // since a relationship must always have a body.
    [#(Word(name), _), ..] -> todo("E032")

    [#(token, span), ..] ->
      parse_error.WrongRelationshipName(
        enclosing_definition: None,
        before_wrong_name: relationship_span,
        wrong_name: token.to_string(token),
        wrong_name_span: span,
        hint: None,
      )
      |> fail
    [] -> todo("E003")
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
          |> Ok
          |> pair.new(tokens)
        _ -> todo("E032 o E033 a seconda del numero")
      }

    // If a `-o` is found, switch to attribute parsing.
    [#(CircleLollipop, span), ..tokens] -> {
      use attribute, tokens <- try(parse_attribute(tokens, name_span, span))
      parse_relationship_body(
        tokens,
        name,
        name_span,
        entities,
        [attribute, ..attributes],
      )
    }

    // If a `->` is found, switch to entity parsing.
    [#(ArrowLollipop, span), ..tokens] -> {
      use entity, tokens <- try(parse_relationship_entity(
        tokens,
        name_span,
        span,
      ))
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
    [#(StarLollipop, _), ..] -> todo("E024")

    // If someone writes `- o` or `- >` it tells them there's possibly
    // a spelling mistake and suggests a fix.
    [#(Minus, minus_span), #(Word("o"), o_span), ..] ->
      parse_error.PossibleCircleLollipopTypo(
        enclosing_definition: name_span,
        typo_span: span.merge(minus_span, o_span),
        hint: None,
      )
      |> fail

    [#(Minus, minus_span), #(Word(">"), arrow_span), ..] ->
      parse_error.PossibleArrowLollipopTypo(
        enclosing_definition: name_span,
        typo_span: span.merge(minus_span, arrow_span),
        hint: None,
      )
      |> fail

    [#(token, _), ..] -> todo("E034")
    [] -> todo("E003")
  }
}

/// Parses an entity of a relationship after finding a `->`.
/// 
fn parse_relationship_entity(
  tokens: List(#(Token, Span)),
  relationship_span: Span,
  lollipop_span: Span,
) -> ParseResult(RelationshipEntity) {
  case tokens {
    // In case the entity name and a `:` is found, switches to parsing
    // the cardinality of the entity.
    [#(Word(name), name_span), #(Colon, colon_span), ..tokens] -> {
      use cardinality, tokens <- try(parse_cardinality(
        tokens,
        False,
        relationship_span,
        colon_span,
      ))
      #(Ok(RelationshipEntity(name_span, name, cardinality)), tokens)
    }

    // In case there is no cardinality annotation, reports it as an error
    [#(Word(_), name_span), ..] ->
      parse_error.MissingCardinalityAnnotation(
        enclosing_definition: relationship_span,
        before_span: name_span,
        hint: None,
      )
      |> fail

    [#(token, span), ..] ->
      parse_error.WrongEntityName(
        enclosing_definition: Some(relationship_span),
        before_wrong_name: lollipop_span,
        wrong_name: token.to_string(token),
        wrong_name_span: span,
        hint: None,
      )
      |> fail

    [] -> todo("E003")
  }
}
