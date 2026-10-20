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
That behaviour is now `covers(_:)`.

#### Hole boundaries

A point on a hole's boundary is now reported as `.boundary`, matching JTS
`SimplePointInAreaLocator` and GEOS. Previously hole boundaries were treated
inverted relative to the outer boundary: they counted as inside when the
boundary was ignored, and as outside when it was included.

#### Geometry-level predicates

`GeoJson.contains(_:)` / `GeoJson.covers(_:)` for line and polygon operands
still use the previous boundary-inclusive implementation; only the point
overloads are aligned in this release. The interior-only/boundary-inclusive
split for the remaining geometry pairs is planned as a follow-up, together
with segment-aware coverage checks.

### Fixed

- Points on a polygon hole boundary are now reported as boundary points
  instead of being treated as inside the hole (or outside the polygon),
  matching JTS/GEOS and OGC (#257).

