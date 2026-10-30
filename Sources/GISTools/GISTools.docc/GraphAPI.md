# Graph API

The graph API builds routing and network-analysis graphs from GeoJSON
`LineString` and `MultiLineString` features. It is opt-in behind the
`EnableGraphAPI` package trait.

## Enable the trait

```swift
.package(
    url: "https://github.com/Outdooractive/gis-tools",
    from: "3.0.0",
    traits: ["EnableGraphAPI"])
```

For local commands, pass `--traits EnableGraphAPI` to `swift build`,
`swift run` or `swift test`. The rest of the library does not require the
trait.

## Build a graph

```swift
var graph = Graph(featureCollection: featureCollection)
let directed = Graph(featureCollection: featureCollection, isDirected: true)
```

Nodes are created at each line-segment endpoint. Coordinates within
`nodeTolerance` (default 1 meter) are merged through a spatial-hash index.
Truthy `oneway` properties create directed edges when `isDirected` is true.
Graphs work in every projection, including antimeridian-crossing data.

Nodes and edges can also be added manually:

```swift
let start = graph.createNode(at: coordinate)
let end = graph.createNode(at: otherCoordinate)
graph.addUndirectedEdge(from: start, to: end)
graph.addDirectedEdge(from: start, to: end)
```

Edges can carry a weight and a reference to the original feature. An optional
edge filter restricts routing by mode, for example hiking or cycling.

## Route

```swift
let path = graph.shortestPath(from: start, to: end)
let length = graph.length(ofPath: path)

let aStar = graph.aStarPath(from: start, to: end)
let bidirectional = graph.bidirectionalShortestPath(from: start, to: end)
let alternatives = graph.kShortestPaths(from: start, to: end, k: 3)
```

For repeated point-to-point queries, precompute a routing index:

```swift
if let index = graph.routingIndex() {
    let path = index.aStarPath(from: start, to: end)
}

if let landmarks = graph.landmarkIndex() {
    let path = landmarks.aStarPath(from: start, to: end)
}
```

The routing index reuses one contraction across queries. The landmark index
uses ALT routing with precomputed landmarks. Both fall back to the graph for
queries that use blocked nodes or edge filters.

## Work with components and subsets

```swift
let components = graph.connectedComponentGraphs
let subgraph = graph.subgraph(containing: [nodeA, nodeB, nodeC])
let pruned = graph.prunedDeadEnds()?.graph
let contracted = graph.contracted()?.graph
```

The graph also exposes breadth-first and depth-first search, cycle detection,
bridges, articulation points, strongly connected components, minimum spanning
trees, Eulerian paths and Chinese Postman tours, traveling-salesperson
approximation, betweenness centrality and graph partitioning.

## Merge tiled networks

```swift
let merged = Graph.merged([tile1, tile2, tile3])
let extended = graph.merged(with: anotherGraph)
```

Merging deduplicates nodes by `nodeTolerance` and removes duplicate edges.
Clipped tile seams are stitched and noded by default: dangling endpoints near a
collinear segment become graph nodes, and overlapping collinear edges are split
and deduplicated. Pass `stitchingTolerance: 0.0` to disable this correctness
pass. The extra preprocessing is visible in large merges; see
[Performance and memory notes][performance].

## Export

```swift
let collection = graph.toFeatureCollection()
```

Each edge becomes a two-point `LineString` feature. Original feature
properties, identifiers and edge weights are preserved, and directed edges get
a `"oneway": "yes"` property.

## Next steps

- [Performance and memory notes][performance] for routing-index and contraction trade-offs.
- [Projections and antimeridian handling][projections] for projection and seam handling.
- [Migrating to GISTools 3.0][migration] for the 3.0 graph trait migration.

[performance]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/performanceandmemory
[projections]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/projectionsandantimeridian
[migration]: https://swiftpackageindex.com/Outdooractive/gis-tools/documentation/gistools/migrationguide
