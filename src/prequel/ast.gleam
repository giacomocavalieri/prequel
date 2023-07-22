import gleam/option.{Option}
import non_empty_list.{NonEmptyList}
import prequel/span.{Span}

/// A module is the result obtained by parsing a file, it contains a list of
/// entities and relationships.
/// 
pub type Module {
  Module(entities: List(Entity), relationships: List(Relationship))
}

/// A relationship as described by the ER model. It always involves at least
/// two entities and can also have attributes.
/// 
pub type Relationship {
  Relationship(
    span: Span,
    name: String,
    entity: RelationshipEntity,
    entities: NonEmptyList(RelationshipEntity),
    attributes: List(Attribute),
  )
}

/// An entity that takes part in a relationship with a given cardinality.
/// 
pub type RelationshipEntity {
  RelationshipEntity(span: Span, name: String, cardinality: Cardinality)
}

/// An entity as described by the ER model. It has a name, it can have 
/// zero or more attributes that can also act as keys.
/// The first key is always considered to be the primary key.
/// An entity can also be the root of a hierarchy of sub-entities.
/// 
pub type Entity {
  Entity(
    span: Span,
    name: String,
    keys: List(Key),
    attributes: List(Attribute),
    inner_relationships: List(Relationship),
    children: Option(Hierarchy),
  )
}

/// An attribute that can be found inside the body of an entity or a
/// relationship.
/// 
pub type Attribute {
  Attribute(span: Span, name: String, cardinality: Cardinality, type_: Type)
}

/// The cardinality of an attribute or of an entity in a relationship.
/// 
pub type Cardinality {
  /// A cardinality where the upper bound is the letter `N`,
  /// for example `(1-N)`, `(0-N)` are both unbounded.
  ///
  Unbounded(span: Span, lower_bound: Int)

  /// A cardinality where both upper and lower bound are numbers,
  /// for example `(0-1)`, `(1-1)` are both bounded.
  /// 
  Bounded(span: Span, lower_bound: Int, upper_bound: Int)
}

/// The type of an attribute.
/// 
pub type Type {
  NoType
  ComposedAttribute(span: Span, attributes: List(Attribute))
}

/// The key of an entity, its composed of at least the name of one of the
/// attributes (or one of the relationships that can be used as external keys).
/// 
pub type Key {
  SingleKey(span: Span, key: String, type_: Option(Type))
  ComposedKey(span: Span, keys: NonEmptyList(String))
}

/// A hierarchy of entities, it specifies wether it is overlapping or disjoint
/// and wether it is total or partial.
/// 
pub type Hierarchy {
  Hierarchy(
    span: Span,
    overlapping: Overlapping,
    totality: Totality,
    children: NonEmptyList(Entity),
  )
}

/// The totality of a hierarchy: it can either be `Total` or `Partial`.
/// 
pub type Totality {
  Total
  Partial
}

/// The overlapping of a hierarchy: it can either be `Overlapped` or `Disjoint`.
/// 
pub type Overlapping {
  Overlapped
  Disjoint
}
