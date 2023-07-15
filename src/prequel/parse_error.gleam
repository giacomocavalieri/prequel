import prequel/span.{Span}
import gleam/option.{None, Option, Some}
import gleam/string_builder.{StringBuilder}
import gleam_community/ansi
import gleam/string
import gleam/int
import gleam/list
import non_empty_list.{NonEmptyList}
import gleam/pair
import gleam/bool
import gleam/result

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

pub fn context_span(error: ParseError) -> Option(Span) {
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

const error_heading_length = 8

pub type ReportBlock {
  ErrorBlock(pointed: Span, underlined: List(Span), message: String)
  ContextBlock(span: Span)
}

pub fn pretty_report(
  source_code: String,
  blocks: List(ReportBlock),
) -> StringBuilder {
  let source_code_lines =
    string.split(source_code, on: "\n")
    |> list.index_map(fn(index, line) { #(index + 1, line) })

  todo
}

/// Pretty prints an error
/// TODO
/// 
pub fn pretty(
  source_file_name: String,
  source_code: String,
  error: ParseError,
) -> String {
  let source_code_lines =
    source_code
    |> string.split(on: "\n")
    |> list.index_map(fn(index, line) { #(index + 1, line) })

  let error_heading = error_heading(error)
  let file_heading = file_heading(error, source_file_name)
  let context_lines =
    show_context_lines(source_code_lines, error)
    |> option.unwrap(string_builder.new())

  let error_lines =
    show_error_lines(source_code_lines, error)
    |> option.unwrap(string_builder.new())

  [error_heading, file_heading, context_lines, error_lines]
  |> list.filter(fn(sb) { !string_builder.is_empty(sb) })
  |> string_builder.join("\n")
  |> string_builder.to_string
}

/// Returns the lines of the corresponding span.
/// 
fn get_span_lines(
  source_code_lines: List(#(Int, String)),
  span: Span,
) -> List(#(Int, String)) {
  source_code_lines
  |> list.drop(span.line_start - 1)
  |> list.take(span.line_end - span.line_start + 1)
}

/// Given a list of source code lines and an error it returns a `StringBuilder`
/// disaplying the context lines of that error. If the error doesn't have a
/// context to show, an empty optional is returned.
///
fn show_context_lines(
  source_code_lines: List(#(Int, String)),
  error: ParseError,
) -> Option(StringBuilder) {
  use span <- option.map(context_span(error))
  let max_line_digits = count_digits(span.max_line(spans(error)))

  get_span_lines(source_code_lines, span)
  |> list.map(fn(pair) {
    let #(line_number, line) = pair
    let line = show_line(line_number, line, max_line_digits, ContextLine)
    #(line_number, line)
  })
  |> join_lines(max_line_digits)
}

fn show_error_lines(
  source_code_lines: List(#(Int, String)),
  error: ParseError,
) -> StringBuilder {
  let report_lines = report_lines(error)
  show_report_line()
}

/// Joins a list of `StringBuilder`s, one for each line, paired with the number
/// of the corresponding line. If two lines are consecutive they are joined with
/// a newline; otherwise, a dashed empty line is inserted between them.
/// 
fn join_lines(
  lines: List(#(Int, StringBuilder)),
  max_line_digits: Int,
) -> StringBuilder {
  case lines {
    [] -> string_builder.new()
    [first, ..rest] ->
      do_join_lines(non_empty_list.new(first, rest), max_line_digits)
      |> pair.second
  }
}

fn do_join_lines(
  lines: NonEmptyList(#(Int, StringBuilder)),
  max_line_digits: Int,
) -> #(Int, StringBuilder) {
  let padding = string.repeat(" ", max_line_digits + 2)
  let separator = string_builder.from_strings([padding, "┆"])

  use #(last_number, acc), #(number, line) <- list.fold(lines.rest, lines.first)
  let are_consecutive = last_number - 1 == number
  case are_consecutive {
    True -> [acc, line]
    False -> [acc, separator, line]
  }
  |> string_builder.join("\n")
  |> pair.new(number, _)
}

/// The kind of a line to display to toggle different styles.
/// 
type LineKind {
  ErrorLine
  ContextLine
}

/// Displays a line with a number on the left padded to accomodate for
/// at most `max_line_digits`.
/// Based on the kind of line the display style may change: for now, in case the
/// line is an `ErrorLine`, the line number is highlighted in red.
/// 
fn show_line(
  line_number: Int,
  line: String,
  max_line_digits: Int,
  line_kind: LineKind,
) -> StringBuilder {
  let digits = count_digits(line_number)
  let left_padding_size = max_line_digits - digits + 1
  let left_padding = string.repeat(" ", left_padding_size)
  let line_number = case line_kind {
    ErrorLine -> ansi.red(int.to_string(line_number))
    ContextLine -> int.to_string(line_number)
  }

  [left_padding, line_number, " ", "│", " ", line]
  |> string_builder.from_strings
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
fn error_heading(error: ParseError) -> StringBuilder {
  ["[ ", to_code(error), " ] Error: ", pretty_name(error)]
  |> list.map(ansi.red)
  |> string_builder.from_strings
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
/// "     ╭─── foo.pre:1:1
///       │"
/// ```
///
pub fn file_heading(
  error: ParseError,
  source_file_name: String,
) -> StringBuilder {
  let spans = spans(error)

  // Used to display the initial line and column of the error
  let main_span = main_span(error)
  let line_start = int.to_string(main_span.line_start)
  let column_start = int.to_string(main_span.line_end)

  // Compute the left padding needed to correctly align with the line number
  let max_line_digits = count_digits(span.max_line(spans))
  let padding = string.repeat(" ", max_line_digits + 2)

  // Compute the number of dashes needed to correctly align the start of the
  // file name with the end of the error code. This is totally useless and a
  // grand total of 3 people might notice it but it's really satisfying to me :)
  let dash_size = error_heading_length - { max_line_digits + 3 }
  let first_line_dash = string.repeat("─", dash_size)
  let file_name_with_info =
    [source_file_name, ":", line_start, ":", column_start]
    |> string_builder.from_strings
  let first_line =
    [padding, "╭", first_line_dash, " "]
    |> string_builder.from_strings
    |> string_builder.append_builder(file_name_with_info)

  // The vertical dash connecting the error heading to the error body and
  // displayed code. If the code doesn't start from line 1 then a dashed line is
  // used to make it look prettier. Again, maybe 2 people will notice this but
  // if I didn't do it I'd feel bad!
  let vertical_dash = case span.min_line(spans) {
    1 -> "│"
    _ -> "┆"
  }
  let second_line = string_builder.from_strings([padding, vertical_dash])

  [first_line, second_line]
  |> string_builder.join("\n")
}

/// TODO: move to int_extra utils
fn count_digits(n: Int) -> Int {
  let assert Ok(digits) = int.digits(n, 10)
  list.length(digits)
}
