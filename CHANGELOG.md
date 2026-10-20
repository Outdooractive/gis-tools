# Changelog

All notable changes to this project are documented in this file.

## Unreleased — 3.0.0

### Breaking changes

#### OGC/PostGIS-aligned point containment

Point containment on `Ring`, `Polygon`, `MultiPolygon`, `GeometryCollection`,
`Feature` and `FeatureCollection` now follows the OGC Simple Features /
PostGIS names:

| API | Meaning |
|---|---|
| `contains(_:)` | OGC `ST_Contains`: only the **interior**. Points on the outer or a hole boundary return `false`. |
| `covers(_:)` | OGC `ST_Covers`: interior **or boundary**. |
| `locate(_:)` | Returns `PointLocation.interior`, `.boundary` or `.exterior` (JTS/GEOS `Location`). |

`contains(_:ignoringBoundary:gridSize:)` was removed. The `gridSize:`
parameter is still available on all three methods.

Migration:

| Before | After |
|---|---|
| `geometry.contains(coordinate, ignoringBoundary: true)` | `geometry.contains(coordinate)` |
| `geometry.contains(coordinate, ignoringBoundary: false)` | `geometry.covers(coordinate)` |
| `geometry.contains(coordinate)` (boundary included) | `geometry.covers(coordinate)` |

The old default for `ignoringBoundary` was `false`, i.e. boundary-inclusive.
That behaviour is now `covers(_:)`. The same split applies to geometry-to-
geometry calls: `contains(_:)` is interior-only, `covers(_:)` is the
boundary-inclusive predicate.

#### Hole boundaries

A point on a hole's boundary is now reported as `.boundary`, matching JTS
`SimplePointInAreaLocator` and GEOS. Previously hole boundaries were treated
inverted relative to the outer boundary: they counted as inside when the
boundary was ignored, and as outside when it was included.

#### Geometry-level predicates

`GeoJson.contains(_:)` now implements OGC `ST_Contains`: the receiver must
cover the other geometry and their interiors must intersect. `covers(_:)` is
the boundary-inclusive predicate and no longer delegates to `contains`.

Coverage is segment-aware: a segment is split at its intersections with the
container's boundaries and every sub-segment is tested, so concave containers,
holes and lines crossing a notch are handled correctly. Line boundaries follow
OGC rules (endpoints are boundary, not interior; MultiLineStrings use the
mod-2 rule).

The predicates operate in the receiver's projection and project the other
geometry into it. Antimeridian-crossing geometries are cut at ±180° first.

### Fixed

- Points on a polygon hole boundary are now reported as boundary points
  instead of being treated as inside the hole (or outside the polygon),
  matching JTS/GEOS and OGC (#257).
- Geometry-level `contains` no longer treats boundary points of B as interior
  points of A; `covers` remains boundary-inclusive.
- Coverage and containment now detect segments that leave a concave container
  or cross a hole, instead of only checking vertices.

