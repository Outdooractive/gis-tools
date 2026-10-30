# Performance and memory notes

GISTools optimizes the common GeoJSON loading, encoding, predicate, overlay,
buffer, hull and routing paths. The notes below describe where the time and
memory go and which APIs to reach for in hot paths.

## Loading and encoding

- GeoJSON `Data` and `String` loading decodes directly into coordinates and
  geometry types. On the 640k-vertex benchmark, native loading is roughly
  0.23 s and 139 MB instead of 7.73 s and 264 MB; `Codable` follows the same
  path.
- Encoding writes coordinate arrays directly to the encoder instead of building
  a full `JSONValue` tree first. A 100k-vertex polygon encodes in about 0.04 s.
- `Data` entry points transparently decompress gzip input.

Use ``GeoJsonReader`` or `Codable` for normal loading. Use ``GeoJsonParser`` only
when you need strict validation or diagnostics; both use the same validated
decoder path.

## Reuse prepared geometry

- Point-in-polygon on ``Polygon`` and ``MultiPolygon`` can use a prepared
  spatial index. Prepare once and reuse it for many lookups:

  ```swift
  let prepared = polygon.prepared()
  let inside = prepared.contains(coordinate)
  let location = prepared.locate(coordinate)
  ```

  Prepared lookups are about 6× faster at 1k vertices, 50× at 10k and 200× at
  100k. Polygon coverage reuses prepared point lookups and an R-tree over
  boundary segments.
- ``RTree`` is available for spatial filtering. A bounding box is required;
  call `calculateBoundingBox()` or `updateBoundingBox()` before indexing.

## Overlay, buffer and hull

- Overlay operations unwrap antimeridian-crossing polygons, compute in a
  continuous frame and wrap the result back. Difference and symmetric
  difference stay within roughly 1.3× of union and intersection.
- Buffer boundary classification uses a uniform grid, prepared point tests and
  single-pass edge merging. A 1k-vertex line or polygon buffers in about 0.3 s;
  10k vertices take about 5 s.
- Concave hull uses precomputed spherical vectors and assembles the triangle
  boundary directly. A 10k-point hull takes about 0.12 s instead of 2.8 s.
- Use the `gridSize` parameter to snap noisy coordinates before predicates or
  overlay work when sub-tolerance precision is not required.

## Routing

- Dijkstra is the baseline route query. A* and bidirectional Dijkstra are
  useful when the heuristic or bidirectional frontier matches the network
  shape; on grid-like data with many equal-cost routes they can be slower.
- `routingIndex()` precomputes one contraction and reuses it for repeated
  queries. On the Paris fixture, indexed A* routes take about 17 ms instead of
  40 ms after a roughly 1 s index build.
- `landmarkIndex()` uses ALT routing. Four landmarks reduce A* queries to
  roughly 54 µs on Allgäu, 36 µs on Munich and 0.4 ms on Paris after one-time
  builds of 24 ms, 38 ms and 655 ms.
- Routing uses one bit per visited/settled node. At 500k nodes a bitset is
  about 62.5 KB instead of 500 KB.
- Clipped-tile seam stitching is a correctness pass. It raises merge time from
  about 25 ms to 250 ms for the 33-tile fixture; disable it with
  `stitchingTolerance: 0.0` only when seams are already noded.

## Memory layout

The 3.0 model is intentionally compact:

| Type | Stride |
|---|---:|
| `Coordinate3D` | 56 bytes |
| `Projection` | 8 bytes |
| `BoundingBox` | 64 bytes |
| `Point` | 128 bytes |
| `Feature` | 144 bytes |
| `LineString` | 80 bytes |
| `Polygon` | 80 bytes |
| `FeatureCollection` | 80 bytes |

`BoundingBox` stores scalar X/Y bounds and an optional altitude range. The
linear-reference `m` value is not retained in bounding boxes.

## Benchmarks

The release-mode `Benchmarks` executable covers loading, projection,
predicates, overlay, R-tree, coders, buffer, simplify, hulls, line operations,
tile cover, clipping, graph routing, query, clustering, memory layout and
cross-module inlining.

```bash
# Run every suite and print Markdown
scripts/benchmarks.sh

# Run selected suites
swift run -c release --traits EnableGraphAPI Benchmarks predicates overlay graph
```

The repository also stores platform- and architecture-specific baselines under
`Benchmarks/Baselines/`. See
[DEVELOPMENT.md](https://github.com/Outdooractive/gis-tools/blob/main/DEVELOPMENT.md)
for the complete benchmark and development command reference. Compare the current checkout with the matching
baseline:

```bash
python3 scripts/benchmark_compare.py
```

The command prints current-versus-baseline time and peak-RSS deltas and exits
non-zero above the configured threshold. Refresh a baseline only after
reviewing the change:

```bash
python3 scripts/benchmark_compare.py --update
git diff Benchmarks/Baselines/
```

The manually triggered **Benchmarks** workflow can run the comparison or upload
a new baseline artifact; it is not part of pull-request CI. Benchmark numbers are
machine-specific, so generate a baseline on each platform and architecture you
want to track.

## Next steps

- [Query DSL][query-dsl] for filtering with spatial predicates.
- [Graph API][graph-api] for routing-index usage.

[query-dsl]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/querydsl
[graph-api]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/graphapi
