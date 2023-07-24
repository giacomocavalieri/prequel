import gleam/int
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/pair
import non_empty_list.{NonEmptyList}
import prequel/ast.{
  Attribute, Bounded, Cardinality, Entity, Hierarchy, Module, Relationship,
  RelationshipEntity, Unbounded,
}
import prequel/internals/extra/list as list_extra
import prequel/span.{Span}
import prequel/error/validation_error.{ValidationError}

/// Validates a module and returns a list of all the errors found.
/// 
pub fn check_module(module: Module) -> List(ValidationError) {
  [
    check_cardinalities_bounds,
    check_all_entities_have_different_names,
    check_all_relationships_have_different_names,
  ]
  |> gather_errors(from: module)
}

/// Given a list of validation steps (functions from module to a list of
/// errors), and a module, returns all the errors found by the different steps.
/// 
fn gather_errors(
  using validation_steps: List(fn(Module) -> List(ValidationError)),
  from module: Module,
) -> List(ValidationError) {
  list.flat_map(validation_steps, fn(validate) { validate(module) })
}

/// Validates that every cardinality inside a module has its lower bound lower
/// than the upper bound. Any wrong cardinality is reported in the resulting
/// list.
/// 
fn check_cardinalities_bounds(module: Module) -> List(ValidationError) {
  cardinalities_from_module(module)
  |> list_extra.map_pairs(check_cardinality_bounds)
  |> option.values
}

/// Given a module returns all the cardinalities that are declared in it.
/// Each cardinality is also paired with the span of the enclosing entity to
/// make error reporting easier.
/// 
fn cardinalities_from_module(module: Module) -> List(#(Span, Cardinality)) {
  [
    list.flat_map(module.entities, cardinalities_from_entity),
    list.flat_map(module.relationships, cardinalities_from_relationship),
  ]
  |> list.concat
}

/// Gets all the cardinalities declared inside a relationship.
/// 
fn cardinalities_from_relationship(
  relationship: Relationship,
) -> List(#(Span, Cardinality)) {
  let Relationship(span, _, entity, entities, attributes) = relationship
  let inner_entities = [entity, ..non_empty_list.to_list(entities)]
  let cardinality_from_inner_entities = fn(entity: RelationshipEntity) {
    entity.cardinality
  }

  [
    list.map(attributes, cardinality_from_attribute),
    list.map(inner_entities, cardinality_from_inner_entities),
  ]
  |> list.concat
  |> list.map(fn(cardinality) { #(span, cardinality) })
}

/// Gets all the cardinalities declared inside an entity.
/// 
fn cardinalities_from_entity(entity: Entity) -> List(#(Span, Cardinality)) {
  let Entity(span, _, _, attributes, inner_relationships, children) = entity
  // We take the cardinalities from the inner relationships and use the
  // entity as the enclosing definition instead of the inner relatinpship
  // itself.
  let inner_relationship_cardinalities =
    list.flat_map(inner_relationships, cardinalities_from_relationship)
    |> list.map(fn(pair) { #(entity.span, pair.1) })

  let children_cardinalities = case children {
    None -> []
    Some(Hierarchy(_, _, _, children)) ->
      non_empty_list.to_list(children)
      |> list.flat_map(cardinalities_from_entity)
  }

  [list.map(attributes, cardinality_from_attribute)]
  |> list.concat
  |> list.map(fn(cardinality) { #(span, cardinality) })
  |> list.append(inner_relationship_cardinalities)
  |> list.append(children_cardinalities)
}

/// Gets the cardinality (maybe more in the future) declared inside an
/// attribute.
/// 
fn cardinality_from_attribute(attribute: Attribute) -> Cardinality {
  attribute.cardinality
}

/// Validates a cardinality's bounds by returning an error if its lower bound
/// is bigger than its upper bound.
/// 
fn check_cardinality_bounds(
  enclosing_definition: Span,
  cardinality: Cardinality,
) -> Option(ValidationError) {
  case cardinality_has_valid_bounds(cardinality) {
    True -> None
    False ->
      Some(validation_error.LowerBoundGreaterThanUpperBound(
        enclosing_definition: enclosing_definition,
        cardinality: cardinality,
        hint: Some("TODO: add hint"),
      ))
  }
}

/// Returns true if the given cardinality has valid bounds; that is, if its
/// lower bound is lower than its upper bound.
fn cardinality_has_valid_bounds(cardinality: Cardinality) -> Bool {
  case cardinality {
    Bounded(_, lower_bound, upper_bound) if lower_bound > upper_bound -> False
    Unbounded(_, _) | Bounded(_, _, _) -> True
  }
}

/// Checks that all entities declared in a module have different names.
/// 
fn check_all_entities_have_different_names(
  module: Module,
) -> List(ValidationError) {
  entities_from_module(module)
  |> list_extra.duplicates(by: fn(entity) { entity.name })
  |> list_extra.map_pairs(to_duplicate_entity_error)
}

fn entities_from_module(module: Module) -> List(Entity) {
  let top_level_entities = module.entities
  let sub_entities = list.flat_map(top_level_entities, entities_from_entity)
  list.append(top_level_entities, sub_entities)
}

fn entities_from_entity(entity: Entity) -> List(Entity) {
  case entity.children {
    None -> []
    Some(hierarchy) -> {
      let children = non_empty_list.to_list(hierarchy.children)
      list.flat_map(children, entities_from_entity)
      |> list.append(children)
    }
  }
}

fn to_duplicate_entity_error(
  first_entity: Entity,
  other_entities: NonEmptyList(Entity),
) -> ValidationError {
  // Sorts the entities by their starting line so that the one that comes first
  // is always reported first.
  let assert [first, other] =
    list.sort(
      [first_entity, other_entities.first],
      fn(one, other) { int.compare(one.span.start_line, other.span.start_line) },
    )

  validation_error.DuplicateEntityName(
    hint: Some("TODO: add hint"),
    first_entity: first,
    other_entity: other,
  )
}

fn check_all_relationships_have_different_names(
  module: Module,
) -> List(ValidationError) {
  relationships_from_module(module)
  |> list_extra.duplicates(by: fn(relationship) { relationship.name })
  |> list_extra.map_pairs(to_duplicate_relationship_error)
}

// TODO: sistemare: decidere se prendere TUTTE le entità e di quelle le relazioni
// o se prendere solo le top level e poi per ognuna recuperare le relazioni
fn relationships_from_module(module: Module) -> List(Relationship) {
  let top_level_relationships = module.relationships
  let all_entities = entities_from_module(module)
  let inner_relationships =
    list.flat_map(all_entities, fn(entity) { entity.inner_relationships })

  list.append(top_level_relationships, inner_relationships)
}

fn to_duplicate_relationship_error(
  first_relationship: Relationship,
  other_relationships: NonEmptyList(Relationship),
) -> ValidationError {
  // Sorts the relationships by their starting line so that the one that comes
  // first is always reported first.
  let assert [first, other] =
    list.sort(
      [first_relationship, other_relationships.first],
      fn(one, other) { int.compare(one.span.start_line, other.span.start_line) },
    )

  validation_error.DuplicateRelationshipName(
    hint: Some("TODO: add hint"),
    first_relationship: first,
    other_relationship: other,
  )
}
