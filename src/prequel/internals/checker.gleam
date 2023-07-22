import gleam/list
import gleam/option.{None, Option, Some}
import non_empty_list
import prequel/ast.{
  Attribute, Bounded, Cardinality, Entity, Hierarchy, Module, Relationship,
  RelationshipEntity, Unbounded,
}
import prequel/internals/extra/list as list_extra
import prequel/span.{Span}
import prequel/error/validation_error.{ValidationError}

/// Validates a module and returns a list of all the errors found.
/// 
pub fn validate_module(module: Module) -> List(ValidationError) {
  [validate_cardinalities_bounds]
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
fn validate_cardinalities_bounds(module: Module) -> List(ValidationError) {
  cardinalities_from_module(module)
  |> list_extra.map_pair(validate_cardinality_bounds)
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
  let inner_relationship_cardinalities =
    list.flat_map(inner_relationships, cardinalities_from_relationship)
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
fn validate_cardinality_bounds(
  enclosing_definition: Span,
  cardinality: Cardinality,
) -> Option(ValidationError) {
  case cardinality_has_valid_bounds(cardinality) {
    True -> None
    False ->
      Some(validation_error.LowerBoundBiggerThanUpperBound(
        enclosing_definition: enclosing_definition,
        cardinality: cardinality,
        hint: None,
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
