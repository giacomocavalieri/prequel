import gleam/string_builder.{StringBuilder}
import prequel/parser.{
  Attribute, Bounded, Cardinality, Entity, Key, Module, Relationship, Unbounded,
}
import gleam/int
import gleam/option.{None}
import gleam/bool
import gleam/list
import non_empty_list

pub fn pretty(module: Module) -> String {
  module.entities
  |> list.map(pretty_entity(_, 0))
  |> string_builder.join(with: "\n\n\n")
  |> string_builder.to_string()
}

fn entity_has_empty_body(entity: Entity) -> Bool {
  case entity.attributes, entity.inner_relationships, entity.children {
    [], [], None -> True
    _, _, _ -> False
  }
}

fn pretty_entity(entity: Entity, indentation: Int) -> StringBuilder {
  let entity_head = string_builder.from_strings(["entity ", entity.name])
  use <- bool.guard(when: entity_has_empty_body(entity), return: entity_head)
  indent(entity_head, by: indentation)
  |> string_builder.append_builder(indent_string(" {\n", by: indentation))
  |> string_builder.append_builder(pretty_entity_body(entity, indentation + 2))
  |> string_builder.append_builder(indent_string("}", by: indentation))
}

fn pretty_entity_body(entity: Entity, indentation: Int) -> StringBuilder {
  let keys =
    entity.keys
    |> list.map(pretty_key(_, indentation))
    |> string_builder.join("\n")
  let attributes =
    entity.attributes
    |> list.map(pretty_attribute(_, indentation))
    |> string_builder.join("\n")
  let inner_relationships =
    entity.inner_relationships
    |> list.map(pretty_inner_relationship(_, entity.name, indentation))
    |> string_builder.join("\n")

  // TODO SEE IF I HAVE TO REMOVE EMPTY STRING BUILDER TO AVOID WHITE LINES
  [keys, attributes, inner_relationships]
  |> list.filter(fn(builder) { !string_builder.is_empty(builder) })
  |> string_builder.join("\n\n")
  |> string_builder.append("\n")
}

fn pretty_key(key: Key, indentation: Int) -> StringBuilder {
  // TODO CHANGE THE AST TO KEEP SHORTHAND KEYS OTHERWISE THE PRINTER NEEDS TO
  // ALWAYS PRINT THE KEY AND ATTRIBUTE!!!!!!!!!!!
  key.attributes
  |> non_empty_list.to_list
  |> list.intersperse(" & ")
  |> string_builder.from_strings
  |> string_builder.prepend_builder(indent_string("-* ", indentation))
}

fn pretty_attribute(attribute: Attribute, indentation: Int) -> StringBuilder {
  let lollipop = indent_string("-o ", indentation)
  case attribute.cardinality {
    Bounded(1, 1) -> string_builder.append(lollipop, attribute.name)
    _ -> {
      lollipop
      |> string_builder.append(attribute.name)
      |> string_builder.append_builder(pretty_cardinality(attribute.cardinality))
    }
  }
}

fn pretty_inner_relationship(
  inner_relationship: Relationship,
  entity_name: String,
  indentation: Int,
) -> StringBuilder {
  // I assume this was parsed correctly!
  // TODO: Maybe I should handle this gracefully in some other way?
  let assert #([outer_entity], [inner_entity]) =
    inner_relationship.entities
    |> list.partition(fn(entity) { entity.name == entity_name })

  let inner_relationship_head =
    indent_string("-> ", indentation)
    |> string_builder.append(inner_relationship.name)
    |> string_builder.append(" : ")
    |> string_builder.append_builder(pretty_cardinality(
      outer_entity.cardinality,
    ))
    |> string_builder.append(" ")
    |> string_builder.append(inner_entity.name)
    |> string_builder.append(" ")
    |> string_builder.append_builder(pretty_cardinality(
      inner_entity.cardinality,
    ))

  case inner_relationship.attributes {
    [] -> inner_relationship_head
    _ ->
      inner_relationship_head
      |> string_builder.append(" {\n")
      |> string_builder.append_builder(
        inner_relationship.attributes
        |> list.map(pretty_attribute(_, indentation + 2))
        |> string_builder.join("\n")
        |> string_builder.append("\n"),
      )
      |> string_builder.append_builder(indent_string("}", by: indentation))
  }
}

fn pretty_cardinality(cardinality: Cardinality) -> StringBuilder {
  case cardinality {
    Bounded(min, max) ->
      string_builder.from_strings([
        "(",
        int.to_string(min),
        "-",
        int.to_string(max),
        ")",
      ])
    Unbounded(min) ->
      string_builder.from_strings(["(", int.to_string(min), "-N)"])
  }
}

fn indent(builder: StringBuilder, by indentation: Int) -> StringBuilder {
  let spaces = string_builder.from_strings(list.repeat(" ", indentation))
  string_builder.append_builder(spaces, builder)
}

fn indent_string(string: String, by indentation: Int) -> StringBuilder {
  indent(string_builder.from_string(string), indentation)
}

fn pretty_relationship(relationship: Relationship) -> StringBuilder {
  string_builder.new()
  |> string_builder.append("relationship")
}
