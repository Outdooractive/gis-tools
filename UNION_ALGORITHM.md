# Polygon Union Algorithm

## Status

- **UnionTests**: 12/12 passing (all pairwise, multi-polygon, edge cases)
- **BufferTests**: 8/10 passing (2 pre‑existing failures — see below)
- **Full suite**: 522/525 passing (3 pre‑existing failures, none caused by Union)

---

## Algorithm Overview

The union uses a **planar‑graph** approach in 6 pipeline stages:

```
Polygons → Extract Edges → Find Intersections → Split Edges
    → Remove Duplicate Pairs → Filter Boundary → Build Rings → Assemble Polygons
```

<div style="display: flex; justify-content: center; margin: 20px 0;">
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 900 620" style="max-width: 100%; height: auto; background: #fff; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
  <defs>
    <marker id="arrow" markerWidth="10" markerHeight="7" refX="10" refY="3.5" orient="auto" fill="#4A90D9">
      <polygon points="0 0, 10 3.5, 0 7" />
    </marker>
    <linearGradient id="boxGrad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#E8F0FE"/>
      <stop offset="100%" stop-color="#D0E2FF"/>
    </linearGradient>
    <linearGradient id="resultGrad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#E8FEE8"/>
      <stop offset="100%" stop-color="#B8F0B8"/>
    </linearGradient>
    <linearGradient id="failGrad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#FFE8E8"/>
      <stop offset="100%" stop-color="#FFD0D0"/>
    </linearGradient>
    <style>
      .stage { font: bold 13px monospace; fill: #1a1a1a; text-anchor: middle; }
      .sub { font: 11px monospace; fill: #555; text-anchor: middle; }
      .label { font: 12px sans-serif; fill: #666; text-anchor: middle; }
      .edge-label { font: 10px sans-serif; fill: #4A90D9; }
    </style>
  </defs>
  <!-- Row 1 -->
  <rect x="320" y="10" width="260" height="44" rx="8" fill="url(#boxGrad)" stroke="#4A90D9" stroke-width="2"/>
  <text x="450" y="38" class="stage">extractEdges()</text>

  <line x1="450" y1="54" x2="450" y2="76" stroke="#4A90D9" stroke-width="2" marker-end="url(#arrow)"/>

  <rect x="320" y="76" width="260" height="44" rx="8" fill="url(#boxGrad)" stroke="#4A90D9" stroke-width="2"/>
  <text x="450" y="104" class="stage">findIntersections()</text>

  <line x1="450" y1="120" x2="450" y2="142" stroke="#4A90D9" stroke-width="2" marker-end="url(#arrow)"/>

  <rect x="320" y="142" width="260" height="44" rx="8" fill="url(#boxGrad)" stroke="#4A90D9" stroke-width="2"/>
  <text x="450" y="170" class="stage">splitEdges()</text>

  <line x1="450" y1="186" x2="450" y2="208" stroke="#4A90D9" stroke-width="2" marker-end="url(#arrow)"/>

  <!-- Branch 1: duplicate removal -->
  <rect x="100" y="208" width="260" height="44" rx="8" fill="url(#boxGrad)" stroke="#4A90D9" stroke-width="2"/>
  <text x="230" y="236" class="stage">removeDuplicatePairs()</text>
  <text x="230" y="249" class="sub">Shared interior edges are removed</text>

  <line x1="450" y1="208" x2="360" y2="208" stroke="#4A90D9" stroke-width="2" marker-end="url(#arrow)"/>

  <line x1="230" y1="252" x2="230" y2="274" stroke="#4A90D9" stroke-width="2" marker-end="url(#arrow)"/>

  <rect x="100" y="274" width="260" height="44" rx="8" fill="url(#boxGrad)" stroke="#4A90D9" stroke-width="2"/>
  <text x="230" y="302" class="stage">isOnUnionBoundary()</text>
  <text x="230" y="315" class="sub">Perpendicular offset test at midpoint</text>

  <line x1="230" y1="318" x2="230" y2="340" stroke="#4A90D9" stroke-width="2" marker-end="url(#arrow)"/>

  <rect x="100" y="340" width="260" height="44" rx="8" fill="url(#boxGrad)" stroke="#4A90D9" stroke-width="2"/>
  <text x="230" y="368" class="stage">buildRings()</text>
  <text x="230" y="381" class="sub">Adjacency graph + proximity fallback</text>

  <line x1="230" y1="384" x2="230" y2="406" stroke="#4A90D9" stroke-width="2" marker-end="url(#arrow)"/>

  <rect x="100" y="406" width="260" height="44" rx="8" fill="url(#resultGrad)" stroke="#2E8B57" stroke-width="2"/>
  <text x="230" y="434" class="stage">assemblePolygons()</text>
  <text x="230" y="447" class="sub">Outer rings + hole assignment</text>

  <line x1="360" y1="430" x2="360" y2="430" stroke="#4A90D9" stroke-width="0"/>

  <!-- Side: intersection detail -->
  <rect x="580" y="76" width="300" height="135" rx="8" fill="#FFF8E1" stroke="#F0C040" stroke-width="1.5" stroke-dasharray="4,3"/>
  <text x="730" y="98" class="sub" style="font-weight: bold; fill: #8B6914;">Intersection snapping detail</text>
  <text x="730" y="116" class="label" style="font-size: 10px;">For each pair (Edgeᵢ, Edgeⱼ):</text>
  <text x="730" y="132" class="label" style="font-size: 10px;">1. Compute raw intersection point (p)</text>
  <text x="730" y="148" class="label" style="font-size: 10px;">2. Check distance(p, all 4 endpoints) in meters</text>
  <text x="730" y="164" class="label" style="font-size: 10px;">3. If &lt; 2m, snap to the closest endpoint;</text>
  <text x="730" y="180" class="label" style="font-size: 10px;">   both edges use the SAME snapped coordinate</text>
  <text x="730" y="196" class="label" style="font-size: 10px;">4. ⚠  Snap decisions are INDEPENDENT per edge</text>

  <!-- Side: vertex key -->
  <rect x="580" y="320" width="300" height="145" rx="8" fill="#F0F0FF" stroke="#8080D0" stroke-width="1.5" stroke-dasharray="4,3"/>
  <text x="730" y="342" class="sub" style="font-weight: bold; fill: #4444AA;">Vertex key system</text>
  <text x="730" y="360" class="label" style="font-size: 10px;">vertexKey(coord) → "lat,lon" at 1e‑6° precision</text>
  <text x="730" y="380" class="label" style="font-size: 10px;">Avoids Hashable contract violation from</text>
  <text x="730" y="396" class="label" style="font-size: 10px;">Coordinate3D's tolerance‑based ==. Used for</text>
  <text x="730" y="412" class="label" style="font-size: 10px;">adjacency dictionary keys in buildRings().</text>
  <text x="730" y="432" class="label" style="font-size: 10px;">⚠  HACK: twin corners get different keys</text>

  <!-- Side: ring fallback -->
  <rect x="580" y="480" width="300" height="125" rx="8" fill="#FFF0E0" stroke="#E08040" stroke-width="1.5" stroke-dasharray="4,3"/>
  <text x="730" y="502" class="sub" style="font-weight: bold; fill: #8B4513;">Proximity fallback</text>
  <text x="730" y="520" class="label" style="font-size: 10px;">When vertex‑key lookup finds no candidate:</text>
  <text x="730" y="540" class="label" style="font-size: 10px;">Scan all unused edges for endpoint within</text>
  <text x="730" y="556" class="label" style="font-size: 10px;">5e‑6° (≈0.5m). Bridges the gap from</text>
  <text x="730" y="572" class="label" style="font-size: 10px;">independent snapping in findIntersections().</text>
  <text x="730" y="592" class="label" style="font-size: 10px;">⚠  Can connect wrong edges → wrong rings</text>

  <!-- Side: known issues -->
  <rect x="580" y="540" width="300" height="65" rx="8" fill="url(#failGrad)" stroke="#D04040" stroke-width="2"/>
  <text x="730" y="562" class="sub" style="font-weight: bold; fill: #8B0000;">Pre‑existing failures</text>
  <text x="730" y="580" class="label" style="font-size: 10px;">bufferedPolygon:  ratio 0.13</text>
  <text x="730" y="596" class="label" style="font-size: 10px;">bufferedMultiPolygon: ratio 0.38</text>
</svg>
</div>

---

## Pipeline Stages

### 1. Edge Extraction (`extractEdges`, line 96)

Decomposes each polygon ring into directed edges tagged with the source polygon index.

```swift
for (pIndex, polygon) in polygons.enumerated() {
    for ring in polygon.rings {
        for i in 0..<(coords.count - 1) {
            edges.append(Edge(start: coords[i], end: coords[i+1], polygonIndex: pIndex))
        }
    }
}
```

### 2. Intersection Detection (`findIntersections`, line 116)

For every edge pair from **different** polygons, compute the `LineSegment.intersection()`. Key details:

- Uses `epsilon: 1.0e-12` to avoid missing near‑intersections.
- **Snapping**: If the raw intersection is within `snapEpsMeters = 2.0` meters of **any** of the four endpoints (both edges' start and end), the coordinate is replaced with that endpoint coordinate.
- **Independent per edge**: Each edge's snapped coordinate is computed independently — Edgeᵢ may snap but Edgeⱼ may not, or they may snap to different endpoints. This produces **asymmetric coordinates** for what should be the same geometric vertex.

```swift
if di0 < snapEpsMeters { pointI = edges[i].start }
else if di1 < snapEpsMeters { pointI = edges[i].end }
else { pointI = raw }

if dj0 < snapEpsMeters { pointJ = edges[j].start }
else if dj1 < snapEpsMeters { pointJ = edges[j].end }
else { pointJ = raw }
```

After collection, splits are **deduplicated**: same edge index + near‑identical `distanceAlong` → keep one.

### 3. Edge Splitting (`splitEdges`, line 196)

Sorts splits by `distanceAlong` (t‑parameter) per edge and slices each edge at those points, discarding splits at t ≤ 0 or t ≥ 1. Produces a new set of edges where all polygon‑polygon intersection points are explicit vertices.

### 4. Duplicate Removal (`removeDuplicatePairs`, line 235)

Finds pairs of edges that are identical but in opposite directions (`A.start == B.end && A.end == B.start`). These represent shared boundaries that become **interior** to the union and are removed.

Uses `Coordinate3D.==` with tolerance `GISTool.equalityDelta = 1e-10`. This means micro‑segments with coordinates differing by ~4e-6° (~0.3m) may **NOT** be detected as duplicates.

### 5. Boundary Filter (`isOnUnionBoundary`, line 264)

Classifies each remaining edge using a **perpendicular offset test**:

```swift
let eps = 1.0e-8  // ≈1mm offset
let leftPoint  = midpoint + perpendicular * eps
let rightPoint = midpoint - perpendicular * eps
```

If `leftInside != rightInside`, one side is inside the union and the other is outside → the edge is on the boundary. Edges kept, others are discarded.

### 6. Ring Construction (`buildRings`, line 294)

Builds closed rings from the boundary edges using a **graph‑based adjacency walk**:

```
adjacency[vertexKey] → [edgeIndex, ...]
```

Starting from any unused edge, follow the chain by matching the current endpoint key to the next edge's start or end key.

**Key system** (`vertexKey`, line 59): Rounds coordinates to `1e-6°` (≈0.1m) precision to produce string keys. This works around `Coordinate3D`'s broken `Hashable` contract (tolerance‑based `==` but auto‑synthesised `hashValue`).

**Proximity fallback** (line 341): When the key‑based adjacency lookup finds no candidate (the 0.3m gap case), scans all remaining unused edges for an endpoint within `snapEpsDegrees = 5e-6` (≈0.5m). This bridges the coordinate gaps from asymmetric intersection snapping.

```swift
if !found {
    // Proximity fallback: find any unused edge with endpoint
    // within 5e-6 degrees of the current coordinate
    for (i, e) in edges.enumerated() where !used.contains(i) {
        let dStart = hypot(e.start.latitude - cur.latitude,
                           e.start.longitude - cur.longitude)
        let dEnd = hypot(e.end.latitude - cur.latitude,
                         e.end.longitude - cur.longitude)
        // ... pick the closest within snapEpsDegrees
    }
}
```

### 7. Polygon Assembly (`assemblePolygons`, line 381)

Computes ring area (signed): **negative** → outer ring, **positive** → hole. Assigns holes to the containing outer ring. Uncontained positive‑area rings become standalone polygons (e.g., disjoint union components).

---

## Known Problems

### 1. Proximity fallback can connect wrong edges

The 5e-6° (0.5m) proximity threshold is a **blunt instrument**. In dense geometry (e.g., buffer output with many small polygons close together), the fallback may match an edge that should be connected to a *different* vertex within the same tolerance radius. This produces:

- **Buggy `bufferedPolygon`**: ratio 0.13 (87% area loss)
- **Buggy `bufferedMultiPolygon`**: ratio 0.38 (62% area loss)

Both are pre‑existing failures: the original codebase had 5/10 BufferTests failing. The proximity fallback *reduced* this to 2/10 but didn't fix it completely.

**Potential fix**: Replace the proximity fallback with a **correct intersection‑snapping algorithm**. The root cause is in `findIntersections` — the independent per-edge snapping that creates the 0.3m coordinate gap. More principled options:

| Approach | Pros | Cons |
|----------|------|------|
| **Both edges always use raw** | Simple, symmetric | Creates micro‑segments near endpoints (t≈0, t≈1) that need duplicate‑pair matching at coarser precision |
| **Both edges use the SAME snapped coord** | Symmetric, no gap | Need to decide *which* endpoint to snap to when both are close but different |
| **Graph‑based dedup after splitting** | Works for any geometry | More complex; merge near‑identical vertices in the final graph |
| **Use `removeDuplicatePairs` with tolerance** | Simple | Currently uses 1e-10; bumping to 1e-5 may merge non‑duplicate edges |

### 2. Coordinate3D Hashable contract violation

`Coordinate3D` defines `==` with `GISTool.equalityDelta = 1e-10` tolerance, but the compiler‑synthesised `hashValue` uses exact floating‑point bits. Two coordinates that are `==` can have different hashes. The `vertexKey` hack (string keys at 1e-6° precision) works around this but is fragile: changing the key precision can break all tests.

### 3. `removeDuplicatePairs` uses exact `==`

Line 243:

```swift
if edges[i].start == edges[j].end && edges[i].end == edges[j].start
```

Micro‑segments created by endpoint‑proximate splits may not match because their coordinates differ by ~4e-6° (0.3m). Using `vertexKey` comparison here would help but risks false positives.

### 4. No colinear‑edge dedup

The algorithm does not currently merge colinear edges after splitting, which can produce extra vertices (cosmetic) or, in degenerate cases, break ring closure.

### 5. Boundary test uses fixed offset

`isOnUnionBoundary` uses a hard‑coded `1.0e-8°` (≈1mm) perpendicular offset. For very small polygons (cm‑scale), this offset may be too large relative to the polygon size, causing misclassification.

---

## Project Structure

```
Sources/GISTools/Algorithms/
  Union.swift              ← The main file (440 lines)
  LineIntersect.swift      ← LineSegment.intersection()
  Buffer.swift             ← Buffer algorithm (uses Union)
  BooleanPointInPolygon.swift  ← Used by isOnUnionBoundary()
  LineSegments.swift       ← LineSegment type

Tests/GISToolsTests/
  Algorithms/UnionTests.swift  ← 12 tests
  TestData/Union/
    LongLineFlatParts.geojson              ← 7 component polygons
    Pairwise/                              ← 9 ground-truth union results
    (other test files for basic cases)

Test tolerances:
  UnionTests.checkGeometric():      1% (0.01)
  pairwiseUnion():                  1% (0.01)
  isOnUnionBoundary offset:         1.0e-8°
  intersection epsilon:             1.0e-12
  intersection snap distance:       2.0 meters
  vertexKey precision:              1.0e-6°
  ring builder proximity threshold: 5.0e-6°
```

---

## Reproducing Test Results

```bash
# All UnionTests
swift test --filter "UnionTests"

# All BufferTests (2 pre-existing failures expected)
swift test --filter "BufferTests"

# Full suite
swift test

# Individual pairwise test
swift test --filter "pairwiseUnion" 2>&1 | grep -E "(pass|fail|ratio)"
```

## Next Steps

1. **Fix `findIntersections` snapping** — the highest‑priority issue. Both edges must split at the *same* geometric coordinate. The simplest correct approach: always use `raw` and rely on improved dedup to remove near‑endpoint micro‑segments.
2. **Improve `removeDuplicatePairs`** — use tolerance‑based matching (e.g., `vertexKey` comparison) to catch micro‑segments that should cancel out.
3. **Remove proximity fallback** in `buildRings` once the snapping fix ensures vertex keys always match.
4. **Clean up `vertexKey` precision** — once the Hashable hack can be removed, consider implementing a proper `Hashable` conformance on `Coordinate3D`.
