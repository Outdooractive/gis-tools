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

- Edge-case coverage tests (#382): added meaningful regression tests for
  Helmert datum transforms, topological validity failures, Boolean touch
  combinations, buffer collections/insets, simplify metadata and shared
  chains, bounding-box clipping boundaries, point-on-feature fallbacks,
  BooleanCover union receivers, direct overlay assembly, LAEA projection
  modes, built-in projection metadata and prepared-path invariants,
  projection WKT zone rejection, parser/decoder invalid-input branches,
  concave-hull collection inputs and graph debug descriptions. Coverage
  increased from **88.27%** to **90.35%** weighted line coverage.

- Coverage and formatting gates (#382): refreshed `Tests/TEST_COVERAGE.md`
  from the current code-coverage JSON (231 files, **88.27%** weighted line
  coverage), added a documented **87.5%** CI coverage floor, a
  `scripts/refresh_coverage_report.py` refresh/gate command, and a
  changed-file SwiftFormat lint job using `.swiftformat` and the pinned
  `.swift-version`, failing when a PR adds new violations relative to its base
  branch. Exact local commands are
  documented in the README and the coverage report.

- Deterministic property-based and differential tests (#381): seeded
  generators now exercise GeoJSON, WKB, WKT and TWKB round-trips, overlay
  partition invariants (projected and antimeridian-crossing), simplify and
  buffer invariants. Shapely-generated overlay, buffer and polygonize fixtures
  are covered by a new differential test suite; the generator script is
  development-only and the package keeps no third-party runtime dependency.

- API compatibility CI (#380): pull requests now run
  `swift package diagnose-api-breaking-changes` against their base branch.
  Accidental public API removals or signature changes fail CI; intentional
  changes are acknowledged with the `api-breaking` label. See
  [API_BREAKAGE.md](API_BREAKAGE.md).
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

- Polar Lambert azimuthal equal-area forward projection scaling: the polar
  branches now apply the ellipsoid semi-major axis, matching the equatorial
  and oblique formulas and the inverse path. Discovered by the new LAEA mode
  round-trip tests.

- Symmetric difference correctness (#394): `symmetricDifference` is now the
  union of the two independently computed one-sided differences (`A \ B` and
  `B \ A`) instead of a single multi-component XOR boundary pass. This fixes
  invalid output and a wrong area for overlapping rectangles. The property
  and Shapely differential tests now assert symmetric difference again.

- Hardcoded epsilon audit (#387): replaced unexplained tolerance literals
  with named constants or existing `GISTool` tolerances. `BooleanPointInPolygon`
  now uses `GISTool.determinantEpsilon`; `BooleanEquals`, `LineMerge`,
  `Clusters`, `Overlay`, `Polygonize` and the LCC/Albers/LAEA/Swiss
  projection math document their local tolerances and units. Numeric values
  are unchanged.

- CI configuration (#379): GitHub Actions now runs on pull requests targeting
  any branch (including stacked audit branches), supports manual dispatch,
  cancels superseded runs, and tests the two individual conversion traits in
  a single Linux job. The matrix stays at three jobs; trait combinations are
  intentionally not tested.

- Generic geometry dispatch safety (#386): replaced all forced `as!` casts in
  the GeoJSON transform, rewind, snap, simplify, truncate, reverse, densify,
  scale, WKB and WKT dispatch paths with a single checked-cast helper that
  reports the expected and actual type. Removed or guarded the force unwraps
  in the same dispatch and geometry paths, including the cited `outerRing!`
  and `sorted.last!` cases. Added regression tests for every concrete GeoJSON
  type and both coder type switches. No public behavior changed.
- Geographic and unit-conversion constants (#388): added canonical
  `GISTool.oneDegreeLatitudeDistance`, `metersPerDegreeLongitude(atLatitude:)`,
  `conservativeMetersPerDegree` and documented length/area conversion
  constants. `Conversions`, `RectangleGrid`, `Graph`, `Clusters`, `Projection`
  and the trait-gated meter extensions now use them instead of scattered
  `111_000`/`111_320`/`111_325`, mile/nautical-mile and imperial-unit
  literals. The deliberately conservative DBSCAN search bound remains
  separate and documented.
- BoundingBoxClip split-box cleanup (#376): removed the stale
  `TODO: This is ugly Swift code` and factored the two crossing-box windows
  through a local constructor, avoiding duplicated coordinate boilerplate. No
  clipping behavior changed.

- Open-ended and reversed `LineString.slice` (#375): `nil` start/end now
  have exact regression coverage for the documented first/last defaults, all
  projections, antimeridian crossing, altitude interpolation and the
  `Feature.slice` wrapper. Start/end points on the same segment are now
  ordered along that segment, so reversed same-segment slices no longer emit
  coordinates in reverse line order. Removed the stale open-ended-slice TODO.

- MapTile children at maximum zoom (#370): `child` returns the receiver
  unchanged and `children` returns an empty array when `z == 32`, instead of
  shifting x/y and emitting invalid same-zoom tiles. Zoom 31 still produces
  four valid zoom-32 children.

- Voronoi duplicate and collinear sites (#369): duplicate coordinates are
  collapsed to the first feature (including its `id`, properties and foreign
  members) before triangulation, and neighbours are resolved from the
  deduplicated sites instead of `firstIndex` lookups. One and two distinct
  sites, and any number of collinear sites, now use direct half-plane clipping
  rather than returning an empty diagram. The documented contract changed from
  "at least three input points" to "one cell per distinct point site".

- Mask result is cut at the antimeridian (#368): when the mask itself crosses
  the seam, the assembled `MultiPolygon` is cut at ±180° (holes and islands
  preserved) so the result never reports `crossesAntimeridian == true`.
  Non-crossing masks keep the direct hole/island construction. Tests assert
  the default world mask is non-crossing and a crossing mask with a custom
  outer preserves the exact world-minus-mask area.

- BoundingBoxClip line handling across the antimeridian (#367): line clipping
  now splits a crossing clip box into its projection-aware non-crossing
  windows, unwraps and shifts the line into each window's world copy, clips
  each part and normalizes the result back. Lines and multi-lines inside a
  `175 → −175` box (or the EPSG:3857 `originShift` equivalent) are no longer
  dropped. Polygon clipping also uses projection-aware split boxes, so a
  crossing 3857 box and cross-projection 4978 clipping stay correct.

- QueryParser nested grouping and prefix NOT (#349): nested parentheses no
  longer reset the caller's pipeline, so `.a == 1 and (.b == 2 or .c == 3)`
  preserves both operands and the connector; a pending boolean connector is
  emitted after the completed group. Prefix `NOT` now negates the following
  operand/group (including after `and`/`or`), while postfix `not` keeps
  negating the accumulated expression. Incomplete pipelines (`.highway ==`,
  `.foo and`, unclosed groups) are rejected by an RPN arity check, and exact
  pipeline/evaluation tests cover nested groups, prefix/postfix negation and
  mixed forms.

- Eulerian and Chinese Postman parallel edges (#346): parity and traversal
  now use **edge multiplicity** over the undirected underlying graph instead
  of distinct neighbours. Hierholzer and the Chinese Postman augmentation are
  built from every underlying edge instance (parallel edges each get their own
  edge ID; two-way edges contribute one underlying edge and one-way edges
  contribute to both endpoint degrees). Two parallel edges, a triangle with a
  duplicated edge, a bridge with parallel edges and opposite one-way edges now
  classify and traverse correctly; postman tour lengths assert the required
  repetitions.

- Overlay and spatial regression coverage (#343): tightened overlay fixture
  area tolerances from 20–40% to 1% (intersection, symmetric difference, mask)
  and buffer fixture tolerances to 2%; added analytic noSRID tests for
  intersection (50), union (150) and symmetric difference (100) of overlapping
  squares; added exact tile-cover tile sets for a single interior tile and a
  two-tile rectangle; and added a seeded deterministic R-tree search
  cross-check against brute-force filtering. The coverage work from #337,
  #338, #340 and #341 already covers the remaining listed APIs (LineOverlap,
  LineChunk, Truncate, SnapToGrid, LineSegments, MakeValid, negative/zero
  buffer, mask holes/partials, crossing clips, PreparedPolygon union and
  crossing bbox).

- GeoJSON decoder validation agreement (#342): the typed `GeoJsonDecoder` now
  validates through `GeoJsonParser` instead of constructing geometries with
  `unchecked` initializers, so the `json`, `jsonData`, `jsonString`,
  `GeoJsonReader` and `JSONDecoder` paths agree on malformed documents.
  Feature/geometry collection decoding is lenient like the parser (malformed
  members are dropped rather than throwing the whole document), the
  `Decodable` path round-trips through the parser, and a concrete-type
  mismatch falls back to the documented JSONValue coercion instead of failing
  outright. Tests compare all entry points on short rings, non-numeric
  coordinates, missing members, empty multi-geometries and valid documents;
  the empty intersection fixture is now constructed directly because an empty
  `MultiPolygon` is deliberately rejected as structurally invalid.

- Mask and BoundingBoxClip correctness (#341): `PolygonGeometry.mask` now
  returns a `MultiPolygon`, so masks with holes become unmasked islands,
  partial masks are clipped to the outer boundary, and multi-part/seam
  results are representable; fully contained masks are constructed directly
  (holes + islands) and only partial overlaps use overlay difference.
  `Polygon.clipped(to:)` now returns a `MultiPolygon` and clips through real
  polygon intersection: crossing clip boxes are handled as their non-crossing
  parts, holes reaching the clip edge become notches, U-shaped polygons can
  split into disconnected parts, and cross-projection clipping uses the
  projected box geometry instead of corner-only reprojection. Tests assert
  exact areas, part counts, validity and 4978 cross-projection.

- Negative buffer holes and degenerate buffer behavior (#340): insets now
  reject any result that is not topologically valid, so a large concave inset
  returns `nil` instead of a self-intersecting/inverted polygon; the hole
  expansion direction is covered by an exact hole-area test for both hole
  windings. Zero-distance buffering has a documented contract: polygonal
  inputs return a cleaned identity `MultiPolygon`, non-areal inputs return an
  empty `MultiPolygon` (still the same return type). Tests assert hole growth,
  ring winding, valid concave output (or nil) and the zero-distance contract.

- Remaining boolean, collection and prepared-geometry semantics (#339):
  a `FeatureCollection` receiver and a multi-part `MultiPolygon` receiver are
  now treated as the union of their parts for `contains`/`covers`, so a
  geometry spanning adjacent features or prepared components is covered;
  `PreparedPolygon` with multiple parts delegates to the union. `BooleanDisjoint`
  is covered for lines through holes, lines crossing the shell and
  boundary-touching lines. `Coordinate3D` equality and hashing were made
  mutually consistent for the wraparound axis (shared with #338). Spherical
  area now uses the same documented `GISTool.earthRadius` model as distance
  and length; the 3857 small-square area expectations were updated accordingly
  and an area-versus-distance consistency test was added.

- Remaining antimeridian correctness in operations and indexes (#338):
  `perpendicularFoot`/`nearestCoordinateOnLine`, `LineSegment.checkIsOnSegment`
  and `LineSegment.intersection` now unwrap seam-crossing segments into a
  continuous frame (intersections stay in the caller's working frame),
  `Kinks` unwraps and aligns rings before detection/un-kinking and keys
  vertices by a wrapped coordinate relation, overlay aligns holes into the
  outer ring's world copy, and crossing geometries get a conservative
  world-width bounding box so R-tree searches on either side of the seam find
  them. `Coordinate3D` equality and hashing now treat `+extent` and `−extent`
  as the same location consistently. Tests cover nearest-point, point-on-line,
  line intersection, RTree/PreparedPolygon search, kinks/un-kink and union
  with real `179 → −179` crossings.

- Line and polygon construction regression coverage (#337): added independent
  expected-value tests for `LineChunk` collection/feature entry points,
  `Truncate` polygon/multi-polygon/collection/`removeM` paths, `SnapToGrid`
  MultiPoint/MultiLineString/GeometryCollection dispatch, `LineSegments`
  BoundingBox/Ring/Polygon/MultiPolygon/collection dispatch, `LineOverlap`
  self-overlap/segmentLength/grid/MultiLineString/FeatureCollection inputs,
  one-sided `LineSlice`/`LineSliceAlong` and Feature variants, `MakeValid`
  `gridSize`, `MultiPolygon.kinks`/mutating `unkink`, exact noSRID/4978
  `LineOffset` behaviour, and `PolygonToLine` coordinates/closure/order.
  The audit found and fixed two bugs: `Truncate` copied stale bounding boxes
  instead of recalculating them, and `unkinked` polygons could be returned with
  open rings.

- Line and polygon constructor antimeridian handling (#336): added a shared
  `AntimeridianCutting.unwrapCoordinates` helper that keeps a sequence
  continuous across the wraparound axis. `BezierSpline` now interpolates in
  the unwrapped frame and normalizes its output, so `179 → −179` control
  points stay near the seam instead of sweeping through 0°; `ConcaveHull`
  unwraps all input points before triangulation and normalizes the resulting
  hull, so crossing hulls use the 20° short span and the correct area, and
  ECEF hulls are computed in geographic space. Tests assert intermediate
  seam spans, exact crossing-hull area and 4978 round trips.

- Voronoi antimeridian and degenerate handling (#335): points and the clip
  bounding box are unwrapped around the projection's wraparound axis (a
  `170 ... -170` box becomes `170 ... 190`), the diagram is computed in the
  short span, and cells are normalized back, so seam-separated sites get
  adjacent small cells instead of world-spanning ones. ECEF inputs are
  computed in geographic space and projected back. One/two points consistently
  return an empty collection (the documented minimum is three), `gridSize`
  matches manual snapping, and tests assert site containment, bounding-box area
  partition, short-side spans and metadata preservation.

- Simplify topology and tolerance handling (#334): `polygonHullSimplified`
  now keeps inner rings (with winding) and the silently ignored `highQuality`
  parameter was removed from that API; `coverageSimplified` decomposes each
  ring into shared and nonshared runs, simplifies every shared chain exactly
  once and reuses it for both incident polygons (including multi-vertex shared
  edges), so no T-junctions are introduced; and the Visvalingam-Whyatt
  threshold is now a perpendicular-distance threshold
  (`0.5 · chordLength · tolerance`) instead of a unit-mixing constant, so
  short and long segments behave consistently. Tests assert hole retention,
  shared-coordinate equality, and equal spike removal on 50 m and 1000 m bases.

- Polygonize topology, dangles and collinear edges (#333): degree-1 dangles
  and bridges (cut edges) are pruned recursively before ring finding;
  collinear overlapping segments are noded at their endpoints and duplicate
  noded edges are removed; bounded face rings are distinguished from the
  unbounded face and classified by containment depth, so a separate inner ring
  becomes a hole (with outer CCW / hole CW winding) instead of a second shell,
  while nested islands stay separate polygons. Coordinates crossing the
  projection wraparound axis are normalized generically (4326 antimeridian and
  3857 `originShift`), and ECEF is polygonized in geographic space and
  projected back. Tests assert coordinates, winding, hole counts, exact area,
  input-order independence and all projections.

- LineMerge junction, metadata and seam endpoints (#332): junction
  continuations are now paired by angle (straightest through-pair) instead of
  input order, so reordering features produces the same geometry and a branch
  is not merged into a through route. Merged lines inherit the `id`,
  properties and foreign members of the earliest contributing input feature
  (documented on `lineMerged`), and one `MultiLineString` copies its metadata
  to every line it produces. `+180°` and `−180°` are treated as coincident
  endpoints, so seam-crossing lines merge without duplicating the seam point.

- Minkowski sum holes and projection handling (#331): polygons whose outer
  ring is convex but which have holes are now tessellated before the vertex
  sum, so hole vertices no longer fill the hole; the pattern is projected into
  the source CRS (mixed 4326/3857 inputs now match normalized inputs); ECEF
  inputs are computed in geographic space and projected back; and differences
  reflect the pattern in the working frame instead of in ECEF. Tests replace
  non-`nil` assertions with exact areas (`[0,10]² ⊕ [0,1]² = [0,11]²`), a
  preserved 84-area hole, mixed-CRS equality and 3857/4978 coverage.

- Tesselate hole and antimeridian triangulation (#330): holes are now
  traversed in the opposite winding direction and bridged to a visible outer
  vertex with duplicated bridge endpoints, so polygons with one or many holes
  triangulate to the correct area instead of overlapping or missing
  ring-minus-hole regions. Rings are unwrapped across the projection's
  wraparound axis before triangulation and emitted coordinates are normalized
  back, so antimeridian polygons use the short side. Degenerate/collinear
  rings stop triangulation instead of emitting overlapping triangles, and
  ECEF polygons are triangulated in geographic space and projected back.
  `TesselateTests` now asserts triangle area sums, hole coverage, short-side
  antimeridian spans and all projections.

- Test quality and coverage audit (#326): generated `Tests/TEST_COVERAGE.md`
  with per-source-file line coverage, direct/indirect test mapping and status,
  an explicit keep decision and rationale for every fixture, a weak-assertion
  inventory, regression links for the audit series, and the remaining gaps.
  Added coverage for the previously untested `FeatureCollection.query` /
  `[Feature].query` entry points, `Projectable.project(to:)`, and the batch
  (`prepared`) transform path for every built-in projection. The audit found
  two larger pre-existing gaps, filed as #346 (Eulerian parallel edges) and
  #349 (QueryParser nested groups / prefix `NOT`).

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

