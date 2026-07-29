# Graph algorithms — implementation backlog

A prioritized list of graph algorithms to implement for the GISTools library,
grouped by use case. Algorithms already implemented are marked ✓.

## Routing & navigation

- [ ] **A\* search** — Dijkstra with a straight-line-distance heuristic;
      dramatically faster for point-to-point routing (the most common real-world
      use case). The heuristic is naturally geographic.
- [ ] **Bidirectional Dijkstra/A\*** — Search from both ends, meeting in the
      middle; ~2x speedup. Standard in production routing engines.
- [ ] **K-shortest paths (Yen's algorithm)** — Find the top-K routes between
      two points; essential for "alternative routes" in navigation apps.
- [ ] **Multi-criteria shortest path** — Weight edges by a combination of
      distance, travel time, elevation gain, road class, etc. (e.g., a cycling
      route that avoids steep hills). The current `edgeFilter` is binary; a
      weighted cost function is more flexible.

## Graph simplification & cleanup

- [ ] **Chain contraction** — Remove degree-2 nodes by merging their edges
      into a single edge. The Immenstadt graph has ~2255 nodes but many are
      just intermediate points on straight roads; contraction could reduce this
      significantly while preserving topology. Speeds up all subsequent
      algorithms.
- [ ] **Dead-end pruning** — Detect and optionally remove cul-de-sacs and stub
      roads. Useful for network cleanup before analysis.
- [ ] **Graph partitioning** — Split a large graph into tiles/regions for
      parallel processing (relevant to the vector-tile workflow).

## Network analysis

- [ ] **Bridge detection** — Edges whose removal disconnects the graph.
      Identifies critical road segments with no alternative route.
- [ ] **Articulation point detection** — Nodes whose removal disconnects the
      graph. Identifies critical intersections.
- [ ] **Betweenness centrality** — How often a node appears on shortest paths
      between other nodes. Identifies the most important intersections in a
      road network.
- [ ] **Strongly connected components (Tarjan/Kosaraju)** — For directed
      graphs, finds groups of mutually reachable nodes. Useful for analyzing
      one-way street systems and detecting unreachable areas.
- [ ] **Minimum spanning tree (Kruskal/Prim)** — Connect points with minimal
      total edge length. Useful for utility network design, trail planning.

## Route optimization

- [ ] **Eulerian path / Chinese Postman** — Route that traverses every edge
      at least once with minimal repetition. Classic use: snow plowing, street
      sweeping, mail delivery.
- [ ] **TSP approximation (nearest neighbor, 2-opt)** — Visit a set of nodes
      with minimal total distance. Useful for delivery route planning,
      inspection routes.

## Already implemented

- [x] Dijkstra (binary heap)
- [x] Cycle detection (curvature-constrained, canonical dedup)
- [x] BFS / DFS
- [x] Connected components
- [x] Roundabout detection (greedy ring walk + curvature validation)
- [x] Node-on-edge splitting (perpendicular foot)
- [x] Spatial hash index for node deduplication
- [x] Directed graph support (oneway edges)
- [x] Edge-filter routing (hiking/cycling)

## Suggested implementation order

| Priority | Algorithm | Rationale |
|----------|-----------|-----------|
| 1 | A\* search | Immediate routing speedup; natural fit for geo data |
| 2 | Chain contraction | Reduces graph size; speeds up all other algorithms |
| 3 | K-shortest paths | Alternative routes; builds on A\* |
| 4 | Bridge detection | Simple, high-value network analysis |
| 5 | Articulation points | Pairs with bridge detection |
| 6 | Bidirectional search | Further routing speedup |
| 7 | Dead-end pruning | Network cleanup |
| 8 | Strongly connected components | Directed-graph analysis |
| 9 | Betweenness centrality | Network importance ranking |
| 10 | Minimum spanning tree | Utility/trail planning |
| 11 | Multi-criteria shortest path | Advanced routing |
| 12 | Eulerian path / Chinese Postman | Route coverage |
| 13 | TSP approximation | Route planning |
| 14 | Graph partitioning | Parallel processing |