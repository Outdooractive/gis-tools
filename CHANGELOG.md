# Changelog

All notable changes to this project are documented in this file.

## Unreleased — 3.0.0

### Breaking changes

#### Boundary and noSRID units

`Polygon.boundary` and `MultiPolygon.boundary` now return `MultiLineString?`
and include hole rings. `length(in:)` and `area(in:)` return `nil` for
`noSRID`, matching the existing distance-unit APIs.

#### Graph API is opt-in

The graph construction, routing and network-analysis API is now gated behind
the `EnableGraphAPI` package trait. Consumers that use `Graph` must enable it:

```swift
.package(url: "https://github.com/Outdooractive/gis-tools", traits: ["EnableGraphAPI"])
```

For local package commands, pass `--traits EnableGraphAPI` to `swift build`,
`swift run` or `swift test`.

#### Validity semantics

`isValid` now means OGC/PostGIS topological validity, not merely “enough
coordinates to make sense”. The previous structural check is available as
`isStructurallyValid`.

New properties:

- `isValidReason` explains the first topological validity failure.
- `isSimple` reports whether a geometry has no self-intersections.

This also changes `validated`, which now accepts only topologically valid
geometries.

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

#### BoundingBox storage

`BoundingBox` now stores scalar X/Y bounds plus optional altitude instead of two
full coordinates. It is 64 bytes instead of 120, which also shrinks every
geometry and feature wrapper that carries a bounding box.

The linear-reference `m` value is no longer retained. GeoJSON bounding boxes
have no `m` member, `asJson` never emitted it, and most construction paths
already dropped it.

#### Removed deprecated APIs

The deprecated aliases from 2.x have been removed. Use the current names:

| Removed | Replacement |
|---|---|
| `transformedTranslate(...)` / `transformTranslate(...)` | `translated(...)` / `translate(...)` |
| `transformedScale(...)` / `transformScale(...)` | `scaled(...)` / `scale(...)` |
| `transformedRotate(...)` / `transformRotate(...)` | `rotated(...)` / `rotate(...)` |
| `MapTile.pixelCoordinate(...)` | `GISTool.coordinate(fromPixelX:...)` |
| `MapTile.metersPerPixel(at:...)` | `GISTool.metersPerPixel(atZoom:...)` |
| `GISTool.convertToCoordinate(...)` | `GISTool.coordinate(fromPixelX:...)` |
| `GISTool.convertToDegrees(...)` | `GISTool.degrees(fromMeters:atLatitude:)` |
| `BoundingBox(coordinates:paddingKilometers:)` / `(locations:paddingKilometers:)` | `init(coordinates:padding:)` / `init(locations:padding:)` |
| `BoundingBox.with(padding:)` | `BoundingBox.padded(_:)` |
| `BoundingBox.expand(...)` | `BoundingBox.expanded(...)` |
| `BoundingBox.boundingBoxPolygon` | `BoundingBox.boundingBoxGeometry` |

### Added

- Transparent gzip support for GeoJSON data and file loading. The `contentsOf:`
  and `jsonData:` entry points detect the gzip magic bytes and decompress with
  the system zlib library; `GeoJsonReader`, `GeoJsonParser`, `JSONValue` and all
  `GeoJsonReadable` types inherit the behavior. This is available on macOS,
  iOS, watchOS and Linux.

- Unit-aware distance overloads: `distance(to:in:)`, `distance(from:in:)`,
  `rhumbDistance(from:in:)`, `distanceAlong(to:tolerance:in:)`,
  `distanceFrom(..., in:)` and `dWithin(_:distance:in:)`. They return `nil`
  (or `false` for `dWithin`) for `noSRID`, where no physical unit is defined.
  Existing meter-based methods are unchanged.

- OGC predicate conveniences: `containsProperly(_:)`, topological
  `equals(_:)` and `dWithin(_:distance:)`. Polygon `isOverlapping` now
  follows `ST_Overlaps` instead of treating boundary contact as overlap. Its
  unused `tolerance` parameter was removed; use `gridSize` for snapping.

- `area(in:)` and `length(in:)` convert the existing metric area/length through
  ``GISTool/convert(area:from:to:)`` and
  ``GISTool/convert(length:from:to:)``. Invalid units return `nil` (#289).

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

### Changed

- Public meter-based length parameters now consistently use
  `CLLocationDistance`. This also corrects `BooleanOverlap` tolerances, which
  were declared as `CLLocationDegrees` despite being documented and used as
  meters. Projection-dependent APIs and native-unit parameters remain
  documented in their respective code comments.

### Performance

- Added ``Graph/LandmarkIndex`` for ALT (A*, landmarks, triangle inequality)
  routing on directed and undirected graphs. Four precomputed landmarks reduce
  A* query times to roughly **54 µs on Allgäu**, **36 µs on Munich** and
  **0.4 ms on Paris**, after one-time builds of 24 ms, 38 ms and 655 ms.
  Directed graphs use forward and reverse distance tables (#308).

- Added ``Graph/RoutingIndex``, which precomputes the contraction once and
  reuses it for repeated point-to-point queries. It also caches chain
  intermediates during contraction, avoiding repeated chain walks when
  expanding paths. On the Paris fixture, indexed A* routes take ~17 ms versus
  ~40 ms for direct A*, after a ~1 s one-time index build. Indexed searches
  with `blockedNodes` or `edgeFilter` fall back to the original graph (#308).

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
- Concave hull filters triangle edges using precomputed spherical vectors and
  assembles the surviving triangle boundary directly instead of unioning every
  triangle. A 10k-point hull drops from 2.8 s to about **0.12 s**; 1k/10k/50k
  scaling cases are now in the hull benchmark (#282).
- Buffer boundary classification now uses a uniform grid with prepared
  point-in-polygon tests, split-point deduplication is linear per edge, and
  boundary edges are merged in one pass. A 1k-vertex line or polygon buffers
  in about **0.3 s**; 10k vertices complete in about **5 s**, instead of the
  previous >30 s timeout at 1k (#279).
- Overlay difference and symmetric difference now stay within about 1.3× of
  union/intersection after the boundary-index and prepared-geometry work.
  Added 1k/10k/100k scaling cases to the overlay benchmark (#283).
- `BoundingBox` is now 64 bytes instead of 120. This reduces `Point` from 184
  to 128 bytes, `Feature` from 200 to 144, and `LineString`/`Polygon`/
  `FeatureCollection` from 136 to 80. The memory suite now measures 100k point
  features and 10k small polygon features as well as layout sizes (#284).
- `Coordinate3D.equals` now avoids reprojecting when both coordinates already
  use the same projection. Repeated coincidence checks are about 4× faster in
  the cross-module benchmark (#284).
- `Graph.merged(_:)` now uses integer edge keys and appends merged adjacency
  directly instead of building string keys and recomputing undirected edge
  weights twice. Without seam stitching, merging the 33 OSM navigation tiles
  (~36.5k source nodes and ~70.6k directed edge instances) drops from roughly
  **35 ms to 25 ms**; a synthetic 100k-edge merge drops from ~110 ms to
  **~80 ms**. Manually added one-way edges now also make the merged graph
  directed.
- Clipped-tile seams are stitched and noded by default: dangling endpoints
  within `stitchingTolerance` of a nearly collinear segment become graph nodes,
  and collinear overlapping edges are split at shared vertices and
  deduplicated. Pass `stitchingTolerance: 0.0` to disable this. The correctness
  pass costs preprocessing time: the 33 tiles merge in about **250 ms** (versus
  ~25 ms without noding), and the synthetic 100k-edge case in about **500 ms**
  (versus ~80 ms).

- Graph routing now uses compact bitmaps (one bit per node) for visited and
  settled state instead of hash sets or byte-per-node arrays. At 500k nodes a
  single bitset is about 62.5 KB instead of 500 KB; bidirectional search drops
  from roughly 1 MB to 125 KB of scratch state. A* caches heuristic values and
  fully bidirectional graphs skip reverse-adjacency construction. On the new
  deterministic 10k/100k/1M-edge grid benchmarks, Dijkstra improves from
  0.115 s to **0.090 s** at 1M edges, bidirectional Dijkstra from 0.274 s to
  **0.120 s**, and A* from 0.180 s to **0.130 s**. A*, bidirectional search and
  contraction remain slower than plain Dijkstra on grid-like inputs, where many
  routes have equal cost and few chains are contractible; this trade-off is
  documented in DocC (#285). The bitmap change is performance-neutral within
  benchmark noise; its win is lower per-query scratch memory.

### Fixed

- Core utilities, query, tiles and clustering audit (#325): DBSCAN's
  neighbourhood query now widens its longitude window by `cos(latitude)` and
  searches the seam-adjacent window when the radius crosses ±180°, so points
  at high latitudes and across the antimeridian are no longer missed. `MapTile`
  clamps zoom levels to the supported `0...32` range (negative or oversized
  zooms previously trapped in `1 << zoom`), and string/quadkey/descendant
  entry points reject or bound unsupported zooms. `Double.rounded(precision:)`
  returns the value unchanged for precisions beyond the representable
  ~15 digits instead of producing a rounded-but-wrong (or NaN) result.
  Existing query-DSL, tile-cover and benchmark coverage was audited; the
  remaining tile-cover exactness gaps stay in #343.

- Graph and routing audit (#324): chain contraction no longer drops a one-way
  edge when its target looks like a two-way degree-2 pass-through; when a
  direct edge and a longer chain connect the same contracted pair, the
  cheapest edge is kept instead of the first one discovered; and path
  expansion now selects the edge actually used by the route (respecting
  one-way vs two-way edges and reversing intermediate order on reverse
  traversals). All routing entry points (Dijkstra, A*, bidirectional, the
  contraction wrappers, the reusable routing index and ALT) are now
  cross-checked against Floyd–Warshall on seeded random directed and
  undirected graphs, and MST minimality is checked against the cycle property.
  Parallel-edge Eulerian/Chinese Postman behaviour is still incorrect and is
  tracked in #346.

- Projection and coordinate-transformation audit (#323): EPSG:32662 (WGS 84 /
  Plate Carree) now uses its real metre-valued equirectangular definition
  (`x = a·λ`, `y` = WGS84 meridian arc) instead of copying degrees, so its
  wraparound extent is ±`originShift` and conversions agree with PROJ.
  EPSG:26901–26923 are the only NAD83/UTM zones; SRIDs 26924–26960 are
  unassigned or NAD83 State Plane zones and no longer resolve as UTM
  (previously they produced silently wrong coordinates). The ETRS89/UTM
  belt now covers the full EPSG range EPSG:25828–25838 instead of only
  25831–25837. NAD83 UTM now
  reports `utmZone`/`utmHemisphere`, `Projection.epsg4269` labels forward
  results with the NAD83 SRID, the meridian-arc series matches the exact
  elliptic integral to nanometres, WKT zone matching rejects datum/hemisphere
  inconsistencies instead of falling through to WGS84, and the projection
  matrix fixture is regenerated from PROJ.

- Line and polygon algorithm audit (#322): rewinding now applies the requested
  winding order to closed LineStrings; `lineArc` uses the requested number of
  steps; negative distances in `coordinateAlong`/`sliceAlong` are clamped and
  no longer trap; `lineSplit` returns the original short line when there are no
  intersections; `lineSlice` no longer duplicates interior vertices; `Clean`
  uses perpendicular distance for collinearity and honors polygon `gridSize`;
  direct `Coordinate3D.snappedToGrid` rejects non-positive tolerances;
  `bezierSpline` and `polygonSmooth` guard non-positive numeric parameters;
  `LineOffset` preserves the source projection and unwraps the antimeridian;
  `LineOverlap` expands searches by the requested tolerance; `Polygonize`
  rewinds shells counter-clockwise; `Polygon.tangentPoints` rejects points in
  concave interiors; `coverageSimplified` simplifies a single polygon; and
  Voronoi cells preserve feature ids, properties and foreign members.

- Overlay, buffer, clipping and indexing audit (#321): overlay operations now
  treat each `MultiPolygon` as a union of parts, reproject mixed-projection
  operands independently, keep vertex-touching components separate, rewind
  difference holes, use finer topology tolerances, and validate coverage
  connectivity. R-trees terminate with empty input and small node sizes;
  tile covers deduplicate collections, reject negative zoom and clamp
  Mercator rows; prepared rings no longer crash on degenerate horizontal
  rings; point/line intersections are symmetric; noSRID buffers have area;
  over-inset polygons return `nil`; and mask defaults are projection-aware.

- Predicate, validity, distance and measurement audit (#320): coverage and
  containment now preserve the segment's CRS, mixed-projection distances
  project into the receiver's CRS, planar distances and lengths unwrap the
  antimeridian, polygon boundaries include holes, touching/crossing/overlap
  handle holes, T-junctions and boundary-only contact, FeatureCollection
  containment requires every feature, ring winding handles the prime meridian,
  collinear vertices no longer make polygons concave, and parallel checks
  require matching segment counts. Center mean/median now handle the
  antimeridian and non-geographic projections correctly.
- `length(in:)` and `area(in:)` now return `nil` for `noSRID` instead of
  treating raw units as metres; `Polygon.area` for `noSRID` is a planar
  shoelace area.
- `Polygon.boundary` and `MultiPolygon.boundary` now include hole rings and
  return `MultiLineString?`.

- GeoJSON model and reader audit (#319): feature `id` is no longer exposed as a
  foreign member, string and `Data` readers use the same fallback path, parser
  validation continues after a missing geometry and checks ring closure and
  foreign-member compatibility, and collection mutation no longer traps on
  negative indices or rejects unlocated features in located collections.
- WKB/WKT/TWKB audit (#319): explicit WKB source projections now consume an
  embedded EWKB SRID, truncated WKB counts and invalid rings are rejected,
  nested encoders use the requested projection, malformed WKT and trailing
  bytes are rejected, and TWKB metadata (bbox, size, ID list, Z/M dimensions
  and the empty-geometry flag) is parsed according to the specification.

- `madeValid` now accepts repaired results only when they satisfy topological
  ``ValidatableGeoJson/isValid``, not merely structural validity. Invalid
  points and lines return `nil`, invalid holes either fall back to a valid
  shell or return `nil`, and overlapping `MultiPolygon` components are
  rejected. Added regression coverage across EPSG:4326, EPSG:3857, EPSG:4978
  and noSRID (#306).

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

