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

#### Unlocated features

`Feature.geometry` is now optional. RFC 7946 §3.2 allows `"geometry": null`
for an unlocated feature; such a feature is preserved with its identifier,
properties and foreign members instead of being dropped.

- A missing `"geometry"` member is still invalid; only an explicit `null`
  creates an unlocated feature.
- `Feature(id:properties:foreignMembers:)` creates an unlocated feature
  programmatically.
- `projection` is `.noSRID`, `allCoordinates` is empty and `calculateBoundingBox()`
  returns `nil` for unlocated features.
- WKB/WKT encoding returns `nil` for an unlocated feature, and for a
  `FeatureCollection` or `[Feature]` that contains one.
- Geometry algorithms return `nil`, `false` or empty results for unlocated
  features.

Strict parsing diagnostics are available through ``GeoJsonParser``.

#### Explicit projection for projected coordinates

`Coordinate3D(x:y:z:m:)` no longer defaults to EPSG:3857. The `projection:`
argument is required, so lon/lat code can no longer accidentally compile and
be treated as meters.

Migration:

| Before | After |
|---|---|
| `Coordinate3D(x: x, y: y)` | `Coordinate3D(x: x, y: y, projection: .epsg3857)` |
| `Coordinate3D(x: x, y: y)` (Web Mercator) | `Coordinate3D.epsg3857(x: x, y: y)` |
| `Coordinate3D(x: x, y: y, projection: .epsg4978)` | `Coordinate3D.epsg4978(x: x, y: y)` |
| `Coordinate3D(x: x, y: y, projection: .noSRID)` | `Coordinate3D.noSRID(x: x, y: y)` |

`Coordinate3D(latitude:longitude:…)` remains the EPSG:4326 initializer.

### Added

- ``PreparedPolygon`` and `Polygon/MultiPolygon.prepared()` for repeated
  point and containment queries. The prepared index supports holes,
  antimeridian crossing, all projections and grid snapping (#281).
- `GeoJson.closestPoint(to:)` returns the point on the receiver closest to
  another geometry, following OGC/PostGIS `ST_ClosestPoint` (#287).
- ``GeoJsonParser`` for non-silent parsing:
  - `.lenient` returns the parsed object plus every malformed or skipped
    element as a ``GeoJsonParseIssue`` with a JSON Pointer path.
  - `.strict` throws the first ``GeoJsonParsingError``.
  - Validates Feature and FeatureCollection members, geometry types, position
    arrays (including altitude/`m` nulls), LineString/MultiPoint minimum
    counts, polygon rings and nested GeometryCollections.
  - Works from `Data`, `String`, or an already-parsed JSON object.
  - Typed overloads (`GeoJsonParser.parse(..., as: FeatureCollection.self)`)
    return the requested concrete type and report a type mismatch as an issue.
  - `FeatureCollection(jsonData:issues:)`, `(jsonString:issues:)` and
    `(json:issues:)` provide the existing normalization behaviour with
    diagnostics.
  - The existing `init?(json:)` initializers remain as the silent, lenient
    convenience API.

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

### Performance

- `Coordinate3D` is now 56 bytes (stride 56) instead of 96, and `Projection`
  is 8 bytes instead of 48. The projection definition is resolved from the
  immutable built-in registry instead of being stored in every coordinate
  (#254).
- GeoJSON parsing no longer re-coerces the whole `JSONValue` document in the
  feature and geometry initializers; already-`Sendable` dictionaries take a
  fast path (#254).
- A bounding-box miss in `Polygon.contains` is now O(1): the antimeridian flag
  is cached when the bounding box is calculated (#254).
- GeoJSON `Data`/`String` loading now decodes directly with `JSONDecoder` into
  `Coordinate3D` and the geometry types; `Codable` uses the same path. On the
  640k-vertex benchmark, native loading drops from 7.73 s / 264 MB to
  **0.23 s / 139 MB**, and Codable from 7.42 s / 316 MB to **0.23 s / 139 MB**
  (#254).
- GeoJSON encoding writes coordinate arrays directly to the encoder instead
  of building a full `JSONValue` tree first. A 100k-vertex polygon drops from
  1.55 s to about **0.04 s**; the `coders` benchmark now covers every geometry
  type and a large property set (#280).
- Prepared point-in-polygon uses latitude-bucket ring indexes. Repeated
  lookups improve by about 6× at 1k vertices, 50× at 10k and 200× at 100k.
  Polygon coverage also reuses prepared point lookups and an R-tree over the
  container boundary segments, reducing 1k/1k containment from about 76 ms to
  about 10 ms (#281).
- Buffer boundary classification now uses a uniform grid with prepared
  point-in-polygon tests, split-point deduplication is linear per edge, and
  boundary edges are merged in one pass. A 1k-vertex line or polygon buffers
  in about **0.3 s**; 10k vertices complete in about **5 s**, instead of the
  previous >30 s timeout at 1k (#279).

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
- `Codable` decoding goes through ``JSONValue``; encoding writes the `asJson`
  tree directly instead of going through `[String: Any]` and
  `JSONSerialization`. Booleans stay booleans, numbers and booleans inside
  arrays are preserved, and JSON `null` encodes and decodes instead of being
  dropped or throwing (#255, #256, #280).
- `asJsonData()` / `asJsonString()` now use `JSONEncoder` with the shortest
  round-trip number representation, so coordinates read back bit-exactly.
  Object keys are sorted by default for stable output; `sortedKeys: false`
  opts out. JSON input is read with `JSONDecoder` via ``JSONValue`` (#261).

