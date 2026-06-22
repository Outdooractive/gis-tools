import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-voronoi

extension FeatureCollection {

    /// Computes a Voronoi diagram from the receiver's points within a bounding box.
    ///
    /// Each input ``Point`` feature produces one ``Polygon`` cell representing the
    /// region closer to that point than to any other input point. The cells are
    /// clipped to the given bounding box.
    ///
    /// - Parameter boundingBox: The bounding box to which all cells are clipped.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: A ``FeatureCollection`` of ``Polygon`` features, one per input point.
    public func voronoiDiagram(
        boundingBox: BoundingBox,
        gridSize: Double? = nil
    ) -> FeatureCollection {
        guard features.count >= 3 else { return FeatureCollection() }

        let snapped = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self

        let points: [Coordinate3D] = snapped.features.compactMap { f in
            (f.geometry as? Point)?.coordinate
        }
        guard points.count >= 3 else { return FeatureCollection() }

        return Voronoi.diagram(points: points, boundingBox: boundingBox)
    }

}

// MARK: - Implementation

private enum Voronoi {

    static func diagram(
        points: [Coordinate3D],
        boundingBox: BoundingBox
    ) -> FeatureCollection {
        let pts = points.map { Pt(x: $0.longitude, y: $0.latitude) }
        let triangles = Triangulator.triangulate(pts)
        guard triangles.isNotEmpty else { return FeatureCollection() }

        // Build edge counts to identify adjacency and boundary edges
        var edgeCount: [String: Int] = [:]
        var edgeEndpoints: [String: (a: Pt, b: Pt)] = [:]

        for t in triangles {
            let edges = [(t.a, t.b), (t.b, t.c), (t.c, t.a)]
            for (a, b) in edges {
                let key = Voronoi.edgeKey(a, b)
                edgeCount[key, default: 0] += 1
                edgeEndpoints[key] = (a, b)
            }
        }

        // Build neighbor list for each point
        var neighbors: [Int: Set<Int>] = [:]
        for (key, _) in edgeCount {
            guard let edge = edgeEndpoints[key],
                  let ia = pts.firstIndex(where: { $0.x == edge.a.x && $0.y == edge.a.y }),
                  let ib = pts.firstIndex(where: { $0.x == edge.b.x && $0.y == edge.b.y })
            else { continue }
            neighbors[ia, default: []].insert(ib)
            neighbors[ib, default: []].insert(ia)
        }

        // Build bounding box polygon (CCW)
        let bboxPolygon = Voronoi.bboxPolygon(boundingBox)

        // Compute Voronoi cell for each point
        var features: [Feature] = []
        for (i, point) in points.enumerated() {
            guard let neighborIndices = neighbors[i],
                  neighborIndices.count >= 2
            else { continue }

            let cell = Voronoi.computeCell(
                point: point,
                neighborIndices: Array(neighborIndices),
                allPoints: points,
                bboxPolygon: bboxPolygon)

            if let cell {
                let feature = Feature(cell)
                features.append(feature)
            }
        }

        return FeatureCollection(features)
    }

    // MARK: - Cell computation

    /// Compute the Voronoi cell for a single point by clipping the bounding box
    /// against the perpendicular bisectors of its Delaunay neighbors.
    private static func computeCell(
        point: Coordinate3D,
        neighborIndices: [Int],
        allPoints: [Coordinate3D],
        bboxPolygon: [Coordinate3D]
    ) -> Polygon? {
        // Start with the bounding box as the clipping polygon
        var cell = bboxPolygon

        let px = point.longitude
        let py = point.latitude
        let pSq = px * px + py * py

        for ni in neighborIndices {
            let q = allPoints[ni]
            let qx = q.longitude
            let qy = q.latitude
            let qSq = qx * qx + qy * qy

            // Bisector coefficients: line where distance(p) == distance(q)
            // 2*(qx-px)*x + 2*(qy-py)*y = qSq - pSq
            let a = 2.0 * (qx - px)
            let b = 2.0 * (qy - py)
            let c = qSq - pSq

            // Clip cell to the half-plane containing point p
            cell = Voronoi.clipPolygonByHalfPlane(polygon: cell, a: a, b: b, c: c)
            guard cell.count >= 3 else { return nil }
        }

        guard cell.count >= 3 else { return nil }
        // Close the polygon
        var coords = cell
        coords.append(cell[0])
        return Polygon([coords])
    }

    // MARK: - Half-plane clipping (Sutherland-Hodgman)

    /// Clip a polygon (CCW) by the half-plane a*x + b*y <= c.
    /// The polygon is represented as an array of coordinates (not closed).
    private static func clipPolygonByHalfPlane(
        polygon: [Coordinate3D],
        a: Double,
        b: Double,
        c: Double
    ) -> [Coordinate3D] {
        guard polygon.count >= 3 else { return polygon }

        var result: [Coordinate3D] = []

        let count = polygon.count
        for i in 0 ..< count {
            let current = polygon[i]
            let previous = polygon[(i + count - 1) % count]

            let dCurrent = a * current.longitude + b * current.latitude - c
            let dPrevious = a * previous.longitude + b * previous.latitude - c

            let currentInside = dCurrent <= 0
            let previousInside = dPrevious <= 0

            if currentInside {
                if !previousInside {
                    // Entering: add intersection
                    if let intersection = Voronoi.lineIntersection(
                        p1: previous, p2: current, a: a, b: b, c: c) {
                        result.append(intersection)
                    }
                }
                result.append(current)
            }
            else if previousInside {
                // Exiting: add intersection
                if let intersection = Voronoi.lineIntersection(
                    p1: previous, p2: current, a: a, b: b, c: c) {
                    result.append(intersection)
                }
            }
        }

        return result
    }

    /// Find intersection of segment (p1-p2) with line a*x + b*y = c.
    private static func lineIntersection(
        p1: Coordinate3D,
        p2: Coordinate3D,
        a: Double,
        b: Double,
        c: Double
    ) -> Coordinate3D? {
        let x1 = p1.longitude, y1 = p1.latitude
        let x2 = p2.longitude, y2 = p2.latitude

        let denom = a * (x2 - x1) + b * (y2 - y1)
        guard abs(denom) > GISTool.determinantEpsilon else { return nil }

        let t = (c - a * x1 - b * y1) / denom
        guard t >= 0, t <= 1 else { return nil }

        return Coordinate3D(
            latitude: y1 + t * (y2 - y1),
            longitude: x1 + t * (x2 - x1))
    }

    // MARK: - Helpers

    /// Build a CCW polygon from the bounding box.
    private static func bboxPolygon(_ bbox: BoundingBox) -> [Coordinate3D] {
        let sw = bbox.southWest
        let nw = bbox.northWest
        let ne = bbox.northEast
        let se = bbox.southEast
        return [sw, nw, ne, se]
    }

    /// Canonical string key for an undirected edge.
    private static func edgeKey(_ a: Pt, _ b: Pt) -> String {
        let ax = "\(a.x),\(a.y)"
        let bx = "\(b.x),\(b.y)"
        return ax < bx ? "\(ax)-\(bx)" : "\(bx)-\(ax)"
    }

}
