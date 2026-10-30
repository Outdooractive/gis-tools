# Shapefile

`GISToolsShapefile` reads and writes the ESRI Shapefile set. It maps `.shp`
geometry, `.dbf` attributes, `.shx` indexes and `.prj` projection metadata to
and from GISTools feature collections.

- Repository: [gis-tools-shapefile](https://github.com/Outdooractive/gis-tools-shapefile)
- Product: `GISToolsShapefile`
- Formats: ESRI Shapefile (`.shp`, `.dbf`, `.shx`, `.prj`)

## Installation

```swift
dependencies: [
    .package(
        url: "https://github.com/Outdooractive/gis-tools",
        from: "3.0.0"),
    .package(
        url: "https://github.com/Outdooractive/gis-tools-shapefile",
        from: "3.0.0"),
],
targets: [
    .target(
        name: "MyTarget",
        dependencies: [
            .product(name: "GISTools", package: "gis-tools"),
            .product(name: "GISToolsShapefile", package: "gis-tools-shapefile"),
        ]),
]
```

## Reading

```swift
import GISTools
import GISToolsShapefile

let collection = try FeatureCollection(shapefile: shapefileURL)

// Or use the coder directly:
let sameCollection = try ShapefileCoder.read(from: shapefileURL)
```

The file path is treated as a base URL; the package loads the matching
extensions:

| Extension | Contents |
|---|---|
| `.shp` | Geometry records |
| `.dbf` | Attribute records |
| `.shx` | Spatial index |
| `.prj` | Projection definition |

If no `.prj` is present, EPSG:4326 is assumed. Attributes from `.dbf` become
``Feature`` properties. GeoJSON feature ids are read from the `id` column when
present.

## Supported geometry

- Point and MultiPoint
- PolyLine
- Polygon
- MultiPatch, read as a ``GeometryCollection`` of ``Polygon`` parts
- Z and M variants for the supported geometry types

```swift
for feature in collection.features {
    switch feature.geometry {
    case let point as Point:
        print(point.coordinate)
    case let line as LineString:
        print(line.coordinates.count)
    case let polygon as Polygon:
        print(polygon.rings.count)
    case let collection as GeometryCollection:
        print(collection.geometries.count)
    default:
        break
    }
}
```

## Writing

```swift
try collection.writeShapefile(to: outputURL)

// Or use the coder directly:
try ShapefileCoder.write(collection, to: outputURL)
```

Writing creates the matching `.shp`, `.dbf`, `.shx` and `.prj` files. The
projection is taken from the ``FeatureCollection`` and written to `.prj`.
Project before writing when a specific output CRS is required:

```swift
let projected = collection.projected(to: .epsg3857)
try projected.writeShapefile(to: outputURL)
```

Attributes are written to `.dbf`, and feature ids are written to the `id`
column when present.

## Field and record limits

Shapefile and dBase formats impose hard limits that cannot be bypassed by the
library:

| Limit | Value |
|---|---|
| Field-name length | 10 characters |
| Fields per table | 1,024 |
| Record size | 65,531 bytes |
| MultiPatch | Read-only |
| AutoCAD Civil 3D / ArcGIS variants | Not supported |

Plan column names and record sizes before exporting a large property set. For
unrestricted attributes, GeoPackage or another format is usually a better
choice; see <doc:GeoPackage>.

## Related packages

<doc:CSV>, <doc:FIT>, <doc:GeoPackage>, <doc:GPX>, <doc:MVTTools>
