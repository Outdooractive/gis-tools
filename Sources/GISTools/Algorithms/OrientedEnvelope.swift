import Foundation

// MARK: - Public API

extension GeoJson {

    /// Returns the minimum-area oriented bounding rectangle (oriented envelope)
    /// that encloses all coordinates of the receiver.
    ///
    /// Unlike the axis-aligned ``BoundingBox``, the oriented envelope is rotated
    /// to minimise its area, giving a tighter fit around the geometry.
    ///
    /// For degenerate inputs (a single point or collinear points) the result
    /// is a rectangle that encloses the `LineString` formed by the points,
    /// or `nil` if the geometry is empty.
    ///
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: A ``Polygon`` representing the minimum-area rotated rectangle
    public func orientedEnvelope(gridSize: Double? = nil) -> Polygon? {
        let coords = allCoordinates
        guard let first = coords.first else { return nil }

        let projection = first.projection
        var pts = coords.map { $0.projected(to: projection) }
        if let gridSize {
            pts = pts.map { $0.snappedToGrid(tolerance: gridSize) }
        }

        guard pts.count > 1 else { return nil }

        return OrientedEnvelope.compute(points: pts)
    }

}

// MARK: - Implementation (rotating calipers)

private enum OrientedEnvelope {

    static func compute(points: [Coordinate3D]) -> Polygon? {
        let hull: [Coordinate3D]

        if points.count >= 3 {
            // Use the existing convexHull() implementation on a MultiPoint
            let multiPoint = MultiPoint(unchecked: points as [Coordinate3D])
            guard let hullPolygon = multiPoint.convexHull(),
                  let ring = hullPolygon.outerRing
            else { return nil }

            var coords = ring.coordinates
            if coords.count > 1, coords.first == coords.last {
                coords = Array(coords.dropLast())
            }
            hull = coords
        }
        else if points.count == 2 {
            hull = points
        }
        else {
            return nil
        }

        if hull.count == 2 {
            return rectForSegment(hull[0], hull[1], all: hull)
        }

        guard hull.count >= 3 else { return nil }

        var bestArea = Double.infinity
        var bestRect: (cx: Double, cy: Double, w: Double, h: Double, angle: Double)?

        for i in 0..<hull.count {
            let j = (i + 1) % hull.count
            let edgeAngle = atan2(
                hull[j].latitude - hull[i].latitude,
                hull[j].longitude - hull[i].longitude)

            let cosA = cos(-edgeAngle)
            let sinA = sin(-edgeAngle)

            var minX = Double.infinity
            var maxX = -Double.infinity
            var minY = Double.infinity
            var maxY = -Double.infinity

            for p in hull {
                let rx = p.longitude * cosA - p.latitude * sinA
                let ry = p.longitude * sinA + p.latitude * cosA
                minX = min(minX, rx)
                maxX = max(maxX, rx)
                minY = min(minY, ry)
                maxY = max(maxY, ry)
            }

            let w = maxX - minX
            let h = maxY - minY
            let area = w * h

            if area < bestArea {
                bestArea = area
                bestRect = (
                    cx: (minX + maxX) / 2.0,
                    cy: (minY + maxY) / 2.0,
                    w: w, h: h,
                    angle: edgeAngle)
            }
        }

        guard let rect = bestRect else { return nil }
        return buildRect(rect, projection: points.first?.projection ?? .epsg4326)
    }

    // MARK: - Rectangle construction

    private static func buildRect(
        _ r: (cx: Double, cy: Double, w: Double, h: Double, angle: Double),
        projection: Projection
    ) -> Polygon? {
        let cosA = cos(r.angle)
        let sinA = sin(r.angle)
        let hw = r.w / 2.0
        let hh = r.h / 2.0

        let local: [(Double, Double)] = [
            (hw, hh), (-hw, hh), (-hw, -hh), (hw, -hh), (hw, hh)
        ]

        let coords: [Coordinate3D] = local.map { lx, ly in
            let worldX = r.cx + lx * cosA - ly * sinA
            let worldY = r.cy + lx * sinA + ly * cosA
            return Coordinate3D(x: worldX, y: worldY, projection: projection)
        }

        return Polygon(unchecked: [coords])
    }

    // MARK: - 2-point case

    private static func rectForSegment(
        _ a: Coordinate3D,
        _ b: Coordinate3D,
        all: [Coordinate3D]
    ) -> Polygon? {
        let angle = atan2(b.latitude - a.latitude, b.longitude - a.longitude)
        let cosA = cos(-angle)
        let sinA = sin(-angle)

        var minX = Double.infinity
        var maxX = -Double.infinity
        var minY = Double.infinity
        var maxY = -Double.infinity

        for p in all {
            let rx = p.longitude * cosA - p.latitude * sinA
            let ry = p.longitude * sinA + p.latitude * cosA
            minX = min(minX, rx)
            maxX = max(maxX, rx)
            minY = min(minY, ry)
            maxY = max(maxY, ry)
        }

        return buildRect(
            (cx: (minX + maxX) / 2.0,
             cy: (minY + maxY) / 2.0,
             w: maxX - minX,
             h: maxY - minY,
             angle: angle),
            projection: a.projection)
    }

}
