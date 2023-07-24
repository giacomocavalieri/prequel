import gleam/option.{None, Option, Some}
import non_empty_list.{NonEmptyList}
import prequel/internals/report.{ContextBlock, ErrorBlock, Report, ReportBlock}
import prequel/span.{Span}

/// TODO: document these errors and when each one makes sense with a little example
pub type ParseError {
  WrongEntityName(
    hint: Option(String),
    enclosing_definition: Option(Span),
    before_wrong_name: Span,
    wrong_name: String,
    wrong_name_span: Span,
    after_what: String,
  )

  MoreThanOneHierarchy(
    hint: Option(String),
    enclosing_entity: Span,
    first_hierarchy_span: Span,
    other_hierarchy_span: Span,
  )

  PossibleCircleLollipopTypo(
    hint: Option(String),
    enclosing_definition: Span,
    typo_span: Span,
  )

  PossibleStarLollipopTypo(
    hint: Option(String),
    enclosing_definition: Span,
    typo_span: Span,
  )

  PossibleArrowLollipopTypo(
    hint: Option(String),
    enclosing_definition: Span,
    typo_span: Span,
  )

  WrongOrderOfHierarchyQualifiers(
    hint: Option(String),
    enclosing_entity: Span,
    qualifiers_span: Span,
    first_qualifier: String,
    second_qualifier: String,
  )

  UnqualifiedHierarchy(
    hint: Option(String),
    enclosing_entity: Span,
    hierarchy_span: Span,
  )

  UnexpectedTokenInEntityBody(
    hint: Option(String),
    enclosing_entity: Span,
    token_span: Span,
  )

  WrongAttributeName(
    hint: Option(String),
    enclosing_definition: Span,
    lollipop_span: Span,
    wrong_name: String,
    wrong_name_span: Span,
  )

  WrongCardinalityAnnotation(
    hint: Option(String),
    enclosing_definition: Span,
    before_wrong_cardinality: Span,
    wrong_cardinality: String,
    wrong_cardinality_span: Span,
  )

  WrongKeyName(
    hint: Option(String),
    enclosing_entity: Span,
    lollipop_span: Span,
    wrong_key: String,
    wrong_key_span: Span,
  )

  TypeAnnotationOnComposedKey(
    hint: Option(String),
    enclosing_entity: Span,
    keywords_span: Span,
    colon_span: Span,
  )

  MissingCardinalityAnnotation(
    hint: Option(String),
    enclosing_definition: Span,
    before_span: Span,
  )

  WrongRelationshipName(
    hint: Option(String),
    enclosing_definition: Option(Span),
    before_wrong_name: Span,
    wrong_name: String,
    wrong_name_span: Span,
  )

  KeyInsideRelationship(
    hint: Option(String),
    enclosing_relationship: Span,
    lollipop_span: Span,
  )

  UnexpectedTokenInBinaryRelationship(
    hint: Option(String),
    enclosing_relationship: Span,
    token_span: Span,
  )

  WrongHierarchyOverlapping(
    hint: Option(String),
    enclosing_entity: Span,
    before_wrong_overlapping: Span,
    wrong_overlapping: String,
    wrong_overlapping_span: Span,
  )

  MissingHierarchyKeyword(
    hint: Option(String),
    enclosing_entity: Span,
    qualifiers_span: Span,
  )

  EmptyHierarchy(
    hint: Option(String),
    enclosing_entity: Span,
    hierarchy_span: Span,
  )

  UnexpectedTokenInHierarchyBody(
    hint: Option(String),
    enclosing_hierarchy: Span,
    token_span: Span,
  )

  RelationshipBodyWithNoEntities(hint: Option(String), relationship_span: Span)

  RelationshipBodyWithJustOneEntity(
    hint: Option(String),
    relationship_span: Span,
    relationship_name: String,
    entity_span: Span,
  )

  UnexpectedTokenInRelationshipBody(
    hint: Option(String),
    enclosing_relationship: Span,
    token_span: Span,
  )

  UnexpectedTokenInTopLevel(hint: Option(String), token_span: Span)

  WrongLetterInUnboundedCardinality(
    hint: Option(String),
    enclosing_definition: Span,
    wrong_letter_span: Span,
  )

  IncompleteCardinality(
    hint: Option(String),
    enclosing_definition: Span,
    cardinality_span: Span,
    missing: String,
  )

  UnexpectedEndOfFile(
    hint: Option(String),
    enclosing_definition: Option(Span),
    context_span: Span,
    context: String,
  )

  InternalError(
    hint: Option(String),
    enclosing_definition: Option(Span),
    context_span: Span,
    context: String,
  )

  IncompleteComposedKey(
    hint: Option(String),
    composed_key_span: Span,
    enclosing_entity: Span,
    wrong_key: String,
    wrong_key_span: Span,
  )
}

pub fn to_report(
  error: ParseError,
  file_name: String,
  source_code: String,
) -> Report {
  let main_span = main_span(error)
  let line = main_span.start_line
  let column = main_span.start_column
  let name = name(of: error)
  let code = code(of: error)
  let blocks = blocks(of: error)
  Report(file_name, source_code, name, code, line, column, blocks, error.hint)
}

/// Given an error, returns its code identifier.
/// 
fn code(of error: ParseError) -> String {
  case error {
    // TODO REWRITE EVERYTHING WITH NICE PATTERN MATCHING YOU DUMMY!
    // https://exercism.org/tracks/gleam/concepts/labelled-fields
    WrongEntityName(..) -> "PE001"
    MoreThanOneHierarchy(_, _, _, _) -> "PE002"
    PossibleCircleLollipopTypo(_, _, _) -> "PE003"
    PossibleStarLollipopTypo(_, _, _) -> "PE004"
    PossibleArrowLollipopTypo(_, _, _) -> "PE005"
    WrongOrderOfHierarchyQualifiers(_, _, _, _, _) -> "PE006"
    UnqualifiedHierarchy(_, _, _) -> "PE007"
    UnexpectedTokenInEntityBody(_, _, _) -> "PE008"
    WrongAttributeName(_, _, _, _, _) -> "PE009"
    WrongCardinalityAnnotation(_, _, _, _, _) -> "PE010"
    WrongKeyName(_, _, _, _, _) -> "PE011"
    TypeAnnotationOnComposedKey(_, _, _, _) -> "PE012"
    MissingCardinalityAnnotation(_, _, _) -> "PE013"
    WrongRelationshipName(_, _, _, _, _) -> "PE014"
    KeyInsideRelationship(_, _, _) -> "PE015"
    UnexpectedTokenInBinaryRelationship(_, _, _) -> "PE016"
    WrongHierarchyOverlapping(_, _, _, _, _) -> "PE017"
    MissingHierarchyKeyword(_, _, _) -> "PE018"
    EmptyHierarchy(_, _, _) -> "PE019"
    UnexpectedTokenInHierarchyBody(_, _, _) -> "PE020"
    RelationshipBodyWithNoEntities(_, _) -> "PE021"
    RelationshipBodyWithJustOneEntity(_, _, _, _) -> "PE022"
    UnexpectedTokenInRelationshipBody(_, _, _) -> "PE023"
    WrongLetterInUnboundedCardinality(_, _, _) -> "PE024"
    IncompleteCardinality(_, _, _, _) -> "PE025"
    UnexpectedEndOfFile(_, _, _, _) -> "PE026"
    UnexpectedTokenInTopLevel(_, _) -> "PE027"
    InternalError(_, _, _, _) -> "PE028"
    IncompleteComposedKey(_, _, _, _, _) -> "PE029"
  }
}

/// Given an error, returns its name.
/// 
fn name(of error: ParseError) -> String {
  case error {
    WrongEntityName(_, _, _, _, _, _) -> "Wrong entity name"
    MoreThanOneHierarchy(_, _, _, _) -> "More than one hierarchy"
    PossibleCircleLollipopTypo(_, _, _) -> "Circle lollipop typo"
    PossibleStarLollipopTypo(_, _, _) -> "Star lollipop typo"
    PossibleArrowLollipopTypo(_, _, _) -> "Arrow lollipop typo"
    WrongOrderOfHierarchyQualifiers(_, _, _, _, _) ->
      "Wrong order of hierarchy qualifiers"
    UnqualifiedHierarchy(_, _, _) -> "Unqualified hierarchy"
    UnexpectedTokenInEntityBody(_, _, _) -> "Unexpected token in entity body"
    WrongAttributeName(_, _, _, _, _) -> "Wrong attribute name"
    WrongCardinalityAnnotation(_, _, _, _, _) -> "Wrong cardinality annotation"
    WrongKeyName(_, _, _, _, _) -> "Wrong key name"
    TypeAnnotationOnComposedKey(_, _, _, _) -> "Type annotation on composed key"
    MissingCardinalityAnnotation(_, _, _) -> "Missing cardinality annotation"
    WrongRelationshipName(_, _, _, _, _) -> "Wrong relationship name"
    KeyInsideRelationship(_, _, _) -> "Key inside relationship"
    UnexpectedTokenInBinaryRelationship(_, _, _) ->
      "Unexpected token in binary relationship"
    WrongHierarchyOverlapping(_, _, _, _, _) -> "Wrong hierarchy overlapping"
    MissingHierarchyKeyword(_, _, _) -> "Missing hierarchy keyword"
    EmptyHierarchy(_, _, _) -> "Empty hierarchy"
    UnexpectedTokenInHierarchyBody(_, _, _) ->
      "Unexpected token in hierarchy body"
    RelationshipBodyWithNoEntities(_, _) -> "Relationship body with no entities"
    RelationshipBodyWithJustOneEntity(_, _, _, _) ->
      "Relatinoship body with just one entity"
    UnexpectedTokenInRelationshipBody(_, _, _) ->
      "Unexpected token in relationship body"
    WrongLetterInUnboundedCardinality(_, _, _) ->
      "Wrong letter in unbounded cardinality"
    IncompleteCardinality(_, _, _, _) -> "Incomplete cardinality"
    UnexpectedEndOfFile(_, _, _, _) -> "Unexpected end of file"
    UnexpectedTokenInTopLevel(_, _) -> "Unexpected token"
    InternalError(_, _, _, _) -> "Internal error"
    IncompleteComposedKey(_, _, _, _, _) -> "Incomplete composed key"
  }
}

/// Returns the span where the error actually starts; that is, the span relative
/// to the error itself and not the accessory enclosing definition span.
/// 
fn main_span(error: ParseError) -> Span {
  case error {
    WrongEntityName(_, _, _, _, span, _) -> span
    MoreThanOneHierarchy(_, _, _, span) -> span
    PossibleCircleLollipopTypo(_, _, span) -> span
    PossibleStarLollipopTypo(_, _, span) -> span
    PossibleArrowLollipopTypo(_, _, span) -> span
    WrongOrderOfHierarchyQualifiers(_, _, span, _, _) -> span
    UnqualifiedHierarchy(_, _, span) -> span
    UnexpectedTokenInEntityBody(_, _, span) -> span
    WrongAttributeName(_, _, _, _, span) -> span
    WrongCardinalityAnnotation(_, _, _, _, span) -> span
    WrongKeyName(_, _, _, _, span) -> span
    TypeAnnotationOnComposedKey(_, _, _, span) -> span
    MissingCardinalityAnnotation(_, _, span) -> span
    WrongRelationshipName(_, _, _, _, span) -> span
    KeyInsideRelationship(_, _, span) -> span
    UnexpectedTokenInBinaryRelationship(_, _, span) -> span
    WrongHierarchyOverlapping(_, _, _, _, span) -> span
    MissingHierarchyKeyword(_, _, span) -> span
    EmptyHierarchy(_, _, span) -> span
    UnexpectedTokenInHierarchyBody(_, _, span) -> span
    RelationshipBodyWithNoEntities(_, span) -> span
    RelationshipBodyWithJustOneEntity(_, span, _, _) -> span
    UnexpectedTokenInRelationshipBody(_, _, span) -> span
    WrongLetterInUnboundedCardinality(_, _, span) -> span
    IncompleteCardinality(_, _, span, _) -> span
    UnexpectedEndOfFile(_, _, span, _) -> span
    UnexpectedTokenInTopLevel(_, span) -> span
    InternalError(_, _, span, _) -> span
    IncompleteComposedKey(_, _, _, _, span) -> span
  }
}

fn blocks(of error: ParseError) -> NonEmptyList(ReportBlock) {
  case error {
    WrongEntityName(_, Some(context), underlined, _, pointed, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(pointed, Some(underlined), message(error))],
      )
    WrongEntityName(_, None, underlined, _, pointed, _) ->
      non_empty_list.single(ErrorBlock(
        pointed,
        Some(underlined),
        message(error),
      ))
    MoreThanOneHierarchy(_, context, first, second) ->
      non_empty_list.new(
        ContextBlock(context),
        [
          ErrorBlock(first, None, message(error)),
          ErrorBlock(
            second,
            None,
            "...and here's another one. Maybe you could merge those together?",
          ),
        ],
      )
    PossibleCircleLollipopTypo(_, context, span) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    PossibleStarLollipopTypo(_, context, span) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    PossibleArrowLollipopTypo(_, context, span) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    WrongOrderOfHierarchyQualifiers(_, context, span, _, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    UnqualifiedHierarchy(_, context, span) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    UnexpectedTokenInEntityBody(_, context, span) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    WrongAttributeName(_, context, underlined, _, span) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, Some(underlined), message(error))],
      )
    WrongCardinalityAnnotation(_, context, underlined, _, span) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, Some(underlined), message(error))],
      )
    WrongKeyName(_, context, underlined, _, span) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, Some(underlined), message(error))],
      )
    TypeAnnotationOnComposedKey(_, context, underlined, span) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, Some(underlined), message(error))],
      )
    MissingCardinalityAnnotation(_, context, span) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    WrongRelationshipName(_, Some(context), underlined, _, span) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, Some(underlined), message(error))],
      )
    WrongRelationshipName(_, None, underlined, _, span) ->
      non_empty_list.single(ErrorBlock(span, Some(underlined), message(error)))
    KeyInsideRelationship(_, context, span) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    UnexpectedTokenInBinaryRelationship(_, context, span) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    WrongHierarchyOverlapping(_, context, underlined, _, span) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, Some(underlined), message(error))],
      )
    MissingHierarchyKeyword(_, context, span) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    EmptyHierarchy(_, context, span) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    UnexpectedTokenInHierarchyBody(_, context, span) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    RelationshipBodyWithNoEntities(_, span) ->
      non_empty_list.single(ErrorBlock(span, None, message(error)))
    RelationshipBodyWithJustOneEntity(_, context, _, span) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    UnexpectedTokenInRelationshipBody(_, context, span) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    WrongLetterInUnboundedCardinality(_, context, span) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    IncompleteCardinality(_, context, span, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    UnexpectedEndOfFile(_, Some(context), span, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    UnexpectedEndOfFile(_, None, span, _) ->
      non_empty_list.single(ErrorBlock(span, None, message(error)))
    UnexpectedTokenInTopLevel(_, span) ->
      non_empty_list.single(ErrorBlock(span, None, message(error)))
    InternalError(_, Some(context), span, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    InternalError(_, None, span, _) ->
      non_empty_list.single(ErrorBlock(span, None, message(error)))
    IncompleteComposedKey(
      _,
      composed_key_span,
      enclosing_entity,
      _,
      wrong_key_span,
    ) ->
      non_empty_list.new(
        ContextBlock(enclosing_entity),
        [ErrorBlock(wrong_key_span, Some(composed_key_span), message(error))],
      )
  }
}

fn message(error: ParseError) -> String {
  case error {
    WrongEntityName(_, _, _, wrong_name, _, after_what) ->
      "I was expecting to find an entity name after " <> after_what <> " but I ran into `" <> wrong_name <> "`, which is not a valid name"
    MoreThanOneHierarchy(_, _, _, _) ->
      "An entity can only be the root of one hierarchy. Here is the first one..."
    PossibleCircleLollipopTypo(_, _, _) -> "Did you mean to write `-o` here?"
    PossibleStarLollipopTypo(_, _, _) -> "Did you mean to write `-*` here?"
    PossibleArrowLollipopTypo(_, _, _) -> "Did you mean to write `->` here?"
    WrongOrderOfHierarchyQualifiers(_, _, _, first, second) ->
      "Did you mean to write `" <> second <> " " <> first <> "` here?"
    UnqualifiedHierarchy(_, _, _) ->
      "This hierarchy is missing its totality and overlapping qualifiers"
    UnexpectedTokenInEntityBody(_, _, _) ->
      "I didn't expect to find this token inside an entity's body"
    WrongAttributeName(_, _, _, name, _) ->
      "I was expecting to find an attribute name but I ran into `" <> name <> "`, which is not a valid name"
    WrongCardinalityAnnotation(_, _, _, wrong_cardinality, _) ->
      "I was expecting a cardinality annotation but I ran into `" <> wrong_cardinality <> "`, which is not a valid cardinality"
    WrongKeyName(_, _, _, name, _) ->
      "I was expecting to find a key name but I ran into `" <> name <> "`, which is not a valid name"
    TypeAnnotationOnComposedKey(_, _, _, _) ->
      "A key composed of multiple items cannot have a type or cardinality annotation"
    MissingCardinalityAnnotation(_, _, _) ->
      "I was expecting to find a cardinality annotation after this"
    WrongRelationshipName(_, _, _, name, _) ->
      "I was expecting to find a relationship name but I ran into `" <> name <> "`, which is not a valid name"
    KeyInsideRelationship(_, _, _) ->
      "A relationship cannot contain any keys, did you mean to write `-o` instead?"
    UnexpectedTokenInBinaryRelationship(_, _, _) ->
      "I didn't expect to find this token inside a relationship's body"
    WrongHierarchyOverlapping(_, _, _, name, _) ->
      "I was expecting to find an overlapping qualifier (either `overlapped` or `disjoint`), but I ran into `" <> name <> "`, which is not a valid qualifier"
    MissingHierarchyKeyword(_, _, _) ->
      "I was expecting to find the `hierarchy` keyword after these qualifiers"
    EmptyHierarchy(_, _, _) -> "This hierarchy has an empty body"
    UnexpectedTokenInHierarchyBody(_, _, _) ->
      "I didn't expect to find this token inside a hierarchy's body"
    RelationshipBodyWithNoEntities(_, _) ->
      "This relationship has no entities in its body"
    RelationshipBodyWithJustOneEntity(_, _, name, _) ->
      "This is the only entity taking part into the relationship `" <> name <> "`"
    UnexpectedTokenInRelationshipBody(_, _, _) ->
      "I didn't expect to find this token inside a relationship's body"
    WrongLetterInUnboundedCardinality(_, _, _) ->
      "Did you mean to write `N` as the upper bound of this cardinality?"
    IncompleteCardinality(_, _, _, what) ->
      "This looks like a cardinality annotation but it is missing " <> what
    UnexpectedEndOfFile(_, _, _, what) ->
      "I ran into the end of file halfway through parsing " <> what
    UnexpectedTokenInTopLevel(_, _) -> "I didn't expect to find this token here"
    InternalError(_, _, _, what) -> what
    IncompleteComposedKey(_, _, _, wrong_key, _) -> "foo " <> wrong_key
  }
}
