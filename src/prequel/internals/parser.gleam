import gleam/int
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/result
import non_empty_list.{NonEmptyList}
import prequel/ast.{
  Attribute, Bounded, Cardinality, ComposedKey, Disjoint, Entity, Hierarchy, Key,
  Module, NoType, Overlapped, Overlapping, Partial, Relationship,
  RelationshipEntity, SingleKey, Total, Totality, Type, Unbounded,
}
import prequel/error/parse_error.{ParseError}
import prequel/span.{Span}
import prequel/internals/token.{
  Ampersand, ArrowLollipop, CircleLollipop, CloseBracket, CloseParens, Colon,
  Minus, Number, OpenBracket, OpenParens, StarLollipop, Token, Word,
}

/// Tail recursive (hopefully, I should check it!! TODO) parser.
/// 
pub fn parse(tokens: List(#(Token, Span))) -> Result(Module, ParseError) {
  case do_parse(tokens, [], []) {
    Ok(#(module, _)) -> Ok(module)
    Error(error) -> Error(error)
  }
}

fn do_parse(
  tokens: List(#(Token, Span)),
  entities: List(Entity),
  relationships: List(Relationship),
) -> ParseResult(Module) {
  case tokens {
    [] ->
      Module(list.reverse(entities), list.reverse(relationships))
      |> succeed([])

    [#(Word("entity"), entity_keyword_span), ..tokens] -> {
      use entity, tokens <- try(parse_entity(tokens, entity_keyword_span))
      do_parse(tokens, [entity, ..entities], relationships)
    }

    [#(Word("relationship"), relationship_span), ..tokens] -> {
      use relationship, tokens <- try(parse_relationship(
        tokens,
        relationship_span,
      ))
      do_parse(tokens, entities, [relationship, ..relationships])
    }

    [#(_, span), ..] ->
      parse_error.UnexpectedTokenInTopLevel(
        token_span: span,
        hint: Some("TODO: add hint"),
      )
      |> fail
  }
}

/// An intermediate result of the parsing process, if the parsing step succeeds
/// it holds a pair with the remaining tokens and a result of type `a`.
/// 
type ParseResult(a) =
  Result(#(a, List(#(Token, Span))), ParseError)

fn try(
  result: ParseResult(a),
  do: fn(a, List(#(Token, Span))) -> ParseResult(b),
) -> ParseResult(b) {
  case result {
    Ok(#(a, tokens)) -> do(a, tokens)
    Error(error) -> Error(error)
  }
}

fn fail(error: ParseError) -> ParseResult(a) {
  Error(error)
}

fn succeed(result: a, tokens: List(#(Token, Span))) -> ParseResult(a) {
  Ok(#(result, tokens))
}

/// Parse an entity once the `entity` keyword was already found.
/// 
fn parse_entity(
  tokens: List(#(Token, Span)),
  entity_keyword_span: Span,
) -> ParseResult(Entity) {
  case tokens {
    // If there is an open bracket '{', parses the body of the entity.
    [#(Word(entity_name), entity_span), #(OpenBracket, _), ..tokens] ->
      parse_entity_body(tokens, entity_name, entity_span)

    // Parses an entity with an empty body.
    [#(Word(entity_name), entity_span), ..tokens] ->
      Entity(entity_span, entity_name, [], [], [], None)
      |> succeed(tokens)

    [#(token, span), ..] ->
      parse_error.WrongEntityName(
        enclosing_definition: None,
        before_wrong_name: entity_keyword_span,
        wrong_name: token.to_string(token),
        wrong_name_span: span,
        after_what: "the `entity` keyword",
        hint: Some("TODO: add hint"),
      )
      |> fail

    [] ->
      parse_error.UnexpectedEndOfFile(
        enclosing_definition: None,
        context_span: entity_keyword_span,
        context: "this entity",
        hint: Some("TODO: add hint"),
      )
      |> fail
  }
}

/// Once an open bracket `{` is found, this function can be called to parse
/// the body of an entity. It expects the body to be closed by a closed
/// bracket `}`.
/// 
/// It returns the completely parsed entity using the `name` and `name_span`
/// passed as arguments.
/// 
/// 
fn parse_entity_body(
  tokens: List(#(Token, Span)),
  entity_name: String,
  entity_span: Span,
) {
  do_parse_entity_body(tokens, entity_name, entity_span, [], [], [], None)
}

fn do_parse_entity_body(
  tokens: List(#(Token, Span)),
  entity_name: String,
  entity_span: Span,
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
        entity_span,
        entity_name,
        list.reverse(keys),
        list.reverse(attributes),
        list.reverse(inner_relationships),
        children,
      )
      |> succeed(tokens)

    // If a `-o` is found, switches into attribute parsing.
    [#(CircleLollipop, lollipop_span), ..tokens] -> {
      use attribute, tokens <- try(parse_attribute(
        tokens,
        entity_span,
        lollipop_span,
      ))
      do_parse_entity_body(
        tokens,
        entity_name,
        entity_span,
        keys,
        [attribute, ..attributes],
        inner_relationships,
        children,
      )
    }

    // If a `-*` is found, switches into key parsing.
    [#(StarLollipop, lollipop_span), ..tokens] -> {
      use key, tokens <- try(parse_key(tokens, entity_span, lollipop_span))
      do_parse_entity_body(
        tokens,
        entity_name,
        entity_span,
        [key, ..keys],
        attributes,
        inner_relationships,
        children,
      )
    }

    // If a `->` is found, switches into relationship parsing.
    [#(ArrowLollipop, lollipop_span), ..tokens] -> {
      use relationship, tokens <- try(parse_inner_relationship(
        tokens,
        entity_name,
        entity_span,
        lollipop_span,
      ))
      do_parse_entity_body(
        tokens,
        entity_name,
        entity_span,
        keys,
        attributes,
        [relationship, ..inner_relationships],
        children,
      )
    }

    // If a `total` or `partial` word is found, switches into hierarchy parsing.
    [#(Word("total" as totality_string), totality_span), ..tokens]
    | [#(Word("partial" as totality_string), totality_span), ..tokens] -> {
      let error =
        parse_error.InternalError(
          enclosing_definition: Some(entity_span),
          context_span: totality_span,
          context: "A call to `totality_from_string` failed despite this being assumed a correct totality",
          hint: Some("TODO: add hint"),
        )

      let result =
        result.replace_error(totality_from_string(totality_string), error)
      use totality <- result.try(result)
      use hierarchy, tokens <- try(parse_hierarchy(
        tokens,
        entity_span,
        totality_span,
        children,
        totality,
      ))
      do_parse_entity_body(
        tokens,
        entity_name,
        entity_span,
        keys,
        attributes,
        inner_relationships,
        Some(hierarchy),
      )
    }

    // If someone writes `- o`, `- *` or `- >` it tells them there's possibly
    // a spelling mistake and suggests a fix.
    [#(Minus, minus_span), #(Word("o"), o_span), ..] ->
      parse_error.PossibleCircleLollipopTypo(
        enclosing_definition: entity_span,
        typo_span: span.merge(minus_span, o_span),
        hint: Some("TODO: add hint"),
      )
      |> fail

    [#(Minus, minus_span), #(Word("*"), star_span), ..] ->
      parse_error.PossibleStarLollipopTypo(
        enclosing_definition: entity_span,
        typo_span: span.merge(minus_span, star_span),
        hint: Some("TODO: add hint"),
      )
      |> fail

    [#(Minus, minus_span), #(Word(">"), arrow_span), ..] ->
      parse_error.PossibleArrowLollipopTypo(
        enclosing_definition: entity_span,
        typo_span: span.merge(minus_span, arrow_span),
        hint: Some("TODO: add hint"),
      )
      |> fail

    // If someone writes the qualifiers of a hierarchy in the wrong order (i.e.
    // first overlapping and then the other) it tells them the correct order and
    // suggests a fix.
    [#(Word(first), first_span), #(Word(second), second_span), ..] if {
      first == "overlapped" || first == "overlapping" || first == "disjoint"
    } && { second == "total" || second == "partial" } ->
      parse_error.WrongOrderOfHierarchyQualifiers(
        enclosing_entity: entity_span,
        qualifiers_span: span.merge(first_span, second_span),
        first_qualifier: first,
        second_qualifier: second,
        hint: Some("TODO: add hint"),
      )
      |> fail

    // If someone writes a hierarchy without the qualifiers it tells them that
    // it should have qualifiers like overlapping etc.
    [#(Word("hierarchy"), span), ..] ->
      parse_error.UnqualifiedHierarchy(
        enclosing_entity: entity_span,
        hierarchy_span: span,
        hint: Some("TODO: add hint"),
      )
      |> fail

    [#(_, token_span), ..] ->
      parse_error.UnexpectedTokenInEntityBody(
        enclosing_entity: entity_span,
        token_span: token_span,
        hint: Some("TODO: add hint"),
      )
      |> fail

    [] ->
      parse_error.UnexpectedEndOfFile(
        enclosing_definition: None,
        context_span: entity_span,
        context: "the body of this entity",
        hint: Some("TODO: add hint"),
      )
      |> fail
  }
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
      Attribute(name_span, name, cardinality, type_)
      |> succeed(tokens)
    }

    // Parse an attribute that has no type/cardinality annotation, the default
    // cardinality of (1-1) is used.
    [#(Word(name), name_span), ..tokens] ->
      Attribute(name_span, name, Bounded(name_span, 1, 1), NoType)
      |> succeed(tokens)

    [#(token, span), ..] ->
      parse_error.WrongAttributeName(
        enclosing_definition: enclosing_span,
        lollipop_span: lollipop_span,
        wrong_name: token.to_string(token),
        wrong_name_span: span,
        hint: Some("TODO: add hint"),
      )
      |> fail

    [] ->
      parse_error.UnexpectedEndOfFile(
        enclosing_definition: Some(enclosing_span),
        context_span: lollipop_span,
        context: "this attribute",
        hint: Some("TODO: add hint"),
      )
      |> fail
  }
}

/// Parses the type of an attribute once `:` is found.
/// 
fn parse_attribute_type(tokens: List(#(Token, Span))) -> ParseResult(Type) {
  // TODO: actually parse a type! But I have to think long and hard about
  //       types before adding them.
  NoType
  |> succeed(tokens)
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
  preceding_span: Span,
) -> ParseResult(Cardinality) {
  case tokens {
    // Parses a bounded cardinality in the form `(<number> - <number>)`.
    [
      #(OpenParens, start),
      #(Number(raw_lower), raw_lower_span),
      #(Minus, _),
      #(Number(raw_upper), raw_upper_span),
      #(CloseParens, end),
      ..tokens
    ] -> {
      let result = parse_number(raw_lower, raw_lower_span, enclosing_span)
      use lower <- result.try(result)
      let result = parse_number(raw_upper, raw_upper_span, enclosing_span)
      use upper <- result.try(result)

      Bounded(span.merge(start, end), lower, upper)
      |> succeed(tokens)
    }

    // Parse an unbounded cardinality in the form `(<number> - N)`.
    [
      #(OpenParens, start),
      #(Number(raw_lower), raw_lower_span),
      #(Minus, _),
      #(Word("N"), _),
      #(CloseParens, end),
      ..tokens
    ] -> {
      let result = parse_number(raw_lower, raw_lower_span, enclosing_span)
      use lower <- result.try(result)
      Unbounded(span.merge(start, end), lower)
      |> succeed(tokens)
    }

    // If one writes a letter that is not `N` in an unbounded cardinality, it
    // tells them there's an error and suggests a fix.
    [
      #(OpenParens, _),
      #(Number(_), _),
      #(Minus, _),
      #(Word(_), span),
      #(CloseParens, _),
      ..
    ] ->
      parse_error.WrongLetterInUnboundedCardinality(
        enclosing_definition: enclosing_span,
        wrong_letter_span: span,
        hint: Some("TODO: add hint"),
      )
      |> fail

    // If the cardinality is correct but is missing the closing parentheses. 
    [#(OpenParens, start), #(Number(_), _), #(Minus, _), #(Number(_), end), ..]
    | [#(OpenParens, start), #(Number(_), _), #(Minus, _), #(Word(_), end), ..] ->
      parse_error.IncompleteCardinality(
        enclosing_definition: enclosing_span,
        cardinality_span: span.merge(start, end),
        missing: "a closed parentheses",
        hint: Some("TODO: add hint"),
      )
      |> fail

    // If the cardinality is (mostly) correct but is missing the second number.
    [#(OpenParens, start), #(Number(_), _), #(Minus, end), ..] ->
      parse_error.IncompleteCardinality(
        enclosing_definition: enclosing_span,
        cardinality_span: span.merge(start, end),
        missing: "an upper bound",
        hint: Some("TODO: add hint"),
      )
      |> fail

    // If the cardinality is (mostly) correct but is missing the `-`.
    [#(OpenParens, start), #(Number(_), end), ..] ->
      parse_error.IncompleteCardinality(
        enclosing_definition: enclosing_span,
        cardinality_span: span.merge(start, end),
        missing: "an upper bound",
        hint: Some("TODO: add hint"),
      )
      |> fail

    // If there is an `(` but nothing else making it a cardinality.
    [#(OpenParens, span), ..] ->
      parse_error.IncompleteCardinality(
        enclosing_definition: enclosing_span,
        cardinality_span: span,
        missing: "a lower bound",
        hint: Some("TODO: add hint"),
      )
      |> fail

    // If there is a number it suggests that they probably forgot the `(`.
    // TODO: This could be a bit more sophisticated and look ahead to see
    //       if what comes after actually resembles a cardinality
    [#(Number(_), span), ..] ->
      parse_error.IncompleteCardinality(
        enclosing_definition: enclosing_span,
        cardinality_span: span,
        missing: "an open parentheses",
        hint: Some("TODO: add hint"),
      )
      |> fail

    // If it is lenient and did not incur in any obvious mistake it defaults
    // to the `(1-1)` cardinality.
    [_, ..] if lenient ->
      Bounded(preceding_span, 1, 1)
      |> succeed(tokens)

    [#(token, span), ..] ->
      parse_error.WrongCardinalityAnnotation(
        enclosing_definition: enclosing_span,
        before_wrong_cardinality: preceding_span,
        wrong_cardinality: token.to_string(token),
        wrong_cardinality_span: span,
        hint: Some("TODO: add hint"),
      )
      |> fail

    [] ->
      parse_error.UnexpectedEndOfFile(
        enclosing_definition: Some(enclosing_span),
        context_span: preceding_span,
        context: "the cardinality of this element",
        hint: Some("TODO: add hint"),
      )
      |> fail
  }
}

fn parse_number(
  raw_number: String,
  raw_number_span: Span,
  enclosing_span: Span,
) -> Result(Int, ParseError) {
  int.parse(raw_number)
  |> result.replace_error(parse_error.InternalError(
    enclosing_definition: Some(enclosing_span),
    context_span: raw_number_span,
    context: "This was assumed to be a number",
    hint: Some("TODO: add hint"),
  ))
}

/// Parses a key once the `-*` is found.
/// 
fn parse_key(
  tokens: List(#(Token, Span)),
  entity_span: Span,
  lollipop_span: Span,
) -> ParseResult(Key) {
  do_parse_key(tokens, entity_span, lollipop_span)
}

fn do_parse_key(
  tokens: List(#(Token, Span)),
  entity_span: Span,
  lollipop_span: Span,
) -> ParseResult(Key) {
  case tokens {
    // If there is a multi-item key with an `&` it switches to multi-key
    // parsing.
    [#(Word(key), first_word_span), #(Ampersand, last_ampersand_span), ..tokens] -> {
      use key, tokens <- try(parse_multi_attribute_key(
        tokens,
        entity_span,
        lollipop_span,
        last_ampersand_span,
        first_word_span,
        [key],
      ))
      succeed(key, tokens)
    }

    // If there is a `:` after the key name it switches to parsing a key
    // shorthand for attribute definition.
    [#(Word(key), span), #(Colon, _), ..tokens] -> {
      use type_, tokens <- try(parse_attribute_type(tokens))
      // Here I could try and see if there's a cardinality raise an error,
      // it depends if it is a common mistake or not
      succeed(SingleKey(span, key, Some(type_)), tokens)
    }

    // If there is no `:` and no `&` then it is a key composed of a single
    // element.
    [#(Word(key), span), ..tokens] ->
      succeed(SingleKey(span, key, None), tokens)

    [#(token, span), ..] ->
      parse_error.WrongKeyName(
        enclosing_entity: entity_span,
        lollipop_span: lollipop_span,
        wrong_key: token.to_string(token),
        wrong_key_span: span,
        hint: Some("TODO: add hint"),
      )
      |> fail

    [] ->
      parse_error.UnexpectedEndOfFile(
        enclosing_definition: Some(entity_span),
        context_span: lollipop_span,
        context: "this key",
        hint: Some("TODO: add hint"),
      )
      |> fail
  }
}

/// Parses a multi attribute key once an `&` is found.
/// 
fn parse_multi_attribute_key(
  tokens: List(#(Token, Span)),
  entity_span: Span,
  lollipop_span: Span,
  last_ampersand_span: Span,
  first_word_span: Span,
  keys: List(String),
) -> ParseResult(Key) {
  case tokens {
    // If there is another `&` it keeps going.
    [#(Word(key), _), #(Ampersand, last_ampersand_span), ..tokens] ->
      parse_multi_attribute_key(
        tokens,
        entity_span,
        lollipop_span,
        last_ampersand_span,
        first_word_span,
        [key, ..keys],
      )

    // If there is a `:` it reports an error since a multi-key cannot
    // have a type annotation.
    [#(Word(_), last_word_span), #(Colon, colon_span), ..] ->
      parse_error.TypeAnnotationOnComposedKey(
        enclosing_entity: entity_span,
        keywords_span: span.merge(first_word_span, last_word_span),
        colon_span: colon_span,
        hint: Some("TODO: add hint"),
      )
      |> fail

    // If there is a word not followed by `&` it is done parsing the key.
    [#(Word(key), last_word_span), ..tokens] ->
      span.merge(first_word_span, last_word_span)
      |> ComposedKey(non_empty_list.reverse(non_empty_list.new(key, keys)))
      |> succeed(tokens)

    [#(token, span), ..] ->
      parse_error.IncompleteComposedKey(
        enclosing_entity: entity_span,
        composed_key_span: span.merge(lollipop_span, last_ampersand_span),
        wrong_key: token.to_string(token),
        wrong_key_span: span,
        hint: Some("TODO: add hint"),
      )
      |> fail

    [] ->
      parse_error.UnexpectedEndOfFile(
        enclosing_definition: Some(entity_span),
        context_span: lollipop_span,
        context: "this key",
        hint: Some("TODO: add hint"),
      )
      |> fail
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
                relationship_span,
                entity_span,
              ))
              Relationship(
                relationship_span,
                relationship_name,
                one_entity,
                other_entity,
                attributes,
              )
              |> succeed(tokens)
            }
            // Otherwise return a relationship with no body.
            _ ->
              relationship_span
              |> Relationship(relationship_name, one_entity, other_entity, [])
              |> succeed(tokens)
          }
        }

        [#(token, span), ..] ->
          parse_error.WrongEntityName(
            enclosing_definition: Some(entity_span),
            before_wrong_name: one_cardinality.span,
            wrong_name: token.to_string(token),
            wrong_name_span: span,
            after_what: "the first cardinality annotation",
            hint: Some("TODO: add hint"),
          )
          |> fail

        [] ->
          parse_error.UnexpectedEndOfFile(
            enclosing_definition: Some(entity_span),
            context_span: lollipop_span,
            context: "this relationship",
            hint: Some("TODO: add hint"),
          )
          |> fail
      }
    }

    // If there is no `:` it is reported as an error since a cardinality is
    // always needed.
    [#(Word(_), name_span), ..] ->
      parse_error.MissingCardinalityAnnotation(
        enclosing_definition: entity_span,
        before_span: name_span,
        hint: Some("TODO: add hint"),
      )
      |> fail

    [#(token, span), ..] ->
      parse_error.WrongRelationshipName(
        enclosing_definition: Some(entity_span),
        before_wrong_name: lollipop_span,
        wrong_name: token.to_string(token),
        wrong_name_span: span,
        hint: Some("TODO: add hint"),
      )
      |> fail

    [] ->
      parse_error.UnexpectedEndOfFile(
        enclosing_definition: Some(entity_span),
        context_span: lollipop_span,
        context: "this relationship",
        hint: Some("TODO: add hint"),
      )
      |> fail
  }
}

/// Parses the body of an inner relationship once its `{` is found.
/// 
fn parse_inner_relationship_body(
  tokens: List(#(Token, Span)),
  relationship_span: Span,
  entity_span: Span,
) -> ParseResult(List(Attribute)) {
  do_parse_inner_relationship_body(tokens, relationship_span, entity_span, [])
}

fn do_parse_inner_relationship_body(
  tokens: List(#(Token, Span)),
  relationship_span: Span,
  entity_span: Span,
  attributes: List(Attribute),
) -> ParseResult(List(Attribute)) {
  case tokens {
    // When a `}` is met, ends the parsing and returns the parsed attributes.
    [#(CloseBracket, _), ..tokens] ->
      list.reverse(attributes)
      |> succeed(tokens)

    // When a `-o` is met, switches to parsing an attribute.
    [#(CircleLollipop, span), ..tokens] -> {
      use attribute, tokens <- try(parse_attribute(
        tokens,
        relationship_span,
        span,
      ))
      do_parse_inner_relationship_body(
        tokens,
        relationship_span,
        entity_span,
        [attribute, ..attributes],
      )
    }

    // When a `-*` is found reports an error since a relationship cannot
    // have a key inside.
    [#(StarLollipop, lollipop_span), ..] ->
      parse_error.KeyInsideRelationship(
        enclosing_relationship: relationship_span,
        lollipop_span: lollipop_span,
        hint: Some("TODO: add hint"),
      )
      |> fail

    // If someone writes `- o` it tells them there's possibly
    // a spelling mistake and suggests a fix.
    [#(Minus, minus_span), #(Word("o"), o_span), ..] ->
      parse_error.PossibleCircleLollipopTypo(
        enclosing_definition: relationship_span,
        typo_span: span.merge(minus_span, o_span),
        hint: Some("TODO: add hint"),
      )
      |> fail

    [#(_, token_span), ..] ->
      parse_error.UnexpectedTokenInBinaryRelationship(
        enclosing_relationship: relationship_span,
        token_span: token_span,
        hint: Some("TODO: add hint"),
      )
      |> fail

    [] ->
      parse_error.UnexpectedEndOfFile(
        enclosing_definition: Some(entity_span),
        context_span: relationship_span,
        context: "the body of this relationship",
        hint: Some("TODO: add hint"),
      )
      |> fail
  }
}

/// Parses a hierarchy after finding the `total`/`partial` keyword.
/// 
fn parse_hierarchy(
  tokens: List(#(Token, Span)),
  entity_span: Span,
  totality_span: Span,
  entity_children: Option(Hierarchy),
  totality: Totality,
) -> ParseResult(Hierarchy) {
  case tokens {
    // If the correct overlapping and the `hierarchy` keyword are found,
    // switches to parsing the hierarchy's body.
    [
      #(Word("overlapped" as word), word_span),
      #(Word("hierarchy"), final_span),
      #(OpenBracket, _),
      ..tokens
    ]
    | [
      #(Word("disjoint" as word), word_span),
      #(Word("hierarchy"), final_span),
      #(OpenBracket, _),
      ..tokens
    ] -> {
      let error =
        parse_error.InternalError(
          enclosing_definition: Some(entity_span),
          context_span: word_span,
          context: "A call to `overlapping_from_string` failed despite this being assumed a correct overlapping",
          hint: Some("TODO: add hint"),
        )
      let result = result.replace_error(overlapping_from_string(word), error)
      use overlapping <- result.try(result)

      let hierarchy_span = span.merge(totality_span, final_span)

      // If the entity already has a hierarchy error
      case entity_children {
        Some(first_hierarchy) ->
          parse_error.MoreThanOneHierarchy(
            enclosing_entity: entity_span,
            first_hierarchy_span: first_hierarchy.span,
            other_hierarchy_span: hierarchy_span,
            hint: Some("TODO: add hint"),
          )
          |> fail

        None -> {
          use entities, tokens <- try(parse_hierarchy_body(
            tokens,
            entity_span,
            hierarchy_span,
          ))
          Hierarchy(hierarchy_span, overlapping, totality, entities)
          |> succeed(tokens)
        }
      }
    }

    // If there is no `{`, reports the error since a hierarchy cannot
    // have an empty body.
    [#(Word("overlapped"), _), #(Word("hierarchy"), hierarchy_span), ..]
    | [#(Word("disjoint"), _), #(Word("hierarchy"), hierarchy_span), ..] ->
      parse_error.EmptyHierarchy(
        enclosing_entity: entity_span,
        hierarchy_span: span.merge(totality_span, hierarchy_span),
        hint: Some("TODO: add hint"),
      )
      |> fail

    // If there is the correct overlapping but no `hierarchy` keyword,
    // reports the missing keyword and suggests a fix.
    [#(Word("overlapped"), overlapping_span), ..]
    | [#(Word("disjoint"), overlapping_span), ..] ->
      parse_error.MissingHierarchyKeyword(
        enclosing_entity: entity_span,
        qualifiers_span: span.merge(totality_span, overlapping_span),
        hint: Some("TODO: add hint"),
      )
      |> fail

    [#(token, span), ..] ->
      parse_error.WrongHierarchyOverlapping(
        enclosing_entity: entity_span,
        before_wrong_overlapping: totality_span,
        wrong_overlapping: token.to_string(token),
        wrong_overlapping_span: span,
        hint: Some("TODO: add hint"),
      )
      |> fail

    [] ->
      parse_error.UnexpectedEndOfFile(
        enclosing_definition: Some(entity_span),
        context_span: totality_span,
        context: "this hierarchy",
        hint: Some("TODO: add hint"),
      )
      |> fail
  }
}

/// Parses the body of a hierarchy after finding its `{`.
/// 
fn parse_hierarchy_body(
  tokens: List(#(Token, Span)),
  entity_span: Span,
  hierarchy_span: Span,
) -> ParseResult(NonEmptyList(Entity)) {
  do_parse_hierarchy_body(tokens, [], entity_span, hierarchy_span)
}

fn do_parse_hierarchy_body(
  tokens: List(#(Token, Span)),
  entities: List(Entity),
  entity_span: Span,
  hierarchy_span: Span,
) -> ParseResult(NonEmptyList(Entity)) {
  case tokens {
    // If a `}` is found ends the parsing process. A check is performed to
    // guarantee that there was at least an entity in the hierarchy's body.
    [#(CloseBracket, _), ..tokens] -> {
      let error =
        parse_error.EmptyHierarchy(
          enclosing_entity: entity_span,
          hierarchy_span: hierarchy_span,
          hint: Some("TODO: add hint"),
        )
      entities
      |> list.reverse
      |> non_empty_list.from_list
      |> result.replace_error(error)
      |> result.try(succeed(_, tokens))
    }

    // If the `entity` keyword is found, switches to entity parsing.
    [#(Word("entity"), span), ..tokens] -> {
      use entity, tokens <- try(parse_entity(tokens, span))
      do_parse_hierarchy_body(
        tokens,
        [entity, ..entities],
        entity_span,
        hierarchy_span,
      )
    }

    [#(_, span), ..] ->
      parse_error.UnexpectedTokenInHierarchyBody(
        enclosing_hierarchy: hierarchy_span,
        token_span: span,
        hint: Some("TODO: add hint"),
      )
      |> fail

    [] ->
      parse_error.UnexpectedEndOfFile(
        enclosing_definition: Some(entity_span),
        context_span: hierarchy_span,
        context: "this hierarchy",
        hint: Some("TODO: add hint"),
      )
      |> fail
  }
}

/// Parses a relationship after finding the `relationship` keyword.
/// 
fn parse_relationship(
  tokens: List(#(Token, Span)),
  relationship_keyword_span: Span,
) -> ParseResult(Relationship) {
  case tokens {
    // If there is the name and an `{` switches to parsing the relationship's
    // body.
    [#(Word(relationship_name), relationship_span), #(OpenBracket, _), ..tokens] ->
      parse_relationship_body(tokens, relationship_name, relationship_span)

    // If there is the relationship's name but no `{` reports it as an error
    // since a relationship must always have a body.
    [#(Word(_), name_span), ..] ->
      parse_error.RelationshipBodyWithNoEntities(
        relationship_span: name_span,
        hint: Some("TODO: add hint"),
      )
      |> fail

    [#(token, span), ..] ->
      parse_error.WrongRelationshipName(
        enclosing_definition: None,
        before_wrong_name: relationship_keyword_span,
        wrong_name: token.to_string(token),
        wrong_name_span: span,
        hint: Some("TODO: add hint"),
      )
      |> fail

    [] ->
      parse_error.UnexpectedEndOfFile(
        enclosing_definition: None,
        context_span: relationship_keyword_span,
        context: "this relationship",
        hint: Some("TODO: add hint"),
      )
      |> fail
  }
}

/// Parses the body of a relationship after finding a `{`.
/// 
fn parse_relationship_body(
  tokens: List(#(Token, Span)),
  relationship_name: String,
  name_span: Span,
) -> ParseResult(Relationship) {
  do_parse_relationship_body(tokens, relationship_name, name_span, [], [])
}

fn do_parse_relationship_body(
  tokens: List(#(Token, Span)),
  relationship_name: String,
  relationship_span: Span,
  entities: List(RelationshipEntity),
  attributes: List(Attribute),
) -> ParseResult(Relationship) {
  case tokens {
    // If a `}` is found. Ends the parsing process and returns the parsed
    // relationship.
    [#(CloseBracket, _), ..tokens] ->
      case entities {
        [one_entity, other_entity, ..other_entities] ->
          Relationship(
            relationship_span,
            relationship_name,
            one_entity,
            non_empty_list.new(other_entity, other_entities),
            attributes,
          )
          |> succeed(tokens)

        [one_entity] ->
          parse_error.RelationshipBodyWithJustOneEntity(
            relationship_span: relationship_span,
            relationship_name: relationship_name,
            entity_span: one_entity.span,
            hint: Some("TODO: add hint"),
          )
          |> fail

        [] ->
          parse_error.RelationshipBodyWithNoEntities(
            relationship_span: relationship_span,
            hint: Some("TODO: add hint"),
          )
          |> fail
      }

    // If a `-o` is found, switch to attribute parsing.
    [#(CircleLollipop, lollipop_span), ..tokens] -> {
      use attribute, tokens <- try(parse_attribute(
        tokens,
        relationship_span,
        lollipop_span,
      ))
      do_parse_relationship_body(
        tokens,
        relationship_name,
        relationship_span,
        entities,
        [attribute, ..attributes],
      )
    }

    // If a `->` is found, switch to entity parsing.
    [#(ArrowLollipop, lollipop_span), ..tokens] -> {
      use entity, tokens <- try(parse_relationship_entity(
        tokens,
        relationship_span,
        lollipop_span,
      ))
      do_parse_relationship_body(
        tokens,
        relationship_name,
        relationship_span,
        [entity, ..entities],
        attributes,
      )
    }

    // If a `-*` is found, reports the error since a relationship cannot have
    // a key.
    [#(StarLollipop, lollipop_span), ..] ->
      parse_error.KeyInsideRelationship(
        enclosing_relationship: relationship_span,
        lollipop_span: lollipop_span,
        hint: Some("TODO: add hint"),
      )
      |> fail

    // If someone writes `- o` or `- >` it tells them there's possibly
    // a spelling mistake and suggests a fix.
    [#(Minus, minus_span), #(Word("o"), o_span), ..] ->
      parse_error.PossibleCircleLollipopTypo(
        enclosing_definition: relationship_span,
        typo_span: span.merge(minus_span, o_span),
        hint: Some("TODO: add hint"),
      )
      |> fail

    [#(Minus, minus_span), #(Word(">"), arrow_span), ..] ->
      parse_error.PossibleArrowLollipopTypo(
        enclosing_definition: relationship_span,
        typo_span: span.merge(minus_span, arrow_span),
        hint: Some("TODO: add hint"),
      )
      |> fail

    [#(_, span), ..] ->
      parse_error.UnexpectedTokenInRelationshipBody(
        enclosing_relationship: relationship_span,
        token_span: span,
        hint: Some("TODO: add hint"),
      )
      |> fail

    [] ->
      parse_error.UnexpectedEndOfFile(
        enclosing_definition: None,
        context_span: relationship_span,
        context: "this relationship",
        hint: Some("TODO: add hint"),
      )
      |> fail
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
      RelationshipEntity(name_span, name, cardinality)
      |> succeed(tokens)
    }

    // In case there is no cardinality annotation, reports it as an error
    [#(Word(_), name_span), ..] ->
      parse_error.MissingCardinalityAnnotation(
        enclosing_definition: relationship_span,
        before_span: name_span,
        hint: Some("TODO: add hint"),
      )
      |> fail

    [#(token, span), ..] ->
      parse_error.WrongEntityName(
        enclosing_definition: Some(relationship_span),
        before_wrong_name: lollipop_span,
        wrong_name: token.to_string(token),
        wrong_name_span: span,
        after_what: "the `->` lollipop",
        hint: Some("TODO: add hint"),
      )
      |> fail

    [] ->
      parse_error.UnexpectedEndOfFile(
        enclosing_definition: Some(relationship_span),
        context_span: lollipop_span,
        context: "this entity",
        hint: Some("TODO: add hint"),
      )
      |> fail
  }
}
