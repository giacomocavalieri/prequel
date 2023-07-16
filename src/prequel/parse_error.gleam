import gleam/option.{None, Option, Some}
import non_empty_list.{NonEmptyList}
import prequel/internals/report
import prequel/span.{Span}

/// TODO: document these errors and when each one makes sense with a little example
pub type ParseError {
  WrongEntityName(
    enclosing_definition: Option(Span),
    before_wrong_name: Span,
    wrong_name: String,
    wrong_name_span: Span,
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
    overlapping_span: Span,
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

  EmptyRelationshipBody(relationship_span: Span, hint: Option(String))

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

/// Given an error, returns its numeric code
fn to_code(error: ParseError) -> String {
  case error {
    WrongEntityName(_, _, _, _, _) -> "E001"
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
    EmptyRelationshipBody(_, _) -> "E021"
    RelationshipBodyWithJustOneEntity(_, _, _, _) -> "E022"
    UnexpectedTokenInRelationshipBody(_, _, _) -> "E023"
    WrongLetterInUnboundedCardinality(_, _, _) -> "E024"
    IncompleteCardinality(_, _, _, _) -> "E025"
    UnexpectedEndOfFile(_, _, _, _) -> "E026"
    UnexpectedTokenInTopLevel(_, _) -> "E027"
    InternalError(_, _, _, _) -> "E028"
  }
}

/// Given an error, returns its pretty name
fn pretty_name(error: ParseError) -> String {
  case error {
    WrongEntityName(_, _, _, _, _) -> "Wrong entity name"
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
    EmptyRelationshipBody(_, _) -> "Empty relationship body"
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

/// Given an error, returns all the spans it contains.
/// 
fn spans(error: ParseError) -> NonEmptyList(Span) {
  case error {
    WrongEntityName(Some(s1), s2, _, s3, _) -> non_empty_list.new(s1, [s2, s3])
    WrongEntityName(None, s2, _, s3, _) -> non_empty_list.new(s2, [s3])
    MoreThanOneHierarchy(s1, s2, s3, _) -> non_empty_list.new(s1, [s2, s3])
    PossibleCircleLollipopTypo(s1, s2, _) -> non_empty_list.new(s1, [s2])
    PossibleStarLollipopTypo(s1, s2, _) -> non_empty_list.new(s1, [s2])
    PossibleArrowLollipopTypo(s1, s2, _) -> non_empty_list.new(s1, [s2])
    WrongOrderOfHierarchyQualifiers(s1, s2, _, _, _) ->
      non_empty_list.new(s1, [s2])
    UnqualifiedHierarchy(s1, s2, _) -> non_empty_list.new(s1, [s2])
    UnexpectedTokenInEntityBody(s1, s2, _) -> non_empty_list.new(s1, [s2])
    WrongAttributeName(s1, s2, _, s3, _) -> non_empty_list.new(s1, [s2, s3])
    WrongCardinalityAnnotation(s1, s2, _, s3, _) ->
      non_empty_list.new(s1, [s2, s3])
    WrongKeyName(s1, s2, _, s3, _) -> non_empty_list.new(s1, [s2, s3])
    TypeAnnotationOnComposedKey(s1, s2, s3, _) ->
      non_empty_list.new(s1, [s2, s3])
    MissingCardinalityAnnotation(s1, s2, _) -> non_empty_list.new(s1, [s2])
    WrongRelationshipName(Some(s1), s2, _, s3, _) ->
      non_empty_list.new(s1, [s2, s3])
    WrongRelationshipName(None, s2, _, s3, _) -> non_empty_list.new(s2, [s3])
    KeyInsideRelationship(s1, s2, _) -> non_empty_list.new(s1, [s2])
    UnexpectedTokenInBinaryRelationship(s1, s2, _) ->
      non_empty_list.new(s1, [s2])
    WrongHierarchyOverlapping(s1, s2, _, s3, _) ->
      non_empty_list.new(s1, [s2, s3])
    MissingHierarchyKeyword(s1, s2, _) -> non_empty_list.new(s1, [s2])
    EmptyHierarchy(s1, s2, _) -> non_empty_list.new(s1, [s2])
    UnexpectedTokenInHierarchyBody(s1, s2, _) -> non_empty_list.new(s1, [s2])
    EmptyRelationshipBody(s1, _) -> non_empty_list.single(s1)
    RelationshipBodyWithJustOneEntity(s1, _, s2, _) ->
      non_empty_list.new(s1, [s2])
    UnexpectedTokenInRelationshipBody(s1, s2, _) -> non_empty_list.new(s1, [s2])
    WrongLetterInUnboundedCardinality(s1, s2, _) -> non_empty_list.new(s1, [s2])
    IncompleteCardinality(s1, s2, _, _) -> non_empty_list.new(s1, [s2])
    UnexpectedEndOfFile(Some(s1), s2, _, _) -> non_empty_list.new(s1, [s2])
    UnexpectedEndOfFile(None, s2, _, _) -> non_empty_list.single(s2)
    UnexpectedTokenInTopLevel(s1, _) -> non_empty_list.single(s1)
    InternalError(Some(s1), s2, _, _) -> non_empty_list.new(s1, [s2])
    InternalError(None, s2, _, _) -> non_empty_list.single(s2)
  }
}

/// Returns the span where the error actually starts; that is, the span relative
/// to the error itself and not the accessory enclosing definition span.
/// 
fn main_span(error: ParseError) -> Span {
  case error {
    WrongEntityName(_, _, _, span, _) -> span
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
    EmptyRelationshipBody(span, _) -> span
    RelationshipBodyWithJustOneEntity(span, _, _, _) -> span
    UnexpectedTokenInRelationshipBody(_, span, _) -> span
    WrongLetterInUnboundedCardinality(_, span, _) -> span
    IncompleteCardinality(_, span, _, _) -> span
    UnexpectedEndOfFile(_, span, _, _) -> span
    UnexpectedTokenInTopLevel(span, _) -> span
    InternalError(_, span, _, _) -> span
  }
}

fn context_span(error: ParseError) -> Option(Span) {
  case error {
    WrongEntityName(span, _, _, _, _) -> span
    MoreThanOneHierarchy(span, _, _, _) -> Some(span)
    PossibleCircleLollipopTypo(span, _, _) -> Some(span)
    PossibleStarLollipopTypo(span, _, _) -> Some(span)
    PossibleArrowLollipopTypo(span, _, _) -> Some(span)
    WrongOrderOfHierarchyQualifiers(span, _, _, _, _) -> Some(span)
    UnqualifiedHierarchy(span, _, _) -> Some(span)
    UnexpectedTokenInEntityBody(span, _, _) -> Some(span)
    WrongAttributeName(span, _, _, _, _) -> Some(span)
    WrongCardinalityAnnotation(span, _, _, _, _) -> Some(span)
    WrongKeyName(span, _, _, _, _) -> Some(span)
    TypeAnnotationOnComposedKey(span, _, _, _) -> Some(span)
    MissingCardinalityAnnotation(span, _, _) -> Some(span)
    WrongRelationshipName(span, _, _, _, _) -> span
    KeyInsideRelationship(span, _, _) -> Some(span)
    UnexpectedTokenInBinaryRelationship(span, _, _) -> Some(span)
    WrongHierarchyOverlapping(span, _, _, _, _) -> Some(span)
    MissingHierarchyKeyword(span, _, _) -> Some(span)
    EmptyHierarchy(span, _, _) -> Some(span)
    UnexpectedTokenInHierarchyBody(span, _, _) -> Some(span)
    EmptyRelationshipBody(span, _) -> Some(span)
    RelationshipBodyWithJustOneEntity(span, _, _, _) -> Some(span)
    UnexpectedTokenInRelationshipBody(span, _, _) -> Some(span)
    WrongLetterInUnboundedCardinality(span, _, _) -> Some(span)
    IncompleteCardinality(span, _, _, _) -> Some(span)
    UnexpectedEndOfFile(span, _, _, _) -> span
    UnexpectedTokenInTopLevel(span, _) -> Some(span)
    InternalError(span, _, _, _) -> span
  }
}

/// Pretty prints an error
/// TODO
/// 
pub fn pretty(
  source_file_name: String,
  source_code: String,
  error: ParseError,
) -> String {
  report.to_string(report.Report(
    source_file_name,
    source_code,
    "Duplicate relationship name",
    "E001",
    1,
    1,
    non_empty_list.new(
      report.ContextBlock(span.new(2, 2, 1, 6)),
      [
        report.ErrorBlock(
          span.new(6, 7, 3, 12),
          option.None,
          //[span.new(5, 5, 2, 2), span.new(7, 7, 14, 16)],
          "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque quis odio a eros tincidunt ullamcorper nec quis tortor. Fusce eu nisl in sapien semper porta ut a enim. Pellentesque a suscipit nisl. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean faucibus sagittis eleifend. Fusce quis lobortis nunc.",
        ),
      ],
    ),
  ))
}
