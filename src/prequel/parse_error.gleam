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

pub fn to_code(error: ParseError) -> String {
  case error {
    WrongEntityName(_, _, _, _, _) -> "001"
    MoreThanOneHierarchy(_, _, _, _) -> "002"
    PossibleCircleLollipopTypo(_, _, _) -> "003"
    PossibleStarLollipopTypo(_, _, _) -> "004"
    PossibleArrowLollipopTypo(_, _, _) -> "005"
    WrongOrderOfHierarchyQualifiers(_, _, _, _, _) -> "006"
    UnqualifiedHierarchy(_, _, _) -> "007"
    UnexpectedTokenInEntityBody(_, _, _) -> "008"
    WrongAttributeName(_, _, _, _, _) -> "009"
    WrongCardinalityAnnotation(_, _, _, _, _) -> "010"
    WrongKeyName(_, _, _, _, _) -> "011"
    TypeAnnotationOnMultiItemKey(_, _, _, _) -> "012"
    MissingCardinalityAnnotation(_, _, _) -> "013"
    WrongRelationshipName(_, _, _, _, _) -> "014"
    KeyInsideRelationship(_, _, _) -> "015"
    UnexpectedTokenInBinaryRelationship(_, _, _) -> "016"
    WrongHierarchyOverlapping(_, _, _, _, _) -> "017"
    MissingHierarchyKeyword(_, _, _) -> "018"
    EmptyHierarchy(_, _, _) -> "019"
    UnexpectedTokenInHierarchyBody(_, _, _) -> "020"
    EmptyRelationshipBody(_, _) -> "021"
    RelationshipBodyWithJustOneEntity(_, _, _, _) -> "022"
    UnexpectedTokenInRelationshipBody(_, _, _) -> "023"
    WrongLetterInUnboundedCardinality(_, _, _) -> "024"
    IncompleteCardinality(_, _, _, _) -> "025"
    UnexpectedEndOfFile(_, _, _, _) -> "026"
    UnexpectedTokenInTopLevel(_, _) -> "027"
    InternalError(_, _, _, _) -> "028"
  }
}
