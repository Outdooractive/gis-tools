# CSV

`GISToolsCSV` adds CSV import and export to GISTools. It reads CSV rows into
``FeatureCollection`` values and writes ``FeatureCollection`` values back to
CSV, including files exported by PostGIS.

- Repository: [gis-tools-csv](https://github.com/Outdooractive/gis-tools-csv)
- Product: `GISToolsCSV`
- Formats: CSV with a required header

## Installation

```swift
dependencies: [
    .package(
        url: "https://github.com/Outdooractive/gis-tools",
        from: "3.0.0"),
    .package(
        url: "https://github.com/Outdooractive/gis-tools-csv",
        from: "1.0.0"),
],
targets: [
    .target(
        name: "MyTarget",
        dependencies: [
            .product(name: "GISTools", package: "gis-tools"),
            .product(name: "GISToolsCSV", package: "gis-tools-csv"),
        ]),
]
```

## Reading

```swift
import GISTools
import GISToolsCSV

let collection = try CSVCoder.read(from: csvURL)

// A different delimiter:
let semicolonSeparated = try CSVCoder.read(
    from: csvURL,
    options: CSVReadOptions(delimiter: ";"))
```

The convenience initializer is optional:

```swift
if let collection = FeatureCollection(csv: csvURL) {
    print(collection.features.count)
}
```

`CSVCoder.read(from data:options:)` reads from `Data` instead of a file.

### Geometry detection

A header row is required; geometry is never guessed. The reader recognizes:

- `geometry` or `geom` columns containing WKT, optionally with an
  `SRID=4326;` prefix
- Hex-encoded WKB, EWKB or TWKB
- GeoJSON geometry objects
- `latitude`/`longitude` columns, with optional `altitude`

If a geometry column is present it wins. Otherwise the reader builds a
``Point`` from the latitude and longitude columns. Any other column becomes a
``Feature`` property. Numeric values become `Int` or `Double`, `true`/`false`
become `Bool`, and everything else remains a `String`.

The header is matched case-insensitively. Accepted aliases include:

| Role | Accepted names |
|---|---|
| Geometry | `geometry`, `geom` |
| Latitude | `latitude`, `lat` |
| Longitude | `longitude`, `long`, `lng` |
| Altitude | `altitude`, `elevation`, `elev`, `z` |
| Feature id | `id`, `feature_id`, `feature_identifier`, `identifier`, `fid`, `objectid` |

### Read options

| Option | Default | Description |
|---|---|---|
| `delimiter` | `","` | Field delimiter; any character is accepted. |
| `nullHandling` | `.keepAsString` | `.keepAsString` keeps `NULL`/empty values as strings; `.omit` drops the property. |
| `treatAsLineString` | `false` | Concatenates row coordinates into one ``LineString`` feature in row order. |

`treatAsLineString` works for latitude/longitude rows and for `POINT`,
`MULTIPOINT`, `LINESTRING` and `MULTILINESTRING` values in a geometry column.
Other geometry types, or fewer than two total coordinates, are errors. Row
properties and ids are dropped.

RFC 4180-style quoting is supported, including embedded delimiters, quotes and
newlines.

## Writing

```swift
try collection.writeCSV(to: outputURL)

let data = try CSVCoder.write(collection)
```

The writer always emits a header. For a collection containing only simple
points it writes `id`, `longitude`, `latitude`, `altitude` and the remaining
properties. For mixed or complex geometry it writes the property columns first
and the geometry last. Geometry is written as WKT by default.

### Write options

| Option | Default | Description |
|---|---|---|
| `delimiter` | `","` | Field delimiter. |
| `geometryFormat` | `.auto` | `.auto`, `.wkt`, `.ewkb` (hex) or `.geojson`. |
| `geometryColumnName` | `"geometry"` | Name of the emitted geometry column. |
| `includeHeader` | `true` | Whether to write the header row. |
| `nullValue` | `""` | Text used for `nil` property values. |
| `lineEnding` | `.lf` | `.lf` or `.crlf`. |

Feature ids are always written to the `id` column. Property columns are ordered
by first appearance across all features.

## Limitations

- A header row is mandatory.
- The configured geometry column is always written for complex geometry.
- CSV has no schema; property types are inferred from the parsed values.

## Related packages

<doc:FIT>, <doc:GeoPackage>, <doc:GPX>, <doc:Shapefile>
