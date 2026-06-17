import Foundation

// MARK: - Public API

extension GeoJson {

    /// Returns the minimum bounding circle that encloses all coordinates
    /// of the receiver as a ``Polygon`` approximation.
    ///
    /// For a single ``Point`` the result is `nil`. For an empty geometry the
    /// result is `nil`.
    ///
    /// - Parameter steps: The number of steps to approximate the circle (default `64`, minimum `3`).
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: A ``Polygon`` approximating the minimum bounding circle
    public func minimumBoundingCircle(
        steps: Int = 64,
        gridSize: Double? = nil
    ) -> Polygon? {
        guard let radius = minimumBoundingRadius(gridSize: gridSize),
              radius > 0.0,
              let center = minimumBoundingCircleCenter(gridSize: gridSize)
        else { return nil }

        return MinimumBoundingCircle.circlePolygon(center: center, radius: radius, steps: max(3, steps))
    }

    /// Returns the radius of the minimum bounding circle that encloses all
    /// coordinates of the receiver, in the native coordinate system units
    /// (degrees for EPSG:4326, meters for EPSG:3857/4978).
    ///
    /// For a single ``Point`` the radius is 0. For an empty geometry it is `nil`.
    ///
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: The radius in native units, or `nil` if the geometry is empty
    public func minimumBoundingRadius(gridSize: Double? = nil) -> Double? {
        let coords = allCoordinates
        guard let first = coords.first else { return nil }

        let projection = first.projection
        var pts = coords.map { $0.projected(to: projection) }
        if let gridSize {
            pts = pts.map { $0.snappedToGrid(tolerance: gridSize) }
        }

        guard let _ = pts.first else { return nil }
        if pts.count == 1 { return 0.0 }

        return MinimumBoundingCircle.compute(points: pts)?.radius
    }

}

// MARK: - Circle center (internal)

extension GeoJson {

    fileprivate func minimumBoundingCircleCenter(gridSize: Double? = nil) -> Coordinate3D? {
        let coords = allCoordinates
        guard let first = coords.first else { return nil }
        let projection = first.projection

        var pts = coords.map { $0.projected(to: projection) }
        if let gridSize {
            pts = pts.map { $0.snappedToGrid(tolerance: gridSize) }
        }

        guard let firstPt = pts.first else { return nil }
        if pts.count == 1 { return firstPt }

        return MinimumBoundingCircle.compute(points: pts)?.center
    }

}

// MARK: - Implementation (Welzl's algorithm)

private enum MinimumBoundingCircle {

    private struct Result {
        let center: Coordinate3D
        let radius: Double
    }

    static func compute(points: [Coordinate3D]) -> (center: Coordinate3D, radius: Double)? {
        guard let hull = hull(points: points) else { return nil }
        guard hull.count > 1 else {
            return hull.first.map { ($0, 0.0) }
        }

        let result = welzl(pts: hull.shuffled(), boundary: [])
        return result.map { ($0.center, $0.radius) }
    }

    static func circlePolygon(center: Coordinate3D, radius: Double, steps: Int) -> Polygon? {
        // Convert the native-unit radius to meters for the geodesic circle(...) method
        let boundaryPoint = Coordinate3D(
            x: center.longitude + radius,
            y: center.latitude,
            projection: center.projection)
        let radiusInMeters = center.distance(from: boundaryPoint)
        return center.circle(radius: radiusInMeters, steps: steps)
    }

    // MARK: - Welzl

    private static func welzl(pts: [Coordinate3D], boundary: [Coordinate3D]) -> Result? {
        if pts.isEmpty || boundary.count == 3 {
            return trivialCircle(boundary)
        }

        var remaining = pts
        let p = remaining.removeLast()

        let result = welzl(pts: remaining, boundary: boundary)
        if let r = result, isInside(p, center: r.center, radius: r.radius) {
            return r
        }

        return welzl(pts: remaining, boundary: boundary + [p])
    }

    private static func trivialCircle(_ boundary: [Coordinate3D]) -> Result? {
        switch boundary.count {
        case 0: return nil
        case 1: return Result(center: boundary[0], radius: 0.0)
        case 2:
            let a = boundary[0], b = boundary[1]
            let cx = (a.longitude + b.longitude) / 2.0
            let cy = (a.latitude + b.latitude) / 2.0
            let center = Coordinate3D(x: cx, y: cy, projection: a.projection)
            return Result(center: center, radius: distance(a, b) / 2.0)
        case 3: return circumcircle(boundary[0], boundary[1], boundary[2])
        default: return nil
        }
    }

    private static func circumcircle(
        _ a: Coordinate3D,
        _ b: Coordinate3D,
        _ c: Coordinate3D
    ) -> Result? {
        let ax = a.longitude, ay = a.latitude
        let bx = b.longitude, by = b.latitude
        let cx = c.longitude, cy = c.latitude

        let d = 2.0 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by))
        guard abs(d) > 1e-15 else { return nil }

        let ux = ((ax * ax + ay * ay) * (by - cy) + (bx * bx + by * by) * (cy - ay) + (cx * cx + cy * cy) * (ay - by)) / d
        let uy = ((ax * ax + ay * ay) * (cx - bx) + (bx * bx + by * by) * (ax - cx) + (cx * cx + cy * cy) * (bx - ax)) / d

        let center = Coordinate3D(x: ux, y: uy, projection: a.projection)
        return Result(center: center, radius: distance(center, a))
    }

    // MARK: - Helpers

    private static func distance(_ a: Coordinate3D, _ b: Coordinate3D) -> Double {
        let dx = a.longitude - b.longitude
        let dy = a.latitude - b.latitude
        return sqrt(dx * dx + dy * dy)
    }

    private static func isInside(_ p: Coordinate3D, center: Coordinate3D, radius: Double) -> Bool {
        distance(p, center) <= radius + 1e-12
    }

    // MARK: - Convex hull (Andrew's monotone chain)

    private static func hull(points: [Coordinate3D]) -> [Coordinate3D]? {
        guard points.count >= 3 else { return points }

        let sorted = points.sorted { a, b in
            a.longitude == b.longitude ? a.latitude < b.latitude : a.longitude < b.longitude
        }

        var lower: [Coordinate3D] = []
        for p in sorted {
            while lower.count >= 2 {
                let a = lower[lower.count - 2]
                let b = lower[lower.count - 1]
                if cross(a, b, p) <= 0 { lower.removeLast() } else { break }
            }
            lower.append(p)
        }

        var upper: [Coordinate3D] = []
        for p in sorted.reversed() {
            while upper.count >= 2 {
                let a = upper[upper.count - 2]
                let b = upper[upper.count - 1]
                if cross(a, b, p) <= 0 { upper.removeLast() } else { break }
            }
            upper.append(p)
        }

        _ = lower.removeLast()
        _ = upper.removeLast()

        return lower + upper
    }

    private static func cross(
        _ o: Coordinate3D,
        _ a: Coordinate3D,
        _ b: Coordinate3D
    ) -> Double {
        (a.longitude - o.longitude) * (b.latitude - o.latitude)
            - (a.latitude - o.latitude) * (b.longitude - o.longitude)
    }

}
