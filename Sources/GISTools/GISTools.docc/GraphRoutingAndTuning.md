# Graph routing algorithms and tuning

Choose the right routing graph, algorithm and preprocessing index for your
network, and learn which parameters affect build time, memory and query speed.

## Overview

The Graph API is layered. A `Graph` stores nodes and weighted, optionally
directed edges. Routing queries either run directly on that graph or use a
precomputed index that trades build time and memory for faster repeated
queries.

The pipeline is:

```text
FeatureCollection
    -> optional feature filtering (mode, access, surface, ...)
    -> Graph (nodes, edges, weights, one-way rules)
    -> optional contraction
    -> optional routing index (contraction, ALT or multi-level)
    -> query (plain, constrained or custom-cost)
```

Every step is optional. For a single route, a direct search is often the right
choice. For many routes on the same network, an index is usually worth the
preprocessing cost.

## Start with the right graph

### Build the routing graph you actually need

The feature-based constructor processes `LineString` and `MultiLineString`
features and merges nodes within `nodeTolerance` meters. Edges inherit the
original feature and a weight equal to the distance between their endpoints in
the graph's projection: Haversine for EPSG:4326 and Euclidean for the other
projections.

If a routing profile is defined by feature tags, filter the features **before**
building the graph. This is faster than post-filtering query results and lets
the index see only the relevant network.

```swift
func isCycling(_ feature: Feature) -> Bool {
    guard let highway: String = feature.property(for: "highway") else {
        return false
    }

    let access: String? = feature.property(for: "access")
    let bicycle: String? = feature.property(for: "bicycle")
    if access == "no" || access == "private" { return false }
    if bicycle == "no" || bicycle == "private" { return false }

    let cyclingHighways: Set<String> = [
        "cycleway", "residential", "primary", "secondary", "tertiary",
        "service", "living_street", "track", "unclassified", "path", "footway",
    ]
    guard cyclingHighways.contains(highway) else { return false }

    if highway == "footway" || highway == "path" {
        return ["yes", "designated", "permissive", "official"]
            .contains(bicycle ?? "")
    }
    return true
}

let cyclingCollection = FeatureCollection(
    roadNetwork.features.filter(isCycling))
let cyclingGraph = Graph(
    featureCollection: cyclingCollection,
    isDirected: true)
```

Use the same pattern for hiking, driving, cargo bikes or any other profile.
Build one graph and one index per profile.

### Node identities belong to their graph

`Node` equality is based on the node index inside one `Graph`. A node from the
unfiltered graph cannot be used to query a filtered graph, and vice versa.
Resolve endpoints on the graph that owns the index:

```swift
guard let start = cyclingGraph.node(
    at: startCoordinate,
    tolerance: 50.0),
    let end = cyclingGraph.node(
        at: endCoordinate,
        tolerance: 50.0)
else { return }
```

The same rule applies after contraction or subgraph extraction: node indices
refer to the graph that produced them.

### Directed graphs and one-way rules

Set `isDirected: true` to create one-way edges from a truthy `onewayProperty`
(default `"oneway"`). The graph stores one-way edges once and two-way edges
twice. Reverse searches use a reverse adjacency built by the routing index or
query.

If a profile has its own direction rules, normalize them into the configured
`onewayProperty` before graph construction. The graph consults a single
property key.

### Projection

Graphs work in EPSG:4326, EPSG:3857, EPSG:4978 and `noSRID`. Edge weights are
computed in the graph's projection. Distances default to Haversine for
EPSG:4326 and Euclidean for the other projections.

The multi-level index tiles a rectangular grid over the graph's coordinate
extents. For large networks, building the graph in a projected CRS gives more
balanced cells than a latitude/longitude grid.

## Choose an algorithm or index

| Need | Entry point | Preprocessing | Constraints |
| ---- | ----------- | ------------- | ----------- |
| One route | `graph.shortestPath(from:to:)` | None | `blockedNodes`, `edgeFilter` |
| One route, guided search | `graph.aStarPath(from:to:)` | None | `blockedNodes`, `edgeFilter` |
| One route, meet in the middle | `graph.bidirectionalShortestPath(from:to:)` | None | `blockedNodes`, `edgeFilter` |
| Custom scalar cost | `graph.shortestPath(from:to:costFunction:)` | None | `blockedNodes` |
| Several alternatives | `graph.kShortestPaths(from:to:k:)` | None | `blockedNodes`, `edgeFilter` |
| Many routes, moderate graph | `graph.routingIndex()` | Contraction | Falls back for constraints |
| Many routes, ALT heuristic | `graph.landmarkIndex()` | Landmark distances | Supported |
| Many routes, large network | `graph.multiLevelIndex()` | Cell hierarchy and overlays | Falls back for constraints |
| One-off contraction search | `graph.shortestPathViaContraction(from:to:)` | Rebuilds contraction | Falls back for `edgeFilter` |

### Direct searches

`shortestPath` is Dijkstra’s algorithm. It is the reference implementation and
always respects blocked nodes and edge filters.

`aStarPath` uses a distance heuristic. It can explore fewer nodes when the
heuristic matches the network, but on grid-like networks with many equal-cost
routes the heuristic may not help.

`bidirectionalShortestPath` runs two Dijkstra searches and stops when the
frontiers meet. It is often a good general-purpose choice for a single route.

These three options require no preprocessing. Prefer them for one-off queries,
small graphs or queries with constraints.

### Multi-criteria search

Use `shortestPath(from:to:costFunction:blockedNodes:)` when the cost is not the
stored edge weight. The closure returns a scalar cost per edge. Return
`.infinity` to exclude an edge.

```swift
let path = graph.shortestPath(
    from: start,
    to: end,
    costFunction: { edge in
        let distance = edge.weight
        let surface: String? = edge.feature?.property(for: "surface")
        let penalty = surface == "gravel" ? 1.6 : 1.0
        return distance * penalty
    })
```

The multi-criteria search is a Dijkstra variant. It is flexible but slower than
a precomputed index, and the indices cannot use a custom cost function.

### K-shortest paths

`kShortestPaths(from:to:k:)` uses Yen’s algorithm and runs repeated Dijkstra
searches. It is intended for a small number of alternatives, not for bulk
routing.

## Reusable routing indices

Indices are immutable snapshots. They store references to their own graph copy
and must be rebuilt after changing nodes, edges or weights. All indices are
value types and can be copied cheaply; the underlying storage is shared until a
mutation occurs.

### Contraction index

```swift
if let index = graph.routingIndex() {
    let path = index.aStarPath(from: start, to: end)
}
```

`routingIndex()` contracts degree-2 chains once, then routes on the smaller
graph. It exposes `shortestPath`, `aStarPath` and `bidirectionalShortestPath`.

Because contraction merges edges, it cannot preserve per-segment properties.
Queries with `blockedNodes` or `edgeFilter` fall back to the original graph.

### Landmark index

```swift
if let index = graph.landmarkIndex(landmarkCount: 4) {
    let path = index.aStarPath(from: start, to: end)
}
```

The landmark index uses ALT (A*, landmarks, triangle inequality). It
precomputes distances from a small set of landmarks and uses them as an
admissible A* heuristic. Directed graphs additionally use distances against the
reverse graph.

Landmarks are a good choice when many queries run on the same graph and the
network has enough structure for the heuristic to pay off. More landmarks
improve the heuristic but increase build time and memory.

The landmark index accepts `blockedNodes` and `edgeFilter` directly.

### Multi-level index

```swift
if let index = graph.multiLevelIndex(
    levels: 3,
    baseRows: 32,
    baseColumns: 32)
{
    let path = index.shortestPath(from: start, to: end)
}
```

The multi-level Dijkstra (MLD) index partitions the graph into nested
rectangular cells, precomputes sparse boundary overlays for each level, and
answers queries with a level-aware bidirectional search. Near the endpoints it
uses original edges in the endpoint cells; farther away it uses the overlay of
the highest level at which a node is separated from both endpoints.

The index uses the graph’s stored edge weights. It does not accept a custom
cost function, and queries with `blockedNodes` or `edgeFilter` fall back to
plain Dijkstra.

Use MLD for repeated point-to-point queries on a large network where the
preprocessing cost can be amortized. See [Tuning the multi-level index](#tuning-the-multi-level-index)
for the parameters.

## Choosing an approach

A useful decision order:

1. **A few queries and no constraints?** Use `bidirectionalShortestPath` or
   `aStarPath`. Avoid paying for preprocessing.
2. **Many queries on a moderate graph?** Try `landmarkIndex()` first. It has a
   small build cost and very fast queries when the heuristic works.
3. **Many queries on a large graph and build time is acceptable?** Use
   `multiLevelIndex()`, optionally on a contracted graph.
4. **Constraints on every query?** Build a mode-specific graph and index it.
   If constraints are truly dynamic, use plain Dijkstra or
   `landmarkIndex()`.
5. **Custom cost function?** Use the multi-criteria Dijkstra. Precomputed
   indices cannot apply an arbitrary cost function.
6. **Alternatives?** Use `kShortestPaths`.

All of these are exact shortest-path algorithms. The differences are
preprocessing cost, memory and query speed, not result quality.

## Tuning the graph

### Contraction

Degree-2 chains are common in road networks: every vertex of a polyline
becomes a node, even when the road continues straight. Contraction merges those
chains into single edges.

```swift
let contraction = graph.contracted()
let contractedGraph = contraction?.graph
```

`contracted(edgeCompatibility:)` lets you keep boundaries where adjacent edges
differ, for example between road classes:

```swift
let result = graph.contracted { first, second in
    first.feature?.property(for: "highway")
        == second.feature?.property(for: "highway")
}
```

Contraction changes node indices. Use `contractedIndexOfOriginal` to map query
endpoints into the contracted graph and `expandPath(_:using:)` to lift the
result back:

```swift
guard let contraction,
      let startIndex = contraction.contractedIndexOfOriginal[start.index],
      let endIndex = contraction.contractedIndexOfOriginal[end.index],
      let contractedStart = contraction.graph.node(withIndex: startIndex),
      let contractedEnd = contraction.graph.node(withIndex: endIndex)
else { return }

let contractedPath = contraction.graph.shortestPath(
    from: contractedStart,
    to: contractedEnd)
let fullPath = graph.expandPath(contractedPath, using: contraction)
```

`routingIndex()` performs this mapping and expansion internally.

### Mode-specific graphs

For a profile whose eligible edges are stable, build a filtered graph and index
it once. This is usually faster and simpler than applying an edge filter to
every query.

```swift
let modeCollection = FeatureCollection(
    roadNetwork.features.filter(isCycling))
let modeGraph = Graph(
    featureCollection: modeCollection,
    isDirected: true)
let modeIndex = modeGraph.multiLevelIndex(
    levels: 3,
    baseRows: 32,
    baseColumns: 32)
```

Do not mix nodes from `roadNetwork` and `modeGraph`. Resolve endpoints on
`modeGraph`.

### Merge and stitch tiles

If the network comes from tiles, `Graph.merged(_:stitchingTolerance:)`
deduplicates nodes and stitches clipped seams. Seam stitching is a correctness
pass and costs time on large merges. Disable it with
`stitchingTolerance: 0.0` only when the input is already noded.

## Tuning the multi-level index

### `baseRows` and `baseColumns`

These control the finest partition. The important quantity is the number of
boundary nodes per cell, because overlay shortcuts grow roughly quadratically
with it.

Guidance:

- Aim for cells containing roughly a few thousand nodes.
- For a regional network, `32 × 32` is a reasonable starting point.
- If build time or memory is too high, make the base grid **finer** (more,
  smaller cells).
- Avoid very fine grids on tiny graphs; they add bookkeeping without helping.

### `levels`

Higher levels merge `2 × 2` blocks of the previous level. More levels can
reduce query exploration, but they also add build time and overlay memory.

Start with `levels: 3` and measure. If the network is small or the top-level
overlays are expensive, fewer levels may be faster overall.

### Graph size and contraction

The index is usually built after mode filtering. Pre-contracting degree-2
chains, either manually as shown above or through a future integrated option,
reduces nodes, boundary nodes, overlay size and query work.

### Grid-like inputs

Grid-like graphs are the worst case for multi-level overlays: every cell
perimeter node is a boundary node, and the overlays become dense. Real road
networks have much sparser cell boundaries.

On the deterministic 1M-edge grid fixture, the current implementation builds
the index in roughly 16 seconds and answers a query in roughly 150 ms, versus
roughly 90 ms for plain Dijkstra. That does not mean MLD is slow on road
networks; it means the grid is an adversarial input. Measure on your own data.

### Snapshot semantics

The index stores edge weights at build time. Rebuild it after changing:

- node coordinates or topology,
- edge weights,
- one-way properties,
- the underlying feature collection.

## Tuning the landmark index

`landmarkIndex(landmarkCount:)` trades build time and memory for heuristic
quality. Four landmarks are a good default. More landmarks can reduce query
exploration on large networks, but each landmark adds a full distance table.

Landmarks work best when the triangle-inequality bound is tight. On networks
with many equal-cost paths, the heuristic may help less.

## Constraints and custom costs

### Blocked nodes and edge filters

Plain Dijkstra, A*, bidirectional Dijkstra and the landmark index accept
`blockedNodes` and `edgeFilter` directly.

The reusable contraction and multi-level indices fall back to a direct search
for queries whose constraints cannot be represented by the index, because
their preprocessing merges or ignores per-edge properties. If the same profile
restriction is used for every query, build a filtered graph instead; then the
index can be reused without falling back.

### Multi-criteria cost

Use `shortestPath(from:to:costFunction:)` for a scalar cost derived from edge
properties. Return `.infinity` to exclude an edge.

Common examples:

- penalize unpaved surfaces,
- prefer cycleways or footways,
- combine distance and elevation gain,
- avoid busy road classes.

The result is exact for the supplied cost function. The multi-level, landmark
and contraction indices are tied to the graph’s `Edge.weight`.

## Putting it together

### Repeated mode-specific routing

```swift
let modeCollection = FeatureCollection(
    roadNetwork.features.filter(isCycling))
let modeGraph = Graph(
    featureCollection: modeCollection,
    isDirected: true)

guard let index = modeGraph.multiLevelIndex(
    levels: 3,
    baseRows: 32,
    baseColumns: 32)
else { return }

guard let start = modeGraph.node(at: startCoordinate, tolerance: 50.0),
      let end = modeGraph.node(at: endCoordinate, tolerance: 50.0)
else { return }

let path = index.shortestPath(from: start, to: end)
```

### Repeated queries with dynamic constraints

```swift
let path = graph.shortestPath(
    from: start,
    to: end,
    blockedNodes: blocked,
    edgeFilter: { edge in
        let surface: String? = edge.feature?.property(for: "surface")
        return surface != "gravel"
    })
```

This does not use a precomputed index, but it is exact and works for arbitrary
query-specific restrictions.

### Alternatives

```swift
let alternatives = graph.kShortestPaths(
    from: start,
    to: end,
    k: 3)
```

Yen’s algorithm is intended for a handful of alternatives. For bulk routing,
use one of the indices.

## Current implementation notes

The multi-level index is deliberately simple and exact. The main levers if you
need more speed are:

- reuse a query workspace instead of allocating full-size arrays per query,
- store fewer per-node arrays during the search,
- stall-on-demand when a settled node has a cheaper path through another
  settled node,
- add an A* or ALT heuristic to the overlay search,
- use compact CSR overlay storage and share undirected shortcuts,
- build cell overlays in parallel,
- improve partitioning with adaptive or boundary-aware cells,
- add real-world benchmarks and per-level diagnostics to guide defaults.

Some of these require changes to GISTools itself. The public API is designed so
that they can be added without changing how callers build or query an index.

## See also

- [Graph API](doc:GraphAPI) for constructing, merging and exporting graphs.
- [Performance and memory notes](doc:PerformanceAndMemory) for benchmark data
  and memory characteristics.
- [Projections and antimeridian handling](doc:ProjectionsAndAntimeridian) for
  projection and seam behavior.
