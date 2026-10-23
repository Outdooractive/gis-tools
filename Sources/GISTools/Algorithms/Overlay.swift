#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: - Shared overlay infrastructure

/// Shared implementation for polygon overlay operations (union, intersection, etc.).
/// All geometry is reprojected to EPSG:3857 for uniform Cartesian tolerances.
/// This limits the usable latitude range to approximately ±85°.
enum Overlay {

    // MARK: - Types

    struct Edge {

        let start: Coordinate3D
        let end: Coordinate3D
        let polygonIndex: Int
        var boundingBox: BoundingBox?

        init(start: Coordinate3D, end: Coordinate3D, polygonIndex: Int) {
            self.start = start
            self.end = end
            self.polygonIndex = polygonIndex
            self.boundingBox = BoundingBox(coordinates: [start, end])
        }

    }

    struct SplitPoint {

        let coordinate: Coordinate3D
        let edgeIndex: Int
        let distanceAlong: Double

    }

    /// A coordinate frame in which no ring crosses the wraparound axis.
    /// Overlay operates on these polygons and wraps the result back afterwards.
    struct AntimeridianFrame {

        let polygons: [Polygon]
        let width: Double?
        let extent: Double?

        func denormalize(_ result: MultiPolygon) -> MultiPolygon {
            guard let width, let extent else { return result }

            let polygons = result.polygons.map { polygon in
                let rings = polygon.coordinates.map { ring in
                    ring.map { coordinate in
                        var x = coordinate.x
                        while x > extent {
                            x -= width
                        }
                        while x < -extent {
                            x += width
                        }
                        return Overlay.coordinate(coordinate, x: x)
                    }
                }
                return Polygon(unchecked: rings, calculateBoundingBox: false)
            }
            return MultiPolygon(unchecked: polygons)
        }

    }

    /// A uniform-grid index over polygons for repeated point containment tests.
    struct PolygonIndex: Sendable {

        let polygons: [Polygon]

        private let prepared: [OverlayPreparedPolygon]
        private let grid: Grid

        init(_ polygons: [Polygon]) {
            self.polygons = polygons
            self.prepared = polygons.map { OverlayPreparedPolygon(polygon: $0) }
            self.grid = Grid(polygons: polygons)
        }

        /// Returns `true` if any indexed polygon contains the point.
        func contains(_ point: Coordinate3D) -> Bool {
            for index in grid.large where prepared[index].contains(point) {
                return true
            }

            guard let cell = grid.cellIndex(for: point) else { return false }

            return grid.cells[cell].contains { prepared[$0].contains(point) }
        }

        /// Returns `true` if the polygon at `index` contains the point.
        func contains(_ point: Coordinate3D, polygonAt index: Int) -> Bool {
            prepared.indices.contains(index) && prepared[index].contains(point)
        }

        /// Returns `true` if any indexed polygon except `index` contains the point.
        func contains(_ point: Coordinate3D, excluding index: Int) -> Bool {
            for candidate in grid.large where candidate != index && prepared[candidate].contains(point) {
                return true
            }

            guard let cell = grid.cellIndex(for: point) else { return false }

            return grid.cells[cell].contains {
                $0 != index && prepared[$0].contains(point)
            }
        }

        /// Returns `true` if any polygon in `range` contains the point.
        func contains(_ point: Coordinate3D, in range: Range<Int>) -> Bool {
            range.contains { contains(point, polygonAt: $0) }
        }

        /// A flat uniform grid of polygon indices, plus polygons too large to
        /// index efficiently.
        private struct Grid: Sendable {

            private static let maxCellsPerPolygon = 256

            let originX: Double
            let originY: Double
            let cellWidth: Double
            let cellHeight: Double
            let columns: Int
            let rows: Int
            let cells: [[Int]]
            let large: [Int]

            struct Box {

                let minX: Double
                let minY: Double
                let maxX: Double
                let maxY: Double

            }

            init(polygons: [Polygon]) {
                var boxes: [(index: Int, box: Box)] = []
                boxes.reserveCapacity(polygons.count)

                for (index, polygon) in polygons.enumerated() {
                    let coordinates = polygon.allCoordinates
                    guard let first = coordinates.first else { continue }

                    var minX = first.x
                    var minY = first.y
                    var maxX = first.x
                    var maxY = first.y

                    for coordinate in coordinates.dropFirst() {
                        minX = min(minX, coordinate.x)
                        minY = min(minY, coordinate.y)
                        maxX = max(maxX, coordinate.x)
                        maxY = max(maxY, coordinate.y)
                    }

                    boxes.append((index, Box(minX: minX, minY: minY, maxX: maxX, maxY: maxY)))
                }

                guard let first = boxes.first?.box else {
                    self.originX = 0.0
                    self.originY = 0.0
                    self.cellWidth = 1.0
                    self.cellHeight = 1.0
                    self.columns = 1
                    self.rows = 1
                    self.cells = [[]]
                    self.large = []
                    return
                }

                let minX = boxes.reduce(first.minX) { min($0, $1.box.minX) }
                let minY = boxes.reduce(first.minY) { min($0, $1.box.minY) }
                let maxX = boxes.reduce(first.maxX) { max($0, $1.box.maxX) }
                let maxY = boxes.reduce(first.maxY) { max($0, $1.box.maxY) }

                let side = max(8, min(64, Int(sqrt(Double(max(polygons.count, 1))))))
                let columns = side
                let rows = side
                let cellWidth = max((maxX - minX) / Double(columns), .leastNonzeroMagnitude)
                let cellHeight = max((maxY - minY) / Double(rows), .leastNonzeroMagnitude)

                var cells = Array(repeating: [Int](), count: columns * rows)
                var large: [Int] = []

                for (index, box) in boxes {
                    let minColumn = Self.column(box.minX, origin: minX, cellSize: cellWidth, count: columns)
                    let maxColumn = Self.column(box.maxX, origin: minX, cellSize: cellWidth, count: columns)
                    let minRow = Self.row(box.minY, origin: minY, cellSize: cellHeight, count: rows)
                    let maxRow = Self.row(box.maxY, origin: minY, cellSize: cellHeight, count: rows)

                    let cellCount = (maxColumn - minColumn + 1) * (maxRow - minRow + 1)
                    if cellCount > Self.maxCellsPerPolygon {
                        large.append(index)
                        continue
                    }

                    for row in minRow ... maxRow {
                        for column in minColumn ... maxColumn {
                            cells[row * columns + column].append(index)
                        }
                    }
                }

                self.originX = minX
                self.originY = minY
                self.cellWidth = cellWidth
                self.cellHeight = cellHeight
                self.columns = columns
                self.rows = rows
                self.cells = cells
                self.large = large
            }

            func cellIndex(for point: Coordinate3D) -> Int? {
                guard columns > 0, rows > 0 else { return nil }

                let column = min(max(Int(floor((point.x - originX) / cellWidth)), 0), columns - 1)
                let row = min(max(Int(floor((point.y - originY) / cellHeight)), 0), rows - 1)

                return row * columns + column
            }

            private static func column(
                _ value: Double,
                origin: Double,
                cellSize: Double,
                count: Int
            ) -> Int {
                min(max(Int((value - origin) / cellSize), 0), count - 1)
            }

            private static func row(
                _ value: Double,
                origin: Double,
                cellSize: Double,
                count: Int
            ) -> Int {
                min(max(Int((value - origin) / cellSize), 0), count - 1)
            }

        }

    }

    // MARK: - Public API

    /// Perform a polygon overlay operation.
    ///
    /// The overlay algorithm operates on native XY values. Inputs are
    /// expected in EPSG:3857 for consistent meter-scale tolerances
    /// (callers such as ``Union.unionPolygons`` handle projection).
    ///
    /// Antimeridian-crossing inputs are unwrapped into a continuous
    /// coordinate frame before the overlay and wrapped back afterwards. A
    /// ``PolygonIndex`` over the normalized polygons is passed to
    /// `boundaryTest`, so the test always sees the same frame as the edges.
    ///
    /// - Parameters:
    ///   - polygons: The input polygons.
    ///   - boundaryTest: Returns `true` when an edge is part of the result boundary.
    /// - Returns: A MultiPolygon representing the overlay result, or `nil` if empty.
    static func overlayPolygons(
        _ polygons: [Polygon],
        boundaryTest: (Edge, PolygonIndex) -> Bool
    ) -> MultiPolygon? {
        guard polygons.isNotEmpty else { return nil }

        let frame = antimeridianFrame(for: polygons)
        let normalized = frame.polygons

        guard normalized.count > 1 else {
            return frame.denormalize(MultiPolygon(unchecked: normalized))
        }

        let allEdges = extractEdges(from: normalized)
        guard allEdges.isNotEmpty else { return nil }

        let intersections = findIntersections(between: allEdges)
        let splitEdges = splitEdges(allEdges, at: intersections)
        guard splitEdges.isNotEmpty else { return nil }

        let polygonIndex = PolygonIndex(normalized)
        let boundary = splitEdges.filter { edge in
            boundaryTest(edge, polygonIndex)
        }
        guard boundary.isNotEmpty else { return nil }

        let mergedBoundary = mergeReversePairs(boundary)
        guard mergedBoundary.isNotEmpty else { return nil }

        let rings = buildRings(from: mergedBoundary)
        let result = assemblePolygons(from: rings)
        guard result.isNotEmpty else { return nil }

        return frame.denormalize(MultiPolygon(unchecked: result))
    }

    // MARK: - Boundary test helpers

    /// Create a boundary test closure that compares the "inside result" status
    /// on both sides of each edge. An edge is part of the result boundary when
    /// the two sides have different "inside result" status.
    ///
    /// - Parameter isInsideResult: Returns `true` if a point is inside the
    ///   overlay result region.
    /// - Returns: A boundary test closure for ``overlayPolygons(_:boundaryTest:)``.
    static func makeBoundaryTest(
        isInsideResult: @escaping (Coordinate3D, PolygonIndex) -> Bool
    ) -> (Edge, PolygonIndex) -> Bool {
        { edge, polygons in
            let midLongitude = (edge.start.longitude + edge.end.longitude) * 0.5
            let midLatitude = (edge.start.latitude + edge.end.latitude) * 0.5
            let dx = edge.end.longitude - edge.start.longitude
            let dy = edge.end.latitude - edge.start.latitude

            let (left, right) = offsetPerpendicular(
                midLongitude: midLongitude,
                midLatitude: midLatitude,
                dx: dx,
                dy: dy,
                distance: 0.001)

            return isInsideResult(left, polygons) != isInsideResult(right, polygons)
        }
    }

    /// Offset a point perpendicular to an edge direction.
    /// Returns two points offset by `distance` meters to the left and right.
    static func offsetPerpendicular(
        midLongitude: Double,
        midLatitude: Double,
        dx: Double,
        dy: Double,
        distance: CLLocationDistance
    ) -> (left: Coordinate3D, right: Coordinate3D) {
        let len = sqrt(dx * dx + dy * dy)
        guard len > 0 else {
            let p = Coordinate3D.epsg3857(x: midLongitude, y: midLatitude)
            return (p, p)
        }

        let offsetX = -dy / len * distance
        let offsetY = dx / len * distance
        let left = Coordinate3D.epsg3857(x: midLongitude + offsetX, y: midLatitude + offsetY)
        let right = Coordinate3D.epsg3857(x: midLongitude - offsetX, y: midLatitude - offsetY)
        return (left, right)
    }

}

// MARK: - BoundingBoxRepresentable

extension Overlay.Edge: BoundingBoxRepresentable {

    var projection: Projection {
        start.projection
    }

    func calculateBoundingBox() -> BoundingBox? {
        BoundingBox(coordinates: [start, end])
    }

    func intersects(_ otherBoundingBox: BoundingBox) -> Bool {
        boundingBox?.intersects(otherBoundingBox) ?? true
    }

}

// MARK: - Private helpers

private struct IndexedEdge: BoundingBoxRepresentable {

    let index: Int
    var boundingBox: BoundingBox?

    var projection: Projection {
        boundingBox?.projection ?? .epsg3857
    }

    func calculateBoundingBox() -> BoundingBox? {
        boundingBox
    }

    func intersects(_ otherBoundingBox: BoundingBox) -> Bool {
        boundingBox?.intersects(otherBoundingBox) ?? false
    }

}

extension Overlay {

    // MARK: - Antimeridian normalization

    /// Returns a frame in which no ring crosses the wraparound axis.
    ///
    /// Only invoked when at least one ring crosses the seam. Each ring is
    /// unwrapped by taking the shortest path across the seam, and then every
    /// polygon is aligned to the first polygon's frame by whole world-width
    /// shifts. Polygons with a deliberately world-spanning edge are left
    /// untouched, since cutting them is ambiguous (RFC 7946). Two separate
    /// polygons on opposite sides of the seam that do not themselves cross it
    /// are not joined; they are treated as far apart.
    fileprivate static func antimeridianFrame(for polygons: [Polygon]) -> AntimeridianFrame {
        guard let extent = polygons.first?.projection.wraparoundExtent else {
            return AntimeridianFrame(polygons: polygons, width: nil, extent: nil)
        }

        let width = 2.0 * extent
        let hasCrossingRing = polygons.contains { $0.crossesAntimeridian }
        let hasWorldSpanningEdge = polygons.contains { polygon in
            polygon.rings.contains { ring in
                zip(ring.coordinates, ring.coordinates.dropFirst()).contains { pair in
                    abs(pair.1.x - pair.0.x) >= (width - GISTool.intersectionEpsilon)
                }
            }
        }

        guard hasCrossingRing, !hasWorldSpanningEdge else {
            return AntimeridianFrame(polygons: polygons, width: nil, extent: nil)
        }

        let unwrapped = polygons.map { unwrap($0, width: width, extent: extent) }
        guard let first = unwrapped.first else {
            return AntimeridianFrame(polygons: polygons, width: nil, extent: nil)
        }

        let reference = centerX(of: first)
        let aligned = unwrapped.map { polygon in
            let shift = ((reference - centerX(of: polygon)) / width).rounded() * width
            return translate(polygon, by: shift)
        }

        return AntimeridianFrame(polygons: aligned, width: width, extent: extent)
    }

    fileprivate static func unwrap(_ polygon: Polygon, width: Double, extent: Double) -> Polygon {
        let rings = polygon.coordinates.map { unwrapRing($0, width: width, extent: extent) }
        return Polygon(unchecked: rings, calculateBoundingBox: false)
    }

    fileprivate static func unwrapRing(_ ring: [Coordinate3D], width: Double, extent: Double) -> [Coordinate3D] {
        guard let first = ring.first else { return ring }

        var result: [Coordinate3D] = [first]
        var previous = first

        for coordinate in ring.dropFirst() {
            var x = coordinate.x
            var dx = x - previous.x

            while dx > extent {
                x -= width
                dx = x - previous.x
            }
            while dx < -extent {
                x += width
                dx = x - previous.x
            }

            let unwrapped = Self.coordinate(coordinate, x: x)
            result.append(unwrapped)
            previous = unwrapped
        }

        // A ring may end one world-width away from its start after unwrapping.
        if let last = result.last, result.count > 1 {
            let worlds = ((last.x - first.x) / width).rounded()
            if abs(worlds) >= 1.0 {
                let offset = worlds * width
                result = result.map { Self.coordinate($0, x: $0.x - offset) }
            }
        }

        return result
    }

    fileprivate static func centerX(of polygon: Polygon) -> Double {
        let xs = polygon.allCoordinates.map(\.x)
        guard let minX = xs.min(), let maxX = xs.max() else { return 0.0 }

        return (minX + maxX) / 2.0
    }

    fileprivate static func translate(_ polygon: Polygon, by offset: Double) -> Polygon {
        guard offset != 0.0 else { return polygon }

        let rings = polygon.coordinates.map { ring in
            ring.map { Self.coordinate($0, x: $0.x + offset) }
        }
        return Polygon(unchecked: rings, calculateBoundingBox: false)
    }

    fileprivate static func coordinate(_ coordinate: Coordinate3D, x: Double) -> Coordinate3D {
        Coordinate3D(
            x: x,
            y: coordinate.y,
            z: coordinate.altitude,
            m: coordinate.m,
            projection: coordinate.projection)
    }

    // MARK: - Edge extraction

    fileprivate static func extractEdges(from polygons: [Polygon]) -> [Edge] {
        var edges: [Edge] = []
        for (pIndex, polygon) in polygons.enumerated() {
            let rings = polygon.rings
            for ring in rings {
                let coords = ring.coordinates
                for i in 0 ..< (coords.count - 1) {
                    let start = coords[i]
                    let end = coords[i + 1]
                    if start != end {
                        edges.append(Edge(start: start, end: end, polygonIndex: pIndex))
                    }
                }
            }
        }
        return edges
    }

    // MARK: - Intersection finding

    fileprivate static func findIntersections(between edges: [Edge]) -> [SplitPoint] {
        var result: [SplitPoint] = []
        let splitEps = GISTool.equalityDelta

        let indexedEdges = edges.enumerated().map { i, e in
            IndexedEdge(index: i, boundingBox: e.boundingBox)
        }
        let tree = RTree(indexedEdges)

        for i in 0 ..< edges.count {
            guard let bbI = edges[i].boundingBox else { continue }

            let candidates = tree.search(inBoundingBox: bbI)

            for candidate in candidates {
                let j = candidate.index
                guard j > i else { continue }
                guard edges[i].polygonIndex != edges[j].polygonIndex else { continue }

                let segI = LineSegment(first: edges[i].start, second: edges[i].end)
                let segJ = LineSegment(first: edges[j].start, second: edges[j].end)

                // Overlay coordinates are metres. Use a micron-scale tolerance
                // for near-collinearity: tight enough not to disturb dense
                // buffer geometry, loose enough to absorb projection rounding
                // differences between platforms.
                let tolerance = 0.000001

                // Split each edge at the other edge's endpoints. This covers
                // collinear overlaps (where there is no single intersection
                // point) and near-collinear overlaps caused by projection
                // rounding differences between platforms.
                for point in [edges[j].start, edges[j].end]
                    where pointLiesOnEdge(point, edges[i], tolerance: tolerance)
                {
                    let dI = distanceAlong(edges[i], at: point)
                    if dI > splitEps, dI < 1.0 - splitEps {
                        result.append(SplitPoint(coordinate: point, edgeIndex: i, distanceAlong: dI))
                    }
                }

                for point in [edges[i].start, edges[i].end]
                    where pointLiesOnEdge(point, edges[j], tolerance: tolerance)
                {
                    let dJ = distanceAlong(edges[j], at: point)
                    if dJ > splitEps, dJ < 1.0 - splitEps {
                        result.append(SplitPoint(coordinate: point, edgeIndex: j, distanceAlong: dJ))
                    }
                }

                if let raw = segI.intersection(segJ, epsilon: GISTool.intersectionEpsilon) {
                    let dI = distanceAlong(edges[i], at: raw)
                    if dI > splitEps, dI < 1.0 - splitEps {
                        result.append(SplitPoint(coordinate: raw, edgeIndex: i, distanceAlong: dI))
                    }

                    let dJ = distanceAlong(edges[j], at: raw)
                    if dJ > splitEps, dJ < 1.0 - splitEps {
                        result.append(SplitPoint(coordinate: raw, edgeIndex: j, distanceAlong: dJ))
                    }
                }
            }
        }

        var pointsByEdge = Array(repeating: [SplitPoint](), count: edges.count)
        for splitPoint in result {
            pointsByEdge[splitPoint.edgeIndex].append(splitPoint)
        }

        var deduped: [SplitPoint] = []
        for var points in pointsByEdge {
            guard points.isNotEmpty else { continue }

            points.sort { $0.distanceAlong < $1.distanceAlong }

            var previousDistance = -Double.infinity
            for point in points where point.distanceAlong - previousDistance >= splitEps {
                deduped.append(point)
                previousDistance = point.distanceAlong
            }
        }
        return deduped
    }

    /// Returns `true` when `point` lies on `edge` within the given tolerance
    /// (in the edge's coordinate units, i.e. metres for overlay).
    fileprivate static func pointLiesOnEdge(
        _ point: Coordinate3D,
        _ edge: Edge,
        tolerance: Double
    ) -> Bool {
        let dx = edge.end.x - edge.start.x
        let dy = edge.end.y - edge.start.y
        let length = hypot(dx, dy)
        guard length > 0.0 else { return false }

        let offsetX = point.x - edge.start.x
        let offsetY = point.y - edge.start.y
        let cross = abs((offsetX * dy) - (offsetY * dx)) / length
        guard cross <= tolerance else { return false }

        let dot = (offsetX * dx) + (offsetY * dy)
        return dot >= (-tolerance * length)
            && dot <= ((length * length) + (tolerance * length))
    }

    /// Returns the signed parameter t along the edge, where t=0 is start and t=1 is end.
    fileprivate static func distanceAlong(
        _ edge: Edge,
        at point: Coordinate3D
    ) -> Double {
        let dx = edge.end.longitude - edge.start.longitude
        let dy = edge.end.latitude - edge.start.latitude
        let lengthSq = dx * dx + dy * dy

        guard lengthSq > 0 else { return 0.0 }

        let px = point.longitude - edge.start.longitude
        let py = point.latitude - edge.start.latitude
        return (px * dx + py * dy) / lengthSq
    }

    // MARK: - Edge splitting

    fileprivate static func splitEdges(
        _ edges: [Edge],
        at splitPoints: [SplitPoint]
    ) -> [Edge] {
        guard splitPoints.isNotEmpty else { return edges }

        var splitsByEdge: [Int: [SplitPoint]] = [:]
        for sp in splitPoints {
            splitsByEdge[sp.edgeIndex, default: []].append(sp)
        }
        for (index, var splits) in splitsByEdge {
            splits.sort { $0.distanceAlong < $1.distanceAlong }
            splitsByEdge[index] = splits
        }

        var result: [Edge] = []
        for (i, edge) in edges.enumerated() {
            if let splits = splitsByEdge[i] {
                var currentStart = edge.start
                for sp in splits {
                    if sp.distanceAlong <= 0 || sp.distanceAlong >= 1.0 {
                        continue
                    }
                    if currentStart != sp.coordinate {
                        result.append(Edge(start: currentStart, end: sp.coordinate, polygonIndex: edge.polygonIndex))
                    }
                    currentStart = sp.coordinate
                }
                if currentStart != edge.end {
                    result.append(Edge(start: currentStart, end: edge.end, polygonIndex: edge.polygonIndex))
                }
            }
            else {
                result.append(edge)
            }
        }
        return result
    }

    // MARK: - Duplicate removal

    /// Removes duplicate and reverse-coincident boundary edges in one pass.
    fileprivate static func mergeReversePairs(_ edges: [Edge]) -> [Edge] {
        // Two boundary edges are the same segment when their endpoints match,
        // regardless of direction. Keep the first occurrence in input order.
        struct EdgeKey: Hashable {

            let first: String
            let second: String

        }

        var seen = Set<EdgeKey>()
        var result: [Edge] = []
        result.reserveCapacity(edges.count)

        for edge in edges {
            let start = vertexKey(edge.start)
            let end = vertexKey(edge.end)
            let key = start < end
                ? EdgeKey(first: start, second: end)
                : EdgeKey(first: end, second: start)

            if seen.insert(key).inserted {
                result.append(edge)
            }
        }

        return result
    }

    // MARK: - Ring construction

    /// Normalizes a coordinate to a fixed-precision key for use as dictionary keys.
    fileprivate static func vertexKey(_ coord: Coordinate3D) -> String {
        let q = 0.01
        let x = round(coord.x / q) * q
        let y = round(coord.y / q) * q
        return "\(x),\(y)"
    }

    fileprivate static func buildRings(from edges: [Edge]) -> [[Coordinate3D]] {
        buildRings(from: edges) { vertexKey($0) }
    }

    fileprivate static func buildRings(
        from edges: [Edge],
        key: (Coordinate3D) -> String
    ) -> [[Coordinate3D]] {
        guard edges.isNotEmpty else { return [] }

        var adj: [String: [Int]] = [:]
        for (i, edge) in edges.enumerated() {
            let sk = key(edge.start)
            let ek = key(edge.end)
            adj[sk, default: []].append(i)
            adj[ek, default: []].append(i)
        }

        let snapEpsMeters = 0.01

        var used = Set<Int>()
        var rings: [[Coordinate3D]] = []

        for startIdx in edges.indices where !used.contains(startIdx) {
            var ring: [Coordinate3D] = [edges[startIdx].start, edges[startIdx].end]
            used.insert(startIdx)
            let startKey = key(edges[startIdx].start)
            var currentKey = key(edges[startIdx].end)

            func currentCoord() -> Coordinate3D {
                guard let last = ring.last else { return edges[startIdx].start }

                return last
            }

            while currentKey != startKey || ring.count < 4 {
                let candidates = adj[currentKey] ?? []
                var found = false
                for ci in candidates where !used.contains(ci) {
                    let e = edges[ci]
                    let sk = key(e.start)
                    let ek = key(e.end)
                    if ek == currentKey {
                        ring.append(e.start)
                        currentKey = sk
                    }
                    else {
                        ring.append(e.end)
                        currentKey = ek
                    }
                    used.insert(ci)
                    found = true
                    break
                }

                if !found {
                    let cur = currentCoord()
                    var best: (ci: Int, useEnd: Bool, dist: Double)?
                    for (i, e) in edges.enumerated() where !used.contains(i) {
                        let dStart = hypot(e.start.x - cur.x, e.start.y - cur.y)
                        let dEnd = hypot(e.end.x - cur.x, e.end.y - cur.y)
                        if dStart < snapEpsMeters,
                           dStart < (best?.dist ?? .greatestFiniteMagnitude)
                        {
                            best = (i, false, dStart)
                        }
                        if dEnd < snapEpsMeters,
                           dEnd < (best?.dist ?? .greatestFiniteMagnitude)
                        {
                            best = (i, true, dEnd)
                        }
                    }
                    if let best {
                        used.insert(best.ci)
                        let e = edges[best.ci]
                        if best.useEnd {
                            ring.append(e.start)
                            currentKey = key(e.start)
                        }
                        else {
                            ring.append(e.end)
                            currentKey = key(e.end)
                        }
                        found = true
                    }
                }

                if !found {
                    break
                }
            }

            if ring.count >= 4 {
                rings.append(ring)
            }
        }

        return rings
    }

    // MARK: - Polygon assembly

    fileprivate static func assemblePolygons(from rings: [[Coordinate3D]]) -> [Polygon] {
        guard rings.isNotEmpty else { return [] }

        let candidates: [(coords: [Coordinate3D], area: Double)] = rings.compactMap { coords in
            guard coords.count >= 4 else { return nil }

            let ring = Ring(unchecked: coords)
            return (coords, ring.area)
        }
        guard candidates.isNotEmpty else { return [] }

        let sorted = candidates.sorted { abs($0.area) > abs($1.area) }

        var result: [Polygon] = []
        for (coords, _) in sorted {
            let ring = Ring(unchecked: coords)
            let candidate = Polygon(unchecked: [ring])
            let testPoint = candidate.poleOfInaccessibility()?.coordinate
                ?? ring.coordinates.first!

            var assigned = false
            for (i, _) in result.enumerated() {
                if result[i].locate(testPoint, gridSize: nil) == .interior {
                    let poly = Polygon(unchecked: [result[i].outerRing!] + (result[i].innerRings ?? []) + [ring])
                    result[i] = poly
                    assigned = true
                    break
                }
            }
            if !assigned {
                let poly = Polygon(unchecked: [ring])
                result.append(poly)
            }
        }

        return result.map { $0.rewinded }
    }

}

// MARK: - Prepared point-in-polygon

/// A point-in-polygon index that buckets ring edges by latitude.
private struct OverlayPreparedPolygon: Sendable {

    private let outerRing: OverlayPreparedRing?
    private let innerRings: [OverlayPreparedRing]
    /// Polygons with a world-spanning edge are left unchanged by antimeridian
    /// normalization and need the robust wraparound-aware containment test.
    private let fallback: Polygon?

    init(polygon: Polygon) {
        if polygon.crossesAntimeridian {
            self.fallback = polygon
            self.outerRing = nil
            self.innerRings = []
            return
        }

        self.fallback = nil
        self.outerRing = polygon.outerRing.map { OverlayPreparedRing($0.coordinates) }
        self.innerRings = polygon.innerRings?.map { OverlayPreparedRing($0.coordinates) } ?? []
    }

    func contains(_ point: Coordinate3D) -> Bool {
        if let fallback {
            return fallback.contains(point)
        }

        guard let outerRing,
              outerRing.contains(point)
        else { return false }

        for ring in innerRings where ring.contains(point) {
            return false
        }

        return true
    }

}

private struct OverlayPreparedRing: Sendable {

    private let coordinates: [Coordinate3D]
    private let edgeCount: Int
    private let minY: Double
    private let maxY: Double
    private let rowScale: Double
    private let rowCount: Int
    private let rows: [[Int]]

    init(_ coordinates: [Coordinate3D]) {
        let isClosed = coordinates.count > 1 && coordinates.first == coordinates.last
        let edgeCount = isClosed ? coordinates.count - 1 : coordinates.count

        self.coordinates = coordinates
        self.edgeCount = max(edgeCount, 0)

        guard edgeCount >= 3, let firstCoordinate = coordinates.first else {
            self.minY = 0.0
            self.maxY = 0.0
            self.rowScale = 0.0
            self.rowCount = 0
            self.rows = []
            return
        }

        var minY = firstCoordinate.y
        var maxY = firstCoordinate.y
        for coordinate in coordinates.dropFirst() {
            minY = min(minY, coordinate.y)
            maxY = max(maxY, coordinate.y)
        }

        guard maxY > minY else {
            self.minY = 0.0
            self.maxY = 0.0
            self.rowScale = 0.0
            self.rowCount = 0
            self.rows = []
            return
        }

        let rowCount = max(8, min(256, edgeCount / 4))
        let span = maxY - minY
        let rowScale = Double(rowCount) / span
        var rows = Array(repeating: [Int](), count: rowCount)

        for index in 0 ..< edgeCount {
            let a = coordinates[index]
            let b = coordinates[(index + 1) % edgeCount]
            let low = min(a.y, b.y)
            let high = max(a.y, b.y)
            let startRow = min(max(Int((low - minY) * rowScale), 0), rowCount - 1)
            let endRow = min(max(Int((high - minY) * rowScale), 0), rowCount - 1)

            for row in startRow ... endRow {
                rows[row].append(index)
            }
        }

        self.minY = minY
        self.maxY = maxY
        self.rowScale = rowScale
        self.rowCount = rowCount
        self.rows = rows
    }

    func contains(_ point: Coordinate3D) -> Bool {
        guard edgeCount >= 3,
              rowCount > 0,
              point.y >= minY,
              point.y <= maxY
        else { return false }

        let row = min(max(Int((point.y - minY) * rowScale), 0), rowCount - 1)
        var inside = false

        for index in rows[row] {
            let a = coordinates[index]
            let b = coordinates[(index + 1) % edgeCount]

            if (a.y > point.y) != (b.y > point.y) {
                let x = (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x
                if point.x < x {
                    inside.toggle()
                }
            }
        }

        return inside
    }

}

// MARK: - Boundary assembly

extension Overlay {

    /// Build polygons from a set of directed boundary edges.
    ///
    /// Coordinates are matched exactly, which is suitable for meshes whose
    /// vertices originate from the same triangulation.
    static func polygons(
        fromBoundaryEdges edges: [(start: Coordinate3D, end: Coordinate3D)]
    ) -> [Polygon] {
        let overlayEdges = edges.map {
            Edge(start: $0.start, end: $0.end, polygonIndex: 0)
        }
        let rings = buildRings(from: overlayEdges) { coordinate in
            let x = coordinate.x == 0.0 ? 0.0 : coordinate.x
            let y = coordinate.y == 0.0 ? 0.0 : coordinate.y
            return "\(x),\(y)"
        }
        return assemblePolygons(from: rings)
    }

}
