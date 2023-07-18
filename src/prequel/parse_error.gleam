import gleam/option.{None, Option, Some}
import non_empty_list.{NonEmptyList}
import prequel/internals/report.{ContextBlock, ErrorBlock, Report, ReportBlock}
import prequel/span.{Span}

/// TODO: document these errors and when each one makes sense with a little example
pub type ParseError {
  WrongEntityName(
    enclosing_definition: Option(Span),
    before_wrong_name: Span,
    wrong_name: String,
    wrong_name_span: Span,
    after_what: String,
    hint: Option(String),
  )

  MoreThanOneHierarchy(
    enclosing_entity: Span,
    first_hierarchy_span: Span,
    other_hierarchy_span: Span,
    hint: Option(String),
  )

  PossibleCircleLollipopTypo(
    enclosing_definition: Span,
    typo_span: Span,
    hint: Option(String),
  )

  PossibleStarLollipopTypo(
    enclosing_definition: Span,
    typo_span: Span,
    hint: Option(String),
  )

  PossibleArrowLollipopTypo(
    enclosing_definition: Span,
    typo_span: Span,
    hint: Option(String),
  )

  WrongOrderOfHierarchyQualifiers(
    enclosing_entity: Span,
    qualifiers_span: Span,
    first_qualifier: String,
    second_qualifier: String,
    hint: Option(String),
  )

  UnqualifiedHierarchy(
    enclosing_entity: Span,
    hierarchy_span: Span,
    hint: Option(String),
  )

  UnexpectedTokenInEntityBody(
    enclosing_entity: Span,
    token_span: Span,
    hint: Option(String),
  )

  WrongAttributeName(
    enclosing_definition: Span,
    lollipop_span: Span,
    wrong_name: String,
    wrong_name_span: Span,
    hint: Option(String),
  )

  WrongCardinalityAnnotation(
    enclosing_definition: Span,
    before_wrong_cardinality: Span,
    wrong_cardinality: String,
    wrong_cardinality_span: Span,
    hint: Option(String),
  )

  WrongKeyName(
    enclosing_entity: Span,
    lollipop_span: Span,
    wrong_key: String,
    wrong_key_span: Span,
    hint: Option(String),
  )

  TypeAnnotationOnComposedKey(
    enclosing_entity: Span,
    key_words_span: Span,
    colon_span: Span,
    hint: Option(String),
  )

  MissingCardinalityAnnotation(
    enclosing_definition: Span,
    before_span: Span,
    hint: Option(String),
  )

  WrongRelationshipName(
    enclosing_definition: Option(Span),
    before_wrong_name: Span,
    wrong_name: String,
    wrong_name_span: Span,
    hint: Option(String),
  )

  KeyInsideRelationship(
    enclosing_relationship: Span,
    lollipop_span: Span,
    hint: Option(String),
  )

  UnexpectedTokenInBinaryRelationship(
    enclosing_relationship: Span,
    token_span: Span,
    hint: Option(String),
  )

  WrongHierarchyOverlapping(
    enclosing_entity: Span,
    before_wrong_overlapping: Span,
    wrong_overlapping: String,
    wrong_overlapping_span: Span,
    hint: Option(String),
  )

  MissingHierarchyKeyword(
    enclosing_entity: Span,
    qualifiers_span: Span,
    hint: Option(String),
  )

  EmptyHierarchy(
    enclosing_entity: Span,
    hierarchy_span: Span,
    hint: Option(String),
  )

  UnexpectedTokenInHierarchyBody(
    enclosing_hierarchy: Span,
    token_span: Span,
    hint: Option(String),
  )

  RelationshipBodyWithNoEntities(relationship_span: Span, hint: Option(String))

  RelationshipBodyWithJustOneEntity(
    relationship_span: Span,
    relationship_name: String,
    entity_span: Span,
    hint: Option(String),
  )

  UnexpectedTokenInRelationshipBody(
    enclosing_relationship: Span,
    token_span: Span,
    hint: Option(String),
  )

  UnexpectedTokenInTopLevel(token_span: Span, hint: Option(String))

  WrongLetterInUnboundedCardinality(
    enclosing_definition: Span,
    wrong_letter_span: Span,
    hint: Option(String),
  )

  IncompleteCardinality(
    enclosing_definition: Span,
    cardinality_span: Span,
    missing: String,
    hint: Option(String),
  )

  UnexpectedEndOfFile(
    enclosing_definition: Option(Span),
    context_span: Span,
    context: String,
    hint: Option(String),
  )

  InternalError(
    enclosing_definition: Option(Span),
    context_span: Span,
    context: String,
    hint: Option(String),
  )
}

pub fn to_pretty_string(
  error: ParseError,
  file_name: String,
  source_code: String,
) -> String {
  report.to_string(to_report(error, file_name, source_code))
}

fn to_report(
  error: ParseError,
  file_name: String,
  source_code: String,
) -> Report {
  let main_span = main_span(error)
  let start = main_span.line_start
  let end = main_span.line_end
  let name = name(of: error)
  let code = code(of: error)
  let blocks = blocks(of: error)
  let hint = Some("foo")
  //error.hint
  Report(file_name, source_code, name, code, start, end, blocks, hint)
}

/// Given an error, returns its code identifier
fn code(of error: ParseError) -> String {
  case error {
    WrongEntityName(_, _, _, _, _, _) -> "E001"
    MoreThanOneHierarchy(_, _, _, _) -> "E002"
    PossibleCircleLollipopTypo(_, _, _) -> "E003"
    PossibleStarLollipopTypo(_, _, _) -> "E004"
    PossibleArrowLollipopTypo(_, _, _) -> "E005"
    WrongOrderOfHierarchyQualifiers(_, _, _, _, _) -> "E006"
    UnqualifiedHierarchy(_, _, _) -> "E007"
    UnexpectedTokenInEntityBody(_, _, _) -> "E008"
    WrongAttributeName(_, _, _, _, _) -> "E009"
    WrongCardinalityAnnotation(_, _, _, _, _) -> "E010"
    WrongKeyName(_, _, _, _, _) -> "E011"
    TypeAnnotationOnComposedKey(_, _, _, _) -> "E012"
    MissingCardinalityAnnotation(_, _, _) -> "E013"
    WrongRelationshipName(_, _, _, _, _) -> "E014"
    KeyInsideRelationship(_, _, _) -> "E015"
    UnexpectedTokenInBinaryRelationship(_, _, _) -> "E016"
    WrongHierarchyOverlapping(_, _, _, _, _) -> "E017"
    MissingHierarchyKeyword(_, _, _) -> "E018"
    EmptyHierarchy(_, _, _) -> "E019"
    UnexpectedTokenInHierarchyBody(_, _, _) -> "E020"
    RelationshipBodyWithNoEntities(_, _) -> "E021"
    RelationshipBodyWithJustOneEntity(_, _, _, _) -> "E022"
    UnexpectedTokenInRelationshipBody(_, _, _) -> "E023"
    WrongLetterInUnboundedCardinality(_, _, _) -> "E024"
    IncompleteCardinality(_, _, _, _) -> "E025"
    UnexpectedEndOfFile(_, _, _, _) -> "E026"
    UnexpectedTokenInTopLevel(_, _) -> "E027"
    InternalError(_, _, _, _) -> "E028"
  }
}

/// Given an error, returns its name
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
  }
}

/// Returns the span where the error actually starts; that is, the span relative
/// to the error itself and not the accessory enclosing definition span.
/// 
fn main_span(error: ParseError) -> Span {
  case error {
    WrongEntityName(_, _, _, span, _, _) -> span
    MoreThanOneHierarchy(_, _, span, _) -> span
    PossibleCircleLollipopTypo(_, span, _) -> span
    PossibleStarLollipopTypo(_, span, _) -> span
    PossibleArrowLollipopTypo(_, span, _) -> span
    WrongOrderOfHierarchyQualifiers(_, span, _, _, _) -> span
    UnqualifiedHierarchy(_, span, _) -> span
    UnexpectedTokenInEntityBody(_, span, _) -> span
    WrongAttributeName(_, _, _, span, _) -> span
    WrongCardinalityAnnotation(_, _, _, span, _) -> span
    WrongKeyName(_, _, _, span, _) -> span
    TypeAnnotationOnComposedKey(_, _, span, _) -> span
    MissingCardinalityAnnotation(_, span, _) -> span
    WrongRelationshipName(_, _, _, span, _) -> span
    KeyInsideRelationship(_, span, _) -> span
    UnexpectedTokenInBinaryRelationship(_, span, _) -> span
    WrongHierarchyOverlapping(_, _, _, span, _) -> span
    MissingHierarchyKeyword(_, span, _) -> span
    EmptyHierarchy(_, span, _) -> span
    UnexpectedTokenInHierarchyBody(_, span, _) -> span
    RelationshipBodyWithNoEntities(span, _) -> span
    RelationshipBodyWithJustOneEntity(span, _, _, _) -> span
    UnexpectedTokenInRelationshipBody(_, span, _) -> span
    WrongLetterInUnboundedCardinality(_, span, _) -> span
    IncompleteCardinality(_, span, _, _) -> span
    UnexpectedEndOfFile(_, span, _, _) -> span
    UnexpectedTokenInTopLevel(span, _) -> span
    InternalError(_, span, _, _) -> span
  }
}

fn blocks(of error: ParseError) -> NonEmptyList(ReportBlock) {
  case error {
    WrongEntityName(Some(context), underlined, _, pointed, _, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(pointed, Some(underlined), message(error))],
      )
    WrongEntityName(None, underlined, _, pointed, _, _) ->
      non_empty_list.single(ErrorBlock(
        pointed,
        Some(underlined),
        message(error),
      ))
    MoreThanOneHierarchy(context, first, second, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(first, None, "a"), ErrorBlock(second, None, "b")],
      )
    PossibleCircleLollipopTypo(context, span, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    PossibleStarLollipopTypo(context, span, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    PossibleArrowLollipopTypo(context, span, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    WrongOrderOfHierarchyQualifiers(context, span, _, _, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    UnqualifiedHierarchy(context, span, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    UnexpectedTokenInEntityBody(context, span, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    WrongAttributeName(context, underlined, _, span, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, Some(underlined), message(error))],
      )
    WrongCardinalityAnnotation(context, underlined, _, span, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, Some(underlined), message(error))],
      )
    WrongKeyName(context, underlined, _, span, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, Some(underlined), message(error))],
      )
    TypeAnnotationOnComposedKey(context, underlined, span, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, Some(underlined), message(error))],
      )
    MissingCardinalityAnnotation(context, span, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    WrongRelationshipName(Some(context), underlined, _, span, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, Some(underlined), message(error))],
      )
    WrongRelationshipName(None, underlined, _, span, _) ->
      non_empty_list.single(ErrorBlock(span, Some(underlined), message(error)))
    KeyInsideRelationship(context, span, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    UnexpectedTokenInBinaryRelationship(context, span, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    WrongHierarchyOverlapping(context, underlined, _, span, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, Some(underlined), message(error))],
      )
    MissingHierarchyKeyword(context, span, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    EmptyHierarchy(context, span, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    UnexpectedTokenInHierarchyBody(context, span, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    RelationshipBodyWithNoEntities(span, _) ->
      non_empty_list.single(ErrorBlock(span, None, message(error)))
    RelationshipBodyWithJustOneEntity(context, _, span, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    UnexpectedTokenInRelationshipBody(context, span, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    WrongLetterInUnboundedCardinality(context, span, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    IncompleteCardinality(context, span, _, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    UnexpectedEndOfFile(Some(context), span, _, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    UnexpectedEndOfFile(None, span, _, _) ->
      non_empty_list.single(ErrorBlock(span, None, message(error)))
    UnexpectedTokenInTopLevel(span, _) ->
      non_empty_list.single(ErrorBlock(span, None, message(error)))
    InternalError(Some(context), span, _, _) ->
      non_empty_list.new(
        ContextBlock(context),
        [ErrorBlock(span, None, message(error))],
      )
    InternalError(None, span, _, _) ->
      non_empty_list.single(ErrorBlock(span, None, message(error)))
  }
}

fn message(error: ParseError) -> String {
  case error {
    WrongEntityName(_, _, wrong_name, _, after_what, _) ->
      "I was expecting to find an entity name after " <> after_what <> " but I ran into `" <> wrong_name <> "`, which is not a valid name"
    MoreThanOneHierarchy(_, _, _, _) -> "todo"
    PossibleCircleLollipopTypo(_, _, _) -> "Did you mean to write `-o` here?"
    PossibleStarLollipopTypo(_, _, _) -> "Did you mean to write `-*` here?"
    PossibleArrowLollipopTypo(_, _, _) -> "Did you mean to write `->` here?"
    WrongOrderOfHierarchyQualifiers(_, _, first, second, _) ->
      "Did you mean to write `" <> second <> " " <> first <> "` here?"
    UnqualifiedHierarchy(_, _, _) ->
      "This hierarchy is missing its totality and overlapping qualifiers"
    UnexpectedTokenInEntityBody(_, _, _) ->
      "I didn't expect to find this token inside an entity's body"
    WrongAttributeName(_, _, name, _, _) ->
      "I was expecting to find an attribute name but I ran into `" <> name <> "`, which is not a valid name"
    WrongCardinalityAnnotation(_, _, wrong_cardinality, _, _) ->
      "I was expecting a cardinality annotation but I ran into `" <> wrong_cardinality <> "`, which is not a valid cardinality"
    WrongKeyName(_, _, name, _, _) ->
      "I was expecting to find a key name but I ran into `" <> name <> "`, which is not a valid name"
    TypeAnnotationOnComposedKey(_, _, _, _) ->
      "A key composed of multiple items cannot have a type or cardinality annotation"
    MissingCardinalityAnnotation(_, _, _) ->
      "I was expecting to find a cardinality annotation after this"
    WrongRelationshipName(_, _, name, _, _) ->
      "I was expecting to find a relationship name but I ran into `" <> name <> "`, which is not a valid name"
    KeyInsideRelationship(_, _, _) ->
      "A relationship cannot contain any keys, did you mean to write `-o` instead?"
    UnexpectedTokenInBinaryRelationship(_, _, _) ->
      "I didn't expect to find this token inside a relationship's body"
    WrongHierarchyOverlapping(_, _, name, _, _) ->
      "I was expecting to find an overlapping qualifier (either `overlapped` or `disjoint`), but I ran into `" <> name <> "`, which is not a valid qualifier"
    MissingHierarchyKeyword(_, _, _) ->
      "I was expecting to find the `hierarchy` keyword after these qualifiers"
    EmptyHierarchy(_, _, _) -> "This hierarchy has an empty body"
    UnexpectedTokenInHierarchyBody(_, _, _) ->
      "I didn't expect to find this token inside a hierarchy's body"
    RelationshipBodyWithNoEntities(_, _) ->
      "This relationship has no entities in its body"
    RelationshipBodyWithJustOneEntity(_, name, _, _) ->
      "This is the only entity taking part into the relationship `" <> name <> "`"
    UnexpectedTokenInRelationshipBody(_, _, _) ->
      "I didn't expect to find this token inside a relationship's body"
    WrongLetterInUnboundedCardinality(_, _, _) ->
      "Did you mean to write `N` as the upper bound of this cardinality?"
    IncompleteCardinality(_, _, what, _) ->
      "This looks like a cardinality annotation but it is missing " <> what
    UnexpectedEndOfFile(_, _, what, _) ->
      "I ran into the end of file halfway through parsing " <> what
    UnexpectedTokenInTopLevel(_, _) -> "I didn't expect to find this token here"
    InternalError(_, _, what, _) -> what
  }
}
