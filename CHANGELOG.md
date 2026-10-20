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

#### Antimeridian overlay support

Overlay operations (intersection, union, difference, symmetric difference)
now unwrap antimeridian-crossing polygons into a continuous frame before
computing, and wrap the result back afterwards. The normalized polygons are
also passed to the overlay boundary test, so edges and containment checks
always use the same frame.

Point-in-polygon wraps at the projection's `wraparoundExtent` (EPSG:4326 at
±180°, EPSG:3857 at ±`originShift`), so raw crossing polygons now work in
Web Mercator as well. Polygons with a deliberately world-spanning edge are
left unchanged; that case is ambiguous per RFC 7946.

### Fixed

- Points on a polygon hole boundary are now reported as boundary points
  instead of being treated as inside the hole (or outside the polygon),
  matching JTS/GEOS and OGC (#257).
- Geometry-level `contains` no longer treats boundary points of B as interior
  points of A; `covers` remains boundary-inclusive.
- Coverage and containment now detect segments that leave a concave container
  or cross a hole, instead of only checking vertices.
- Overlaying identical antimeridian-crossing polygons no longer emits both
  copies of each coincident edge, which previously produced a ring and an
  identical hole.
- Overlay now splits collinear and near-collinear overlapping edges at each
  other's endpoints, and matches edges with the same quantized vertex keys as
  ring assembly, so unions of polygons that share part of an edge produce
  closed rings on all platforms.
- Point-in-polygon boundary detection now uses the JTS/GEOS robust orientation
  predicate (floating-point filter with a double-double fallback) and the
  `RayCrossingCounter` segment rules. Points exactly on an edge are now
  detected as boundary points instead of being classified as inside or
  outside (#258).
- `Codable` encoding and decoding now go through ``JSONValue`` instead of
  `[String: Any]` and `JSONSerialization`. Booleans stay booleans, numbers and
  booleans inside arrays are preserved, and JSON `null` encodes and decodes
  instead of being dropped or throwing (#255, #256).

