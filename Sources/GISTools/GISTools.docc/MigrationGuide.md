# Migrating to GISTools 3.0

GISTools 3.0 contains source-breaking changes. This guide covers the migration
path for every entry in the 3.0 breaking-changes section and the return-type
changes for `mask` and bounding-box clipping. The complete historical list is
in `CHANGELOG.md`.

## Quick checklist

- Replace boundary-inclusive `contains` calls with `covers`.
- Replace structural-validity checks with `isStructurallyValid`.
- Unwrap `Feature.geometry`, or create an unlocated feature explicitly.
- Pass a projection to projected `Coordinate3D(x:y:)` initializers.
- Treat `mask` and polygon clipping results as `MultiPolygon`.
- Enable `EnableGraphAPI` when using `Graph`.
- Handle optional `boundary`, `length(in:)` and `area(in:)` results.
- Stop relying on the bounding box's `m` value.
- Review decoder/parser behavior for malformed or unlocated features.
- Replace removed 2.x aliases with their current names.

## Containment and location

Point containment now follows the OGC Simple Features and PostGIS names:

| API | Meaning |
|---|---|
| `contains(_:)` | `ST_Contains`: only the **interior**; boundary points return `false` |
| `covers(_:)` | `ST_Covers`: interior **or** boundary |
| `locate(_:)` | Returns ``PointLocation/interior``, ``PointLocation/boundary`` or ``PointLocation/exterior`` |

The old `ignoringBoundary` default was `false`, meaning boundary-inclusive
containment. That behaviour is now `covers(_:)`.

| Before | After |
|---|---|
| `geometry.contains(coordinate, ignoringBoundary: true)` | `geometry.contains(coordinate)` |
| `geometry.contains(coordinate, ignoringBoundary: false)` | `geometry.covers(coordinate)` |
| `geometry.contains(coordinate)` (old boundary-inclusive default) | `geometry.covers(coordinate)` |

`gridSize:` remains available on `contains`, `covers` and `locate`.

Geometry-to-geometry calls follow the same split: `contains(_:)` is
interior-only, while `covers(_:)` is boundary-inclusive. Coverage is
segment-aware, operates in the receiver's projection and cuts
antimeridian-crossing geometries at the seam before testing.

## Hole boundaries

A point on a polygon hole's boundary is now ``PointLocation/boundary``. It is
not exterior and it is not interior. This matches JTS
`SimplePointInAreaLocator` and GEOS. Code that classified hole boundaries as
inside or outside must use `covers` or inspect `locate` explicitly.

## Validity

`isValid` now means OGC/PostGIS topological validity instead of the old
structural "enough coordinates" check. The old check is available as
`isStructurallyValid`.

| Before | After |
|---|---|
| `geometry.isValid` for a structural check | `geometry.isStructurallyValid` |
| `geometry.validated` for structural validation | `geometry.isStructurallyValid ? geometry : nil` |
| No reason for a validity failure | `geometry.isValidReason` |
| No self-intersection check | `geometry.isSimple` |

`validated` now returns `self` only when `isValid` is true, i.e. when the
geometry is topologically valid. An unlocated feature is structurally valid;
its other members are still validated.

## Mask and clipping return types

`mask` and polygon clipping can produce holes, islands and multiple disconnected
parts. Their results are now `MultiPolygon` values:

| API | Before | 3.0 |
|---|---|---|
| `PolygonGeometry.mask(outerPolygon:)` | `Polygon?` | `MultiPolygon?` |
| `Polygon.clipped(to:)` | `Polygon?` | `MultiPolygon?` |
| `MultiPolygon.clipped(to:)` | `MultiPolygon?` | `MultiPolygon?` |

Other clipping results are:

| Input | `clipped(to:)` result |
|---|---|
| `Point` | `Point?` |
| `MultiPoint` | `MultiPoint?` |
| `LineString` | `MultiLineString?` |
| `MultiLineString` | `MultiLineString?` |
| `Polygon` / `MultiPolygon` | `MultiPolygon?` |
| `GeometryCollection` | `GeometryCollection?` |
| `GeoJsonGeometry` | `GeoJsonGeometry?` |
| `Feature` | `Feature?` |
| `FeatureCollection` | `FeatureCollection?` |

Migration:

```swift
// Before
let masked: Polygon? = polygon.mask()
let clipped: Polygon? = polygon.clipped(to: boundingBox)

// After
let masked: MultiPolygon? = polygon.mask()
let clipped: MultiPolygon? = polygon.clipped(to: boundingBox)
```

Keep the multi-part result. Taking `.polygons.first` silently drops legitimate
islands or disconnected parts. Masking a polygon that is fully inside the outer
polygon constructs the result directly; partial overlaps use real polygon
difference. Crossing clip boxes are handled as their non-crossing parts.

## Boundary and noSRID units

`Polygon.boundary` and `MultiPolygon.boundary` now return
`MultiLineString?` and include hole rings. Unwrap the optional and handle all
parts when you previously assumed one outer ring.

`length(in:)` and `area(in:)` now return `nil` for `noSRID`, matching the
unit-aware distance APIs. Use the native `length` and `area` properties when
working without a physical reference system, or handle the optional result.

## Graph API is opt-in

Graph construction, routing and network analysis are gated behind the
`EnableGraphAPI` package trait:

```swift
.package(
    url: "https://github.com/Outdooractive/gis-tools",
    from: "3.0.0",
    traits: ["EnableGraphAPI"])
```

For local package commands, pass `--traits EnableGraphAPI` to `swift build`,
`swift run` or `swift test`. Without the trait, graph types and operations are
not compiled into the module.

The optional unit-conversion traits are unchanged in spirit:

- `EnableMeasurementConversionExtensions` returns `Measurement<UnitLength>`.
- `EnableMeterConversionExtensions` returns raw `Double` meters.

The two conversion traits remain mutually exclusive.

## Unlocated features

`Feature.geometry` is optional. RFC 7946 §3.2 allows `"geometry": null`; such a
feature keeps its identifier, properties and foreign members instead of being
dropped.

```swift
let unlocated = Feature(
    id: .string("station-1"),
    properties: ["name": "Closed station"])

if let geometry = feature.geometry {
    print(geometry.type)
}
```

- A missing `"geometry"` member is still invalid.
- An explicit `null` creates an unlocated feature.
- `projection` is `.noSRID`, `allCoordinates` is empty and
  `calculateBoundingBox()` returns `nil`.
- WKB/WKT encoding returns `nil` for an unlocated feature, and for a
  `FeatureCollection` or `[Feature]` containing one.
- Geometry algorithms return `nil`, `false` or empty results for unlocated
  features.

Use ``GeoJsonParser`` if you need diagnostics for malformed documents.

## Explicit projection for projected coordinates

`Coordinate3D(x:y:z:m:)` no longer defaults to EPSG:3857. The `projection:`
argument is required, so lon/lat code cannot accidentally compile as
projected meters.

| Before | After |
|---|---|
| `Coordinate3D(x: x, y: y)` | `Coordinate3D(x: x, y: y, projection: .epsg3857)` |
| `Coordinate3D(x: x, y: y)` (Web Mercator) | `Coordinate3D.epsg3857(x: x, y: y)` |
| `Coordinate3D(x: x, y: y, projection: .epsg4978)` | `Coordinate3D.epsg4978(x: x, y: y)` |
| `Coordinate3D(x: x, y: y, projection: .noSRID)` | `Coordinate3D.noSRID(x: x, y: y)` |

`Coordinate3D(latitude:longitude:…)` remains the EPSG:4326 initializer.

## Bounding boxes

`BoundingBox` stores scalar X/Y bounds plus optional altitude instead of two
full coordinates. It is 64 bytes instead of 120, which also shrinks every
geometry and feature wrapper that carries one.

The linear-reference `m` value is no longer retained. GeoJSON bounding boxes
have no `m` member, so `asJson` never emitted it. If code read
`boundingBox.southWest.m` or `boundingBox.northEast.m`, there is no replacement;
use the coordinate values themselves when the linear reference matters.

## Removed deprecated APIs

The deprecated aliases from 2.x are removed:

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

## Parsing and Codable

The typed decoder now validates through ``GeoJsonParser`` instead of building
geometries with unchecked initializers. The `json`, `jsonData`, `jsonString`,
`GeoJsonReader` and `JSONDecoder` paths agree on malformed documents.

- Feature and geometry collection decoding is lenient like the parser:
  malformed members are dropped instead of failing the whole document.
- A concrete-type mismatch follows the documented `JSONValue` coercion path.
- Use `GeoJsonParser` with `.strict` when a malformed member must fail the
  whole document.
- An unlocated feature cannot be encoded to WKB or WKT.

## Next steps

- <doc:GettingStarted>
- <doc:ProjectionsAndAntimeridian>
- <doc:GeoJSONAndCoders>
- <doc:GraphAPI>
