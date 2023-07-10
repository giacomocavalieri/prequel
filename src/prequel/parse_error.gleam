import prequel/span.{Span}
import gleam/option.{None, Option, Some}
import gleam/string_builder.{StringBuilder}
import gleam_community/ansi
import gleam/string
import gleam/int
import gleam/list
import non_empty_list.{NonEmptyList}
import gleam/pair

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
pub fn to_code(error: ParseError) -> String {
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
pub fn main_span(error: ParseError) -> Span {
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

const error_heading_length = 8

type LineKind {
  ErrorLine
  ContextLine
}

/// Pretty prints an error
/// TODO
/// 
pub fn pretty(
  source_file_name: String,
  source_code: String,
  error: ParseError,
) -> String {
  let error_heading = error_heading(error)
  let spans = spans(error)
  let max_line_digits = count_digits(span.max_line(spans))
  let min_line = span.min_line(spans)
  let main_span = main_span(error)
  let file_heading =
    file_heading(
      source_file_name,
      max_line_digits,
      min_line,
      main_span.line_start,
      main_span.column_start,
    )

  let source_code_lines = string.split(source_code, on: "\n")

  let lines =
    source_code_lines
    |> list.index_map(fn(index, line) { #(index + 1, line) })
    |> list.drop(main_span.line_start - 1)
    |> list.take(main_span.line_end - main_span.line_start + 1)
    |> list.map(fn(pair) {
      let #(line_number, line) = pair
      let line = show_line(line_number, line, max_line_digits, ErrorLine)
      #(line_number, line)
    })
    // Todo better way to merge putting ... if lines are not consecutive
    |> list.map(pair.second)
    |> string_builder.join("\n")

  [error_heading, "\n", file_heading]
  |> string_builder.from_strings
  |> string_builder.append_builder(lines)
  |> string_builder.to_string
}

fn show_line(
  line_number: Int,
  line: String,
  max_line_digits: Int,
  line_kind: LineKind,
) -> StringBuilder {
  let digits = count_digits(line_number)
  let left_padding_size = max_line_digits - digits + 1
  let line_number = case line_kind {
    ErrorLine -> ansi.red(int.to_string(line_number))
    ContextLine -> int.to_string(line_number)
  }

  [string.repeat(" ", left_padding_size), line_number, " │ ", line]
  |> string_builder.from_strings
}

/// TODO: move to int_extra utils
fn count_digits(n: Int) -> Int {
  let assert Ok(digits) = int.digits(n, 10)
  list.length(digits)
}

/// Builds a nice error heading from a given parse error.
/// 
/// ## Examples
/// 
/// ```gleam
/// > error_heading(EmptyHierarchy(...))
/// "[ E019 ] Error: Empty hierarchy"
/// ```
/// 
fn error_heading(error: ParseError) -> String {
  string_builder.from_strings([
    "[ ",
    to_code(error),
    " ] Error: ",
    pretty_name(error),
  ])
  |> string_builder.to_string
  |> ansi.red
}

/// Given a file name and the maximum line to display, builds a file heading.
/// The lenght of the line number is necessary to correctly align the error
/// with any subsequent error line.
/// `starting_line` and `starting_column` are the line and column where the
/// error starts and are displayed in the heading.
/// 
/// ## Examples
/// 
/// ```gleam
/// > file_heading("foo.pre", 3, 1, 1)
/// "     ╭─── foo.pre:1:1"
/// ```
/// 
fn file_heading(
  file_name: String,
  max_line_digits: Int,
  min_line: Int,
  starting_line: Int,
  starting_column: Int,
) -> String {
  let padding = string.repeat(" ", max_line_digits + 1)
  string_builder.from_strings([
    padding,
    " ╭",
    string.repeat("─", error_heading_length - { max_line_digits + 3 }),
    " ",
    file_name,
    ":",
    int.to_string(starting_line),
    ":",
    int.to_string(starting_column),
    "\n",
    padding,
    case min_line {
      1 -> " │\n"
      _ -> " ┆\n"
    },
  ])
  |> string_builder.to_string
}
