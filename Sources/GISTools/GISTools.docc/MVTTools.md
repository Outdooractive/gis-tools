# mvt-tools

[`mvt-tools`](https://github.com/Outdooractive/mvt-tools) reads and writes
[Mapbox Vector Tiles (MVT)](https://github.com/mapbox/vector-tile-spec) and
[MapLibre Tiles (MLT)](https://maplibre.org/maplibre-tile-spec/), and ships the
`mvt` command-line tool. Despite its name, `mvt` is not limited to vector tiles:
it inspects, queries and converts every supported format, including GeoJSON,
GPX, FIT, CSV, Shapefile and GeoPackage.

- Repository: [mvt-tools](https://github.com/Outdooractive/mvt-tools)
- Product: `MVTTools`
- Formats: MVT 2.1 (including version-1 layers) and MLT (`0x01`), with gzip
  input detection
- CLI: `mvt` with `dump`, `info`, `query`, `merge`, `import`, `export`, `load`,
  `rezoom` and `reproject`; it converts between all supported formats, not just
  vector tiles

MVT and MLT are tiled, layered formats, so `mvt-tools` does not wrap
``FeatureCollection`` like the `gis-tools-*` packages. It provides a
`VectorTile` model instead: layers of features, a tile coordinate, a
projection and tile-space buffers, with optional R-tree indexing.

## Installation

```swift
dependencies: [
    .package(
        url: "https://github.com/Outdooractive/gis-tools",
        from: "3.0.0"),
    .package(
        url: "https://github.com/Outdooractive/mvt-tools",
        from: "3.0.0",
        traits: ["EnableMVT", "EnableMLT"]),
],
targets: [
    .target(
        name: "MyTarget",
        dependencies: [
            .product(name: "GISTools", package: "gis-tools"),
            .product(name: "MVTTools", package: "mvt-tools"),
        ]),
]
```

MVT and MLT are opt-in package traits, so enable `EnableMVT` and/or
`EnableMLT` explicitly. The optional `EnableMLTCXX` trait selects the
deprecated C++ MLT backend instead of the pure Swift implementation.

## Reading

```swift
import MVTTools

let data = try Data(contentsOf: mvtURL)
let tile = try VectorTile(mvtData: data, x: 8716, y: 8015, z: 14)

print(tile.layerNames)
print(tile.features(for: "water").count)
```

MLT uses the same initializer shape:

```swift
let tile = try VectorTile(mltData: data, x: 8716, y: 8015, z: 14)
```

## Writing

```swift
var options = VectorTile.ExportOptions(compression: .default)
options.mlt.useVertexDictionaries = true

let mvtData = tile.mvtData(options: options)
try tile.writeMLT(to: mltURL, options: options)
```

## Command line tool

The `mvt` CLI is not limited to vector tiles. Every command accepts any
supported format, and `merge`, `import` and `export` convert between MVT, MLT,
GeoJSON, GPX, FIT, CSV, Shapefile and GeoPackage.

It is available via Homebrew:

```bash
brew install Outdooractive/homebrew-tap/mvt-tools
```

To build it from source with every format coder:

```bash
swift build --enable-all-traits --product mvt
mvt info tile.mvt -x 8716 -y 8015 -z 14
mvt export tile.mvt --output tile.geojson
```

## Related packages

[CSV][csv], [FIT][fit], [GeoPackage][geopackage], [GPX][gpx], [Shapefile][shapefile]

[csv]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/csv
[fit]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/fit
[geopackage]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/geopackage
[gpx]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/gpx
[shapefile]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/shapefile
