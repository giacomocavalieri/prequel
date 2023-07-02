import prequel/span.{Span}
import gleam/option.{Option}

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

  TypeAnnotationOnMultiItemKey(
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
}

pub fn to_code(error: ParseError) -> Int {
  case error {
    WrongEntityName(_, _, _, _, _) -> 1
    MoreThanOneHierarchy(_, _, _, _) -> 4
    PossibleCircleLollipopTypo(_, _, _) -> 5
    PossibleStarLollipopTypo(_, _, _) -> 6
    PossibleArrowLollipopTypo(_, _, _) -> 7
    WrongOrderOfHierarchyQualifiers(_, _, _, _, _) -> 8
    UnqualifiedHierarchy(_, _, _) -> 9
    UnexpectedTokenInEntityBody(_, _, _) -> 11
    WrongAttributeName(_, _, _, _, _) -> 13
    WrongCardinalityAnnotation(_, _, _, _, _) -> 17
    WrongKeyName(_, _, _, _, _) -> 18
    TypeAnnotationOnMultiItemKey(_, _, _, _) -> 19
    MissingCardinalityAnnotation(_, _, _) -> 22
    WrongRelationshipName(_, _, _, _, _) -> 23
    KeyInsideRelationship(_, _, _) -> 24
    UnexpectedTokenInBinaryRelationship(_, _, _) -> 26
    WrongHierarchyOverlapping(_, _, _, _, _) -> 27
    MissingHierarchyKeyword(_, _, _) -> 28
    EmptyHierarchy(_, _, _) -> 29
  }
}
