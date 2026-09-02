# Crash: Swift `_dictionaryUpCast` during GeoJSON parsing

Status: **fixed** (in gis-tools; requires the oa-app-ios app to pick up the new GISTools package revision).

## Problem

The iOS app (oa-app-ios) crashes with `EXC_BREAKPOINT` / `EXC_BAD_ACCESS` (a hard,
non-catchable trap) inside Swift's standard library helper
`_dictionaryUpCast<A, B, C, D>(_:)` while parsing GeoJSON route data. The stack:

```
_dictionaryUpCast
Feature.init(json:calculateBoundingBox:)     GISTools/GeoJson/Feature.swift
static GeoJson.tryCreate(json:)              GISTools/GeoJson/GeoJson.swift
FeatureCollection.init(geoJson:...)          GISTools/GeoJson/FeatureCollection.swift
... down through Segment.init(json:), TourPath.init(json:), Tour.path.getter (OASDK),
RoutePlannerMapController.showGeometry (oa-app-ios, main thread)
```

### Why it's a hard crash and not a `nil`/error

GeoJSON `init?(json:)` methods do **whole-dictionary conditional casts** such as

```swift
json as? [String: Sendable]
```

on values produced by `Foundation.JSONSerialization` (bridged `NSDictionary` /
`NSArray` / `NSNumber`). For certain bridged layout combinations (inhomogeneous
nested values, `NSNumber`-backed numbers, booleans) the stdlib `_dictionaryUpCast`
trips an internal assertion *before* the `as?` can return `nil`. Because it is a
trap and not a thrown error, downstream `try?`/`init?(json:)` guards never get a
chance to short-circuit — the process dies.

### Where the casts live

`Sources/GISTools/GeoJson/`: `Feature.swift`, `FeatureCollection.swift`,
`Polygon.swift`, `Point.swift`, `LineString.swift`, `MultiPoint.swift`,
`MultiLineString.swift`, `MultiPolygon.swift`, `GeometryCollection.swift`;
and the two top-level dispatchers in `GeoJson.swift`
(`tryCreate(json:) -> GeoJson?`, `tryCreateGeometry(json:) -> GeoJsonGeometry?`).

## Attempted fix (incomplete)

*(Superseded — see "Completed fix" below. Kept for context: the first
attempt rebuilt arrays as `[any Sendable]`, which broke downstream concrete
typed casts like `as? [Double?]` and made Point parsing return `nil`.)*

Replace the whole-dictionary `as? [String: Sendable]` with a **recursive,
element-by-element coercion** that never relies on the stdlib whole-dictionary
upcast — a bad element yields `nil` (graceful) instead of trapping.

Helpers added (top of `GeoJson.swift`):

- `func jsonCoerceSendable(_ value: Any?) -> Any?`
- `func jsonCoercibleDictionary(_ value: Any?) -> [String: Sendable]?`
- `Dictionary.coercedAsJsonDictionary()` / `NSDictionary.coercedAsNSDictionary()`

`Feature.swift`, `GeoJson.swift`, `Polygon.swift`, etc. changed their
`json as? [String: Sendable]` casts to `jsonCoercibleDictionary(json)`.

### Verified so far

- Valid **Polygon** fixture (`TestData/Circle/CircleResult.geojson`) parses
  correctly (1 ring, 65 points) — geometry arrays preserved.
- Real **FeatureCollection** fixture (`TestData/Graph/RoadNetwork_Raploch.geojson`)
  parses correctly (670 features, LineString geometry).
- **NSNull** property values degrade gracefully (no crash).

### Still broken

- A **Point** geometry (single coordinate, `coordinates: [1.0, 2.0]`) fails to
  parse; a `FeatureCollection` whose features have Point geometry drops those
  features (features count 0 vs 1).
- Root cause: arrays are coerced to `[any Sendable]`, but downstream code reads
  coordinates via concrete typed casts such as `json as? [Double?]`,
  `json as? [Any]`, `[[Any]]` in `Coordinate3D` / `tryCreate`/geometry paths.
  `[any Sendable]` does not satisfy those casts, so `Coordinate3D` / `Point`
  parsing returns `nil`. The original Swift bridging produced arrays that these
  casts succeed on.
- Also tricky: Swift 6 strict concurrency forbids storing `[Any]` (not
  `Sendable`) inside `[String: Sendable]`, so changing arrays to `[Any]` to
  satisfy the downstream `as? [Any]`/`as? [Double?]` casts conflicts with the
  `[String: Sendable]` model. This tension is the core of the unfinished work.

## Reproducer (minimal)

Run in `gis-tools` after building (`swift build`):

```swift
import Foundation
import GISTools

let pointJSON = #"{"type":"Point","coordinates":[1.0,2.0]}"#
print(try? Point(jsonString: pointJSON))   // now parses (was nil in the first attempt)

let fcJSON = #"{"type":"FeatureCollection","features":[{"type":"Feature","properties":{},"geometry":{"type":"Point","coordinates":[1.0,2.0]}}]}"#
print((try? FeatureCollection(jsonString: fcJSON))?.features.count)  // now 1

let lineJSON = #"{"type":"FeatureCollection","features":[{"type":"Feature","properties":{},"geometry":{"type":"LineString","coordinates":[[1.0,2.0],[3.0,4.0],[5.0,6.0]]}}]}"#
print((try? FeatureCollection(jsonString: lineJSON))?.features.count) // 1
```

## Completed fix (2026-09-02)

New file `Sources/GISTools/GeoJson/JsonCoercion.swift` — a `private enum
JsonCoercion` namespace with element-wise coercion helpers:

- `JsonCoercion.dictionary(_:)` — coerces any JSON object into
  `[String: Sendable]` **element by element**. Bridged dictionaries
  (`NSDictionary`) are iterated instead of whole-cast, so the trapping
  `_dictionaryUpCast` is never invoked. Nested dictionaries recurse; bad
  elements (non-string keys, non-JSON values) yield `nil` gracefully.
- `JsonCoercion.array(_:)`, `.coordinateArray(_:)`, `.doubleArray(_)`,
  `.coordinateArrayList(_)`, `.double(_:)` — element-wise array/number reads
  for `Coordinate3D`, `BoundingBox` and `Validatable`.
- **Arrays are coerced element-wise** into native `[Sendable]` boxes — only
  dictionaries are rebuilt wholesale. Elements keep their runtime types
  (numbers stay `NSNumber`), so downstream `as? [Double?]` / `as? [Any]`
  casts keep working (they cast elements one by one) and the
  `[String: Sendable]` model is satisfied. Note: the raw `NSArray` cannot be
  stored directly — its `Sendable` conformance is unavailable in Swift 6
  mode on Darwin.
- Numbers stay `NSNumber` (runtime representation unchanged), so
  `as? Int`/`as? Double` reads and integer-valued coordinate arrays work.
- Boolean rejection in `double(_:)` uses `objCType == "c"` — `value is Bool`
  is *not* reliable on Linux corelibs (plain numbers like `1.0` answer
  `true` there).

All 11 whole-dictionary cast sites replaced: the 9 type initializers
(`Point`, `MultiPoint`, `LineString`, `MultiLineString`, `Polygon`,
`MultiPolygon`, `GeometryCollection`, `Feature`, plus `Feature.properties`)
and the two dispatchers in `GeoJson.swift` (`tryCreate(json:)`,
`tryCreateGeometry(json:)`) plus the four generic array `tryCreate`s.

### Verification

- All acceptance criteria 1–4 verified; `swift build` has zero warnings.
- `swift test`: 2355 tests in 171 suites pass (incl. new
  `Tests/GISToolsTests/GeoJson/JsonCoercionTests.swift`, 19 tests).
- Note on criterion 5: `Circle.geojson` was a red herring — no test
  references it; `CircleTests` uses `CircleResult.geojson`, which exists.
  `swift test` passes on this environment.

## Minimum acceptance criteria for a complete fix

*(All met — see "Completed fix".)*

1. `Point`, `MultiPoint`, `LineString`, `MultiLineString`, `Polygon`,
   `MultiPolygon`, `Feature`, `FeatureCollection` all parse from
   `JSONSerialization`-bridged input including Point/coordinate depths. ✅
2. Empty / `NSNull` / malformed values degrade to `nil`/skipped (no
   `_dictionaryUpCast` trap), not a crash. ✅
3. Integer-valued JSON properties preserve `as? Int` reads (e.g. `id: 5` →
   `as? Int`), and float values preserve `as? Double`. ✅
4. Existing fixtures under `Tests/GISToolsTests/TestData/` parse unchanged. ✅
5. `swift test` passes. ✅
