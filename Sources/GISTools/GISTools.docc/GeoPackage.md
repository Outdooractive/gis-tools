# GeoPackage

`GISToolsGeoPackage` reads and writes OGC GeoPackage (`.gpkg`) files, including
feature tables, attribute and media tables, relationships, spatial indexes and
tile pyramids. It is built on top of GISTools and returns GISTools geometry and
feature types.

- Repository: [gis-tools-geopackage](https://github.com/Outdooractive/gis-tools-geopackage)
- Product: `GISToolsGeoPackage`
- Formats: OGC GeoPackage (`.gpkg`)
- System dependency: `libsqlite3`

## Installation

```swift
dependencies: [
    .package(
        url: "https://github.com/Outdooractive/gis-tools",
        from: "3.0.0"),
    .package(
        url: "https://github.com/Outdooractive/gis-tools-geopackage",
        from: "3.0.0"),
],
targets: [
    .target(
        name: "MyTarget",
        dependencies: [
            .product(name: "GISTools", package: "gis-tools"),
            .product(name: "GISToolsGeoPackage", package: "gis-tools-geopackage"),
        ]),
]
```

`libsqlite3` is available by default on the supported Apple platforms and
Linux. The package uses the `sqlite3` pkg-config module when needed.

## Feature tables

The convenience API reads and writes a complete table as a
``FeatureCollection``:

```swift
import GISTools
import GISToolsGeoPackage

let collection = try await FeatureCollection(
    geopackage: gpkgURL,
    table: "countries")

try await collection.writeGeopackage(to: outputURL, table: "countries")
```

Bounding-box reads use the GeoPackage R-tree index when present:

```swift
let box = BoundingBox(
    southWest: Coordinate3D(latitude: 35.0, longitude: -10.0),
    northEast: Coordinate3D(latitude: 60.0, longitude: 40.0))

let filtered = try await FeatureCollection(
    geopackage: gpkgURL,
    table: "countries",
    boundingBox: box)
```

## Connection-based API

`GeoPackageConnection` is a thread-safe actor for larger datasets:

```swift
let gpkg = try await GeoPackageConnection(url: gpkgURL)
defer { await gpkg.close() }

let page = try await gpkg.readFeatures(
    table: "places",
    limit: 100,
    offset: 0)

for try await feature in gpkg.features(table: "places") {
    print(feature.id as Any)
}
```

Incremental writes let you stream batches instead of building one large
collection:

```swift
try await gpkg.createMetadata()
try await gpkg.write(features: firstBatch, to: "places")
try await gpkg.write(features: secondBatch, to: "places")
```

## Tiles, attributes and media

```swift
let tile = try await gpkg.readTile(
    for: TileKey(zoom: 5, column: 12, row: 8),
    from: "tiles")

try await gpkg.writeTilePyramid(
    tiles: tileData,
    to: "tiles",
    matrixSetBounds: bounds,
    matrices: matrices)
```

Attribute and media tables are available directly:

```swift
let attributes = try await gpkg.readAttributeTable(
    table: "station_info",
    rowId: 42)

let media = try await gpkg.readMediaRows(
    table: "photos",
    rowId: 1)
```

Relationship lookups are available from a feature loaded from a GeoPackage:

```swift
let feature = collection.features[0]

let attributes = try await feature.relatedAttributes(in: gpkg)
let media = try await feature.relatedMedia(in: gpkg)

print(feature.gpkgRowId as Any)
print(feature.gpkgTableName as Any)
```

`gpkgRowId` is the SQLite `fid` primary key and is used to resolve related
rows. The GeoJSON ``Feature/id`` is stored separately in the `id` column, so
string, integer and double identifiers can round-trip without being confused
with the GeoPackage row id.

## Validation and inspection

```swift
let result = try GeoPackage.validate(url: gpkgURL)
print(result.isValid)

let contents = try await gpkg.readContents()
let featureTables = try await gpkg.featureTables()
let tileTables = try await gpkg.tileTables()
```

The validator checks GeoPackage schema requirements, while `readContents()`
returns the `gpkg_contents` rows.

## Property type mapping

Attribute columns other than `fid`, `id` and geometry are mapped as:

| GeoPackage type | Swift type |
|---|---|
| `INTEGER` | `Int` |
| `REAL` | `Double` |
| `TEXT` | `String` |
| `BLOB` | Base64 `String` |
| `BOOLEAN` | `Bool` |

## Notes

- Feature-table `id` columns preserve uniform integer, double or string
  identifier types. Mixed-type identifiers fall back to `TEXT`.
- Spatial indexing is accelerated through `gpkg_rtree_index` when present.
- Tile blobs can contain PNG, JPEG or WebP data.
- The connection actor must be closed when finished.

## Related packages

[CSV][csv], [FIT][fit], [GPX][gpx], [Shapefile][shapefile], [mvt-tools][mvttools]

[csv]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/csv
[fit]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/fit
[gpx]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/gpx
[shapefile]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/shapefile
[mvttools]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/mvttools
