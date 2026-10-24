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
<doc:CSV>, <doc:FIT>, <doc:GeoPackage>, <doc:GPX> and <doc:Shapefile>.

> Important: GISTools 3.0 contains source-breaking changes to containment,
> validity, projected coordinates, unlocated features, bounding boxes and the
> graph API. Read <doc:MigrationGuide> before upgrading.

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

- <doc:GettingStarted>
- <doc:ProjectionsAndAntimeridian>
- <doc:GeoJSONAndCoders>

### Querying and routing

- <doc:QueryDSL>
- <doc:GraphAPI>

### Related packages

- <doc:CSV>
- <doc:FIT>
- <doc:GeoPackage>
- <doc:GPX>
- <doc:Shapefile>

### Performance

- <doc:PerformanceAndMemory>

### Migration

- <doc:MigrationGuide>
