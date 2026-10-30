# Projections and antimeridian handling

GISTools keeps a ``Projection`` on every ``Coordinate3D``. Algorithms use the
receiver's projection as their working frame and convert other inputs into it
when necessary.

## Coordinate representations

- `Coordinate3D(latitude:longitude:)` creates an EPSG:4326 coordinate.
- Projected coordinates must name their projection:
  `Coordinate3D(x:y:projection:)`.
- `Coordinate3D.epsg3857(x:y:)`, `Coordinate3D.epsg4978(x:y:)` and
  `Coordinate3D.noSRID(x:y:)` are conveniences for the common cases.

```swift
let geodetic = Coordinate3D(latitude: 47.3769, longitude: 8.5417)
let mercator = geodetic.projected(to: .epsg3857)
let ecef = geodetic.projected(to: .epsg4978)
let back = ecef.projected(to: .epsg4326)
```

The `x` and `y` aliases are longitude/easting and latitude/northing. They are
not a separate coordinate system.

## Supported projections

Built-in definitions cover:

- EPSG:4326, EPSG:3857 and EPSG:4978
- All WGS84 UTM zones
- EPSG:3395, EPSG:32662, ETRS89 and NAD83 geographic/UTM variants
- British, Irish, Swiss, Dutch, French, German, Austrian and Canadian national
  grids
- European LAEA/LCC, US Albers and Canadian Albers projections
- `noSRID` for local planar data without a physical reference system

Select a UTM zone from a coordinate, including the Norway and Svalbard
exceptions:

```swift
let oslo = Coordinate3D(latitude: 59.91149, longitude: 10.75793)
let utm = Projection.utmZone(for: oslo) // EPSG:32632
let projected = oslo.projected(to: utm)
```

## Distances and units

Distances default to meters. For EPSG:4326 they use the Haversine formula; for
projected and `noSRID` coordinates they use the projection's planar distance.
`length(in:)`, `area(in:)` and the unit-aware overloads return `nil` when the
unit cannot be derived, including for `noSRID`.

## Custom projections

Register custom definitions once, typically at startup:

```swift
let custom = CustomProjection(
    srid: 900_001,
    kind: .planar,
    validExtent: ProjectionExtent(
        minX: -200_000.0,
        minY: -200_000.0,
        maxX: 200_000.0,
        maxY: 200_000.0),
    forward: { coordinate in
        Coordinate3D(
            x: coordinate.longitude * 1_000.0,
            y: coordinate.latitude * 1_000.0,
            projection: .epsg4326)
    },
    inverse: { coordinate in
        Coordinate3D(
            latitude: coordinate.latitude / 1_000.0,
            longitude: coordinate.longitude / 1_000.0,
            m: coordinate.m)
    })

_ = Projection.register(custom)

let customProjection = try Projection(srid: 900_001)
```

Registration is add-only. A custom projection cannot replace a built-in SRID,
and `Codable` decoding throws if a stored projection's SRID is not registered.
Set `wraparoundExtent`, `worldBoundingBox` and `wktMatchers` when the custom
projection needs antimeridian wrapping, algorithm extents or WKT recognition.

## Datum accuracy

Datum-capable built-in definitions use published EPSG Helmert transforms. The
approximate accuracy is:

- NAD27: about 10 m
- OSGB 1936 / British National Grid: about 2 m
- Swiss LV95/LV03: about 1 m
- Irish Grid: about 1 m
- Dutch RD New: about 1 m

Centimeter-level transformations require grid-shift files, which GISTools does
not bundle. `HelmertTransformation` can be used in custom definitions when an
application supplies its own parameters.

## Antimeridian handling

GeoJSON geometries can cross the antimeridian (±180° longitude). GISTools
represents such geometries directly and handles them in predicates, overlays,
buffers, clipping and spatial indexing.

Use `crossesAntimeridian` to detect a crossing geometry and
`cutAtAntimeridian()` to split it into RFC 7946 parts:

```swift
if geometry.crossesAntimeridian {
    let parts = geometry.cutAtAntimeridian()
    for feature in parts.features {
        print(feature.geometry as Any)
    }
}
```

`cutAtAntimeridian()` returns a ``FeatureCollection`` with one feature per cut
part for every geometry type. This keeps iteration uniform.

Behavior by projection:

| Projection | Antimeridian behavior |
|---|---|
| EPSG:4326 | Splits at ±180° |
| EPSG:3857 | Splits at ±originShift, the projected antimeridian |
| EPSG:4978 | No split; the concept does not apply |
| `noSRID` | No split; the concept does not apply |

Overlay operations unwrap crossing polygons into a continuous frame before
computing and wrap the result back afterwards. Point-in-polygon predicates use
the projection's wraparound extent, so raw crossing polygons work in Web
Mercator as well. Bounding-box clipping splits a crossing clip box into
non-crossing windows and clips lines and polygons in each window.

See [Migrating to GISTools 3.0][migration] for the 3.0 projected-coordinate and bounding-box
changes.

[migration]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/migrationguide
