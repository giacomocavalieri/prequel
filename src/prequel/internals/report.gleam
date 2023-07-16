import prequel/span.{Span}
import prequel/internals/int_extra
import prequel/internals/string_extra
import gleam/string_builder.{StringBuilder}
import gleam/list
import gleam_community/ansi
import gleam/string
import gleam/int
import non_empty_list.{NonEmptyList}
import gleam/option.{None, Option, Some}

const max_column = 70

const vertical_line = "│"

const horizontal_line = "─"

const vertical_dashed_line = "┆"

const top_left_corner = "╭"

const bottom_left_corner = "╰"

const pointy_underline = "┬"

pub type ReportBlock {
  ContextBlock(span: Span)
  ErrorBlock(pointed: Span, before: Option(Span), message: String)
}

pub type Report {
  Report(
    file_name: String,
    source_code: String,
    error_name: String,
    error_code: String,
    error_line: Int,
    error_column: Int,
    blocks: NonEmptyList(ReportBlock),
  )
}

/// An intermediate representation of a `ReportBlock` that is easier to be
/// joined together and displayed.
/// 
/// The idea behind the error rendering process is the following:
/// - each block is turned into a pretty block that is easier to display
/// - the pretty blocks are joined together two by two to get a nice error
///   message
/// - an error heading is added 
/// - an heading with information about the file and error position is added
/// 
/// To get a getter idea of how each block type is turned into a pretty block
/// you can read the doc of `block_content_to_string`.
/// 
type PrettyBlock {
  PrettyBlock(content: StringBuilder, line_start: Int, line_end: Int)
}

type CodeLines =
  List(#(Int, String))

/// Turns a `Report` into a pretty printed string that displays the report.
/// 
pub fn to_string(report: Report) -> String {
  let error_code_length = string.length(report.error_code)
  let max_line = max_line(report.blocks)
  let min_line = min_line(report.blocks)

  [
    error_heading(report.error_code, report.error_name),
    file_heading(
      report.file_name,
      report.error_line,
      report.error_column,
      max_line,
      error_code_length,
    ),
    connection_from_file_heading_to_blocks(min_line, max_line),
    blocks_to_string_builder(report.source_code, report.blocks, max_line),
  ]
  |> string_builder.join("\n")
  |> string_builder.to_string
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
fn error_heading(error_code: String, error_name: String) -> StringBuilder {
  ["[ ", error_code, " ] Error: ", error_name]
  |> list.map(ansi.red)
  |> string_builder.from_strings
}

/// Returns a builder for the file heading:
/// 
/// ```
///    ╭─── <file_name>:<error_line>:<error_column>
/// ```
/// 
/// `error_code_length` is needed to disaply the error nicely and align it well
/// with the error heading:
/// 
/// ```
/// [ E001 ] Error: asa
///   ^^^^ This is the error_code_length, we use it to make sure
///        that the line before the file name aligns with the last `]`
/// ```
/// 
/// `max_line` is needed to give the heading the correct pad to align it
/// with the report blocks.
/// 
pub fn file_heading(
  file_name: String,
  error_line: Int,
  error_column: Int,
  max_line: Int,
  error_code_length: Int,
) -> StringBuilder {
  let error_line = int.to_string(error_line)
  let error_column = int.to_string(error_column)

  let line_length = error_code_length + 4 - left_pad_size(max_line)
  let line = top_left_corner <> string.repeat(horizontal_line, line_length - 1)

  [left_pad(max_line), line, " ", file_name, ":", error_line, ":", error_column]
  |> string_builder.from_strings
}

/// Draws the vertical connection line that goes from the file heading line to
/// the pretty printed error blocks
/// 
fn connection_from_file_heading_to_blocks(
  min_line: Int,
  max_line: Int,
) -> StringBuilder {
  let vertical_line = case min_line {
    1 -> vertical_line
    _ -> vertical_dashed_line
  }

  [left_pad(max_line), vertical_line]
  |> string_builder.from_strings
}

/// Turns a (non empty) list of blocks into a `StringBuilder` that displays each
/// block's content one after the other.
/// 
fn blocks_to_string_builder(
  source_code: String,
  blocks: NonEmptyList(ReportBlock),
  max_line: Int,
) -> StringBuilder {
  let code_lines =
    string.split(source_code, on: "\n")
    |> list.index_map(fn(index, line) { #(index + 1, line) })

  blocks
  |> non_empty_list.map(to_pretty_block(_, code_lines, max_line))
  |> join_pretty_blocks(max_line)
  |> fn(joined: PrettyBlock) { joined.content }
}

/// Joins together a list of blocks, two by two.
/// 
fn join_pretty_blocks(
  blocks: NonEmptyList(PrettyBlock),
  max_line: Int,
) -> PrettyBlock {
  blocks
  |> non_empty_list.reduce(with: fn(one, other) {
    join_two_pretty_blocks(one, other, max_line)
  })
}

/// Joins two blocks together.
/// Each block (that is a `StringBuilder`) also needs to specify its starting
/// line and ending line so that, when joining adjacent blocks, a vertical line
/// can be used to show some piece of code was omitted.
/// 
/// ## Examples
/// 
/// If one block starts at the next line after the previous one stopped, there
/// is no vertical line as no code was omitted:
/// 
/// ```
/// 1 │ first block
/// 2 │ second block
/// ```
/// 
/// However, if there were some lines between two adjacent blocks, then a dashed
/// line is used to join them:
/// 
/// ```
/// 1 │ first block 
///   ┆
/// 4 │ second block
/// ```
/// 
fn join_two_pretty_blocks(
  one: PrettyBlock,
  other: PrettyBlock,
  max_line: Int,
) -> PrettyBlock {
  let joined =
    case int_extra.comes_before(one.line_end, other.line_start) {
      True -> [one.content, other.content]
      False -> [one.content, dashed_separator(max_line), other.content]
    }
    |> string_builder.join(with: "\n")

  PrettyBlock(joined, one.line_start, other.line_end)
}

/// Turns a `ReportBlock` into a `PrettyBlock`: that is, it turns the block
/// content into a pretty string (a `StringBuilder`) and adds info about the
/// block's starting and ending lines.
/// 
/// This way the block is in a form that can be easily joined using the
/// `join_blocks` function.
/// 
fn to_pretty_block(
  block: ReportBlock,
  code_lines: CodeLines,
  max_line: Int,
) -> PrettyBlock {
  let content = block_content_to_string(code_lines, block, max_line)
  PrettyBlock(content, block_start_line(block), block_end_line(block))
}

/// Turns a block into a pretty `StringBuilder`.
/// The `max_line` is needed to add the correct pad on line numbers, while
/// the source code lines are needed to actually display the code and point to
/// errors in the pretty printed string.
/// 
fn block_content_to_string(
  code_lines: CodeLines,
  block: ReportBlock,
  max_line: Int,
) -> StringBuilder {
  case block {
    ContextBlock(span) -> context_to_string(span, code_lines, max_line)
    ErrorBlock(pointed, underlined, comment) ->
      error_to_string(pointed, underlined, comment, code_lines, max_line)
  }
}

/// Turns the content of a `ContextBlock` into a pretty string.
/// It just takes the context lines and adds the line number before each one.
/// 
fn context_to_string(
  span: Span,
  code_lines: CodeLines,
  max_line: Int,
) -> StringBuilder {
  select_lines_range(from: code_lines, using: span)
  |> list.map(fn(pair) { add_line_number(pair.0, pair.1, max_line) })
  |> string_builder.join(with: "\n")
}

/// This function makes some assumptions to print nice error messages: if
/// pointed is a multiline span, it assumes that there is no nothing else beside
/// whitespace.
/// 
fn error_to_string(
  pointed: Span,
  underlined: Option(Span),
  comment: String,
  code_lines: CodeLines,
  max_line: Int,
) -> StringBuilder {
  case underlined {
    None -> simple_error_to_string(pointed, comment, code_lines, max_line)
    Some(underlined) ->
      error_with_context_to_string(
        pointed,
        underlined,
        comment,
        code_lines,
        max_line,
      )
  }
}

/// Pretty prints an error block where there is just a pointed piece with no
/// other underlined context.
/// 
/// It underlines in red the pointed part and displays an error starting from
/// that point.
/// 
fn simple_error_to_string(
  pointed: Span,
  comment: String,
  code_lines: CodeLines,
  max_line: Int,
) -> StringBuilder {
  todo
}

/// Pretty prints an error block where there is also an underlined piece of
/// context.
/// 
/// It underlines in blue the context piece and underlines in red the pointed
/// part, displaying a message starting from that point.
/// 
fn error_with_context_to_string(
  pointed: Span,
  underlined: Span,
  comment: String,
  code_lines: CodeLines,
  max_line: Int,
) -> StringBuilder {
  todo
}

fn pointed_line(
  pointed: Span,
  underlined_on_same_line: List(Span),
  max_line: Int,
) -> StringBuilder {
  case underlined_on_same_line {
    [] -> todo
    [first, ..rest] -> {
      span.max_column(non_empty_list.new(first, rest))
    }
  }

  string_builder.new()
}

fn pretty_pointed(
  pointed: Span,
  code_lines: CodeLines,
  max_line: Int,
  comment: String,
) -> StringBuilder {
  let lines =
    select_lines_range(from: code_lines, using: pointed)
    |> list.map(fn(pair) { add_line_number(pair.0, pair.1, max_line) })
    |> string_builder.join(with: "\n")

  let underline =
    pointed_underline(
      pointed.column_start,
      pointed.column_end,
      max_line,
      comment,
    )

  [lines, underline]
  |> string_builder.join(with: "\n")
}

fn pointed_underline(
  column_start: Int,
  column_end: Int,
  max_line: Int,
  comment: String,
) -> StringBuilder {
  let underline_size = column_end - column_start + 1
  let underline =
    [
      string.repeat(" ", column_start - 1),
      ansi.red(pointy_underline),
      ansi.red(string.repeat(horizontal_line, underline_size - 1)),
    ]
    |> string_builder.from_strings

  let left_pad = string.repeat(" ", left_pad_size(max_line))
  let prefix =
    [left_pad, vertical_dashed_line, " "]
    |> string_builder.from_strings

  let first_line = string_builder.join([prefix, underline], with: "")
  [first_line, pointed_message(comment, column_start, max_line)]
  |> string_builder.join(with: "\n")
}

fn pointed_message(
  message: String,
  column_start: Int,
  max_line: Int,
) -> StringBuilder {
  let left_pad_size = left_pad_size(max_line)
  let left_pad =
    [string.repeat(" ", left_pad_size), vertical_dashed_line]
    |> string_builder.from_strings
  let inner_pad_size = column_start
  let inner_pad = string_builder.from_string(string.repeat(" ", inner_pad_size))
  let extra_pad = string_builder.from_string(string.repeat(" ", 3))
  let max_line_length = max_column - { left_pad_size + inner_pad_size + 4 }

  let pointer =
    [bottom_left_corner, horizontal_line, " "]
    |> list.map(ansi.red)
    |> string_builder.from_strings
  let first_line_prefix =
    string_builder.join([left_pad, inner_pad, pointer], with: "")
  let lines_prefix =
    string_builder.join([left_pad, inner_pad, extra_pad], with: "")

  let assert [first_line, ..lines] =
    string_extra.chunks_of(message, max_size: max_line_length)
    |> list.map(ansi.red)

  let first_line = string_builder.append(first_line, to: first_line_prefix)
  let lines =
    lines
    |> list.map(fn(line) { string_builder.append(line, to: lines_prefix) })

  [first_line, ..lines]
  |> string_builder.join(with: "\n")
}

/// The size of the pad that needs to be on the left of a vertical line,
/// based on the maximum line number to be displayed.
/// 
/// If the maximum line number is 10, error lines will be displayed like this:
/// 
/// ```
///   9 │ ...
///  10 │ ...
/// ```
/// 
/// So there is a space _before_ and _after_ the line, that is why the pad
/// size is the number of digits in the line + 2 
fn left_pad_size(max_line: Int) -> Int {
  let max_line_digits = int_extra.count_digits(max_line)
  max_line_digits + 2
}

/// The whitespace-only pad string used on the left of the vertical line
/// separating code from line numbers.
/// 
fn left_pad(max_line: Int) -> String {
  string.repeat(" ", left_pad_size(max_line))
}

/// Returns the vertical dashed line with the correct pad prepended.
/// 
/// ## Examples
/// 
/// ```gleam
/// > dashed_separator(11) |> string_builder.to_string
/// "   ┆"
/// ```
/// 
/// ```gleam
/// > dashed_separator(5) |> string_builder.to_string
/// "  ┆"
/// ```
/// 
fn dashed_separator(max_line: Int) -> StringBuilder {
  string_builder.from_strings([left_pad(max_line), vertical_dashed_line])
}

/// Adds the line number and a vertical line to the left of the given line.
/// `max_line` is used to properly pad the line number aligning it with other
/// line numbers in report blocks.
/// 
/// ## Examples
/// 
/// ```gleam
/// > add_line_number(2, "foo", 20) |> string_builder.to_string
/// "  2 │ foo"
/// ```
/// 
/// ```gleam
/// > add_line_number(11, "foo", 25) |> string_builder.to_string
/// " 11 │ foo"
/// ```
/// 
fn add_line_number(
  line_number: Int,
  to line: String,
  with max_line: Int,
) -> StringBuilder {
  let max_line_digits = int_extra.count_digits(max_line)
  let line_digits = int_extra.count_digits(line_number)
  let left_pad_size = max_line_digits + 2 - line_digits - 1
  let left_pad = string.repeat(" ", left_pad_size)

  [left_pad, int.to_string(line_number), " ", vertical_line, " ", line]
  |> string_builder.from_strings
}

/// Returns the greatest line found in a list of `ReportBlock`s.
/// 
fn max_line(blocks: NonEmptyList(ReportBlock)) -> Int {
  blocks
  |> non_empty_list.flat_map(block_to_spans)
  |> non_empty_list.flat_map(span.lines)
  |> non_empty_list.reduce(with: int.max)
}

/// Returns the smallest line found in a list of `ReportBlock`s.
/// 
fn min_line(blocks: NonEmptyList(ReportBlock)) -> Int {
  blocks
  |> non_empty_list.flat_map(block_to_spans)
  |> non_empty_list.flat_map(span.lines)
  |> non_empty_list.reduce(with: int.min)
}

/// Given a `ReportBlock`, returns all the spans it contains.
/// 
fn block_to_spans(block: ReportBlock) -> NonEmptyList(Span) {
  case block {
    ContextBlock(span) -> non_empty_list.single(span)
    ErrorBlock(span, context, _) ->
      case context {
        Some(context_span) -> non_empty_list.new(span, [context_span])
        None -> non_empty_list.single(span)
      }
  }
}

fn select_lines_range(from code_lines: CodeLines, using span: Span) -> CodeLines {
  code_lines
  |> list.drop(span.line_start - 1)
  |> list.take(span.line_end - span.line_start + 1)
}

fn block_start_line(block: ReportBlock) -> Int {
  min_line(non_empty_list.single(block))
}

fn block_end_line(block: ReportBlock) -> Int {
  max_line(non_empty_list.single(block))
}
