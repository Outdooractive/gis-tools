# ``GISTools``

GIS tools for Swift: GeoJSON, projections, spatial predicates, overlay
operations, algorithms, spatial indexing, querying and graph routing.

## Overview

GISTools is a pure Swift package for working with geospatial data. It models
GeoJSON geometries and features, keeps projection information on every
coordinate, and provides algorithms that operate consistently across
EPSG:4326 (WGS84), EPSG:3857 (Web Mercator), EPSG:4978 (ECEF) and `noSRID`.

The package covers:

- GeoJSON reading, writing, validation, strict and lenient parsing
- WKB, WKT and TWKB encoding and decoding
- Projection-aware distance, bearing, overlay, buffer, hull and simplification
  operations
- Spatial predicates with OGC/PostGIS `contains`, `covers` and `locate`
  semantics
- A spatial R-tree and a property/spatial query DSL
- Antimeridian-aware geometry handling
- Opt-in graph construction, routing and network analysis

Companion packages add CSV, FIT, GeoPackage, GPX and Shapefile support:
[CSV][csv], [FIT][fit], [GeoPackage][geopackage], [GPX][gpx] and [Shapefile][shapefile]. Tiled
vector formats (MVT and MLT) and the `mvt` CLI live in [mvt-tools][mvttools].

> Important: GISTools 3.0 contains source-breaking changes to containment,
> validity, projected coordinates, unlocated features, bounding boxes and the
> graph API. Read [Migrating to GISTools 3.0][migration] before upgrading.

## Quick example

```swift
import GISTools

let coordinate = Coordinate3D(latitude: 48.1372, longitude: 11.5756)
let feature = Feature(
    Point(coordinate),
    properties: ["name": "Munich"])

let json = feature.asJsonString(prettyPrinted: true)
let decoded = Feature(jsonString: json)
```

## Topics

### Essentials

- [Getting started](doc:GettingStarted)
- [Projections and antimeridian handling](doc:ProjectionsAndAntimeridian)
- [GeoJSON and WKB/WKT/TWKB](doc:GeoJSONAndCoders)

### Querying and routing

- [Query DSL](doc:QueryDSL)
- [Graph API](doc:GraphAPI)

### Related packages

- [CSV](doc:CSV)
- [FIT](doc:FIT)
- [GeoPackage](doc:GeoPackage)
- [GPX](doc:GPX)
- [Shapefile](doc:Shapefile)
- [mvt-tools](doc:MVTTools)

### Performance

- [Performance and memory notes](doc:PerformanceAndMemory)

### Migration

- [Migrating to GISTools 3.0](doc:MigrationGuide)

[csv]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/csv
[fit]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/fit
[geopackage]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/geopackage
[gpx]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/gpx
[shapefile]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/shapefile
[mvttools]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/mvttools
[migration]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/migrationguide
