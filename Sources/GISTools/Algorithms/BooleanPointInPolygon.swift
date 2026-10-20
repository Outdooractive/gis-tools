#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-boolean-point-in-polygon

extension Ring {

    /// Determines where *Coordinate3D* lies relative to the *Ring*.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `.interior`, `.boundary` or `.exterior`.
    public func locate(_ coordinate: Coordinate3D, gridSize: Double? = nil) -> PointLocation {
        let snappedSelf = gridSize.map { snappedToGrid(tolerance: $0) } ?? self
        let snappedCoordinate = gridSize.map { coordinate.snappedToGrid(tolerance: $0) } ?? coordinate

        if projection.isGeocentric {
            return snappedSelf.projected(to: .epsg4326).locate(
                snappedCoordinate.projected(to: .epsg4326))
        }

        let coordinate = snappedCoordinate.projected(to: projection)
        let snappedCoordinates = snappedSelf.coordinates

        var isInside = false

        var coordinatesCount = snappedCoordinates.count
        if snappedCoordinates.first == snappedCoordinates.last {
            coordinatesCount -= 1
        }

        // Detect antimeridian crossing for projections with a wraparound
        // horizontal axis (EPSG:4326 at ±180°, EPSG:3857 at ±originShift).
        // An edge jump larger than the half-width but smaller than twice the
        // half-width indicates that the ring wraps around the seam. For
        // projections without a wraparound axis the X values are just long
        // edges and no adjustment is applied.
        var crossesAntimeridian = false
        if let wraparoundExtent = projection.wraparoundExtent {
            for i in 0 ..< coordinatesCount {
                let j = (i + coordinatesCount - 1) % coordinatesCount
                let dLon = snappedCoordinates[i].longitude - snappedCoordinates[j].longitude
                if abs(dLon) > wraparoundExtent, abs(dLon) < (2.0 * wraparoundExtent) {
                    crossesAntimeridian = true
                    break
                }
            }
        }

        let wraparoundWidth = 2.0 * (projection.wraparoundExtent ?? 0.0)
        var testLon = coordinate.longitude
        if crossesAntimeridian {
            testLon = testLon < 0.0 ? testLon + wraparoundWidth : testLon
        }

        let py = coordinate.latitude

        var j = coordinatesCount - 1
        for i in 0 ..< coordinatesCount {
            defer {
                j = i
            }

            var x1 = snappedCoordinates[j].longitude
            let y1 = snappedCoordinates[j].latitude
            var x2 = snappedCoordinates[i].longitude
            let y2 = snappedCoordinates[i].latitude

            if crossesAntimeridian {
                x1 = x1 < 0.0 ? x1 + wraparoundWidth : x1
                x2 = x2 < 0.0 ? x2 + wraparoundWidth : x2
            }

            // GEOS/JTS RayCrossingCounter. Segment endpoints are visited in
            // ring order so every vertex is tested exactly once as `p2`.
            if x1 < testLon, x2 < testLon {
                continue
            }

            if x2 == testLon, y2 == py {
                return .boundary
            }

            if y1 == py, y2 == py {
                let minX = min(x1, x2)
                let maxX = max(x1, x2)
                if testLon >= minX, testLon <= maxX {
                    return .boundary
                }
                continue
            }

            let crossesRay = (y1 > py && y2 <= py) || (y2 > py && y1 <= py)
            guard crossesRay else { continue }

            var orientation = PointInRing.orientationIndex(
                x1, y1,
                x2, y2,
                testLon, py)
            if orientation == 0 {
                return .boundary
            }
            if y2 < y1 {
                orientation = -orientation
            }
            if orientation > 0 {
                isInside.toggle()
            }
        }

        return isInside ? .interior : .exterior
    }

    /// Determines if *Coordinate3D* resides in the interior of the *Ring*.
    ///
    /// This is the OGC/PostGIS `ST_Contains` semantics for a point: points on the
    /// ring's boundary are **not** contained. Use ``covers(_:gridSize:)`` to
    /// include boundary points.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `true` if the coordinate is in the interior of the ring, `false` otherwise.
    public func contains(_ coordinate: Coordinate3D, gridSize: Double? = nil) -> Bool {
        locate(coordinate, gridSize: gridSize) == .interior
    }

    /// Determines if *Coordinate3D* is covered by the *Ring*.
    ///
    /// This is the OGC/PostGIS `ST_Covers` semantics for a point: points on the
    /// ring's boundary are covered. Use ``contains(_:gridSize:)`` for
    /// interior-only containment.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `true` if the coordinate is inside or on the boundary of the ring, `false` otherwise.
    public func covers(_ coordinate: Coordinate3D, gridSize: Double? = nil) -> Bool {
        locate(coordinate, gridSize: gridSize) != .exterior
    }

    /// Determines where *Point* lies relative to the *Ring*.
    ///
    /// - Parameter point: The point to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `.interior`, `.boundary` or `.exterior`.
    public func locate(_ point: Point, gridSize: Double? = nil) -> PointLocation {
        locate(point.coordinate, gridSize: gridSize)
    }

    /// Determines if *Point* resides in the interior of the *Ring*.
    ///
    /// - Parameter point: The point to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `true` if the point is in the interior of the ring, `false` otherwise.
    public func contains(_ point: Point, gridSize: Double? = nil) -> Bool {
        contains(point.coordinate, gridSize: gridSize)
    }

    /// Determines if *Point* is covered by the *Ring*.
    ///
    /// - Parameter point: The point to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `true` if the point is inside or on the boundary of the ring, `false` otherwise.
    public func covers(_ point: Point, gridSize: Double? = nil) -> Bool {
        covers(point.coordinate, gridSize: gridSize)
    }

}

extension Polygon {

    /// Determines where *Coordinate3D* lies relative to the *Polygon*.
    ///
    /// The polygon can be convex or concave. Holes are accounted for: a coordinate
    /// on a hole's boundary is `.boundary`, matching JTS/GEOS
    /// `SimplePointInAreaLocator`.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `.interior`, `.boundary` or `.exterior`.
    public func locate(_ coordinate: Coordinate3D, gridSize: Double? = nil) -> PointLocation {
        if projection.isGeocentric {
            let snappedSelf = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
            let snappedCoordinate = gridSize.map { coordinate.snappedToGrid(tolerance: $0) } ?? coordinate
            return snappedSelf.projected(to: .epsg4326).locate(
                snappedCoordinate.projected(to: .epsg4326))
        }

        let snappedSelf = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let snappedCoordinate = gridSize.map { coordinate.snappedToGrid(tolerance: $0) } ?? coordinate

        if let boundingBox = snappedSelf.boundingBox,
           !boundingBox.contains(snappedCoordinate)
        {
            // Bounding box doesn't contain the point. If the polygon crosses the
            // antimeridian, the point may still be inside the wrapped side.
            if let outerRing = snappedSelf.outerRing,
               let wraparoundExtent = projection.wraparoundExtent
            {
                let coords = outerRing.coordinates
                var crossesAM = false
                for i in 1 ..< coords.count {
                    let dLon = coords[i].longitude - coords[i - 1].longitude
                    if abs(dLon) > wraparoundExtent, abs(dLon) < (2.0 * wraparoundExtent) {
                        crossesAM = true
                        break
                    }
                }
                if !crossesAM {
                    return .exterior
                }
            } else {
                return .exterior
            }
        }

        guard let outerRing = snappedSelf.outerRing else { return .exterior }

        switch outerRing.locate(snappedCoordinate) {
        case .exterior:
            return .exterior

        case .boundary:
            return .boundary

        case .interior:
            break
        }

        if let innerRings = snappedSelf.innerRings {
            for ring in innerRings {
                // A point on a hole's boundary lies on the polygon boundary, so it
                // must be reported as `.boundary`, never as interior of the hole.
                switch ring.locate(snappedCoordinate) {
                case .boundary:
                    return .boundary

                case .interior:
                    return .exterior

                case .exterior:
                    continue
                }
            }
        }

        return .interior
    }

    /// Determines if *Coordinate3D* resides in the interior of the *Polygon*.
    ///
    /// This is the OGC/PostGIS `ST_Contains` semantics for a point: points on the
    /// outer or hole boundary are **not** contained. Use ``covers(_:gridSize:)``
    /// to include boundary points.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `true` if the coordinate is in the interior of the polygon, `false` otherwise.
    public func contains(_ coordinate: Coordinate3D, gridSize: Double? = nil) -> Bool {
        locate(coordinate, gridSize: gridSize) == .interior
    }

    /// Determines if *Coordinate3D* is covered by the *Polygon*.
    ///
    /// This is the OGC/PostGIS `ST_Covers` semantics for a point: points on the
    /// outer or hole boundary are covered. Use ``contains(_:gridSize:)`` for
    /// interior-only containment.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `true` if the coordinate is inside or on the boundary of the polygon, `false` otherwise.
    public func covers(_ coordinate: Coordinate3D, gridSize: Double? = nil) -> Bool {
        locate(coordinate, gridSize: gridSize) != .exterior
    }

    /// Determines where *Point* lies relative to the *Polygon*.
    ///
    /// - Parameter point: The point to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `.interior`, `.boundary` or `.exterior`.
    public func locate(_ point: Point, gridSize: Double? = nil) -> PointLocation {
        locate(point.coordinate, gridSize: gridSize)
    }

    /// Determines if *Point* resides in the interior of the *Polygon*.
    ///
    /// - Parameter point: The point to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `true` if the point is in the interior of the polygon, `false` otherwise.
    public func contains(_ point: Point, gridSize: Double? = nil) -> Bool {
        contains(point.coordinate, gridSize: gridSize)
    }

    /// Determines if *Point* is covered by the *Polygon*.
    ///
    /// - Parameter point: The point to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `true` if the point is inside or on the boundary of the polygon, `false` otherwise.
    public func covers(_ point: Point, gridSize: Double? = nil) -> Bool {
        covers(point.coordinate, gridSize: gridSize)
    }

}

extension MultiPolygon {

    /// Determines where *Coordinate3D* lies relative to the *MultiPolygon*.
    ///
    /// The polygons can be convex or concave, and holes are accounted for.
    /// A coordinate that is interior to one of the polygons is `.interior` even
    /// if it lies on the boundary of another (which should not happen for valid
    /// MultiPolygons).
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `.interior`, `.boundary` or `.exterior`.
    public func locate(_ coordinate: Coordinate3D, gridSize: Double? = nil) -> PointLocation {
        let snappedSelf = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let snappedCoordinate = gridSize.map { coordinate.snappedToGrid(tolerance: $0) } ?? coordinate

        if let boundingBox = snappedSelf.boundingBox, !boundingBox.contains(snappedCoordinate) {
            return .exterior
        }

        var isOnBoundary = false
        for polygon in snappedSelf.polygons {
            switch polygon.locate(snappedCoordinate) {
            case .interior:
                return .interior

            case .boundary:
                isOnBoundary = true

            case .exterior:
                continue
            }
        }

        return isOnBoundary ? .boundary : .exterior
    }

    /// Determines if *Coordinate3D* resides in the interior of the *MultiPolygon*.
    ///
    /// This is the OGC/PostGIS `ST_Contains` semantics for a point: points on any
    /// polygon boundary are **not** contained. Use ``covers(_:gridSize:)`` to
    /// include boundary points.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `true` if the coordinate is in the interior of one of the polygons, `false` otherwise.
    public func contains(_ coordinate: Coordinate3D, gridSize: Double? = nil) -> Bool {
        locate(coordinate, gridSize: gridSize) == .interior
    }

    /// Determines if *Coordinate3D* is covered by the *MultiPolygon*.
    ///
    /// This is the OGC/PostGIS `ST_Covers` semantics for a point: points on any
    /// polygon boundary are covered. Use ``contains(_:gridSize:)`` for
    /// interior-only containment.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `true` if the coordinate is inside or on the boundary of one of the polygons, `false` otherwise.
    public func covers(_ coordinate: Coordinate3D, gridSize: Double? = nil) -> Bool {
        locate(coordinate, gridSize: gridSize) != .exterior
    }

    /// Determines where *Point* lies relative to the *MultiPolygon*.
    ///
    /// - Parameter point: The point to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `.interior`, `.boundary` or `.exterior`.
    public func locate(_ point: Point, gridSize: Double? = nil) -> PointLocation {
        locate(point.coordinate, gridSize: gridSize)
    }

    /// Determines if *Point* resides in the interior of the *MultiPolygon*.
    ///
    /// - Parameter point: The point to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `true` if the point is in the interior of one of the polygons, `false` otherwise.
    public func contains(_ point: Point, gridSize: Double? = nil) -> Bool {
        contains(point.coordinate, gridSize: gridSize)
    }

    /// Determines if *Point* is covered by the *MultiPolygon*.
    ///
    /// - Parameter point: The point to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `true` if the point is inside or on the boundary of one of the polygons, `false` otherwise.
    public func covers(_ point: Point, gridSize: Double? = nil) -> Bool {
        covers(point.coordinate, gridSize: gridSize)
    }

}

extension GeometryCollection {

    /// Determines where *Coordinate3D* lies relative to the *GeometryCollection*.
    ///
    /// Only polygonal members (``PolygonGeometry`` and nested
    /// ``GeometryCollection``s) contribute to the result, matching
    /// ``contains(_:gridSize:)``. The interior of any member takes precedence
    /// over boundaries of other members.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `.interior`, `.boundary` or `.exterior`.
    public func locate(_ coordinate: Coordinate3D, gridSize: Double? = nil) -> PointLocation {
        let snappedSelf = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let snappedCoordinate = gridSize.map { coordinate.snappedToGrid(tolerance: $0) } ?? coordinate

        var isOnBoundary = false
        for geometry in snappedSelf.geometries {
            let location: PointLocation
            switch geometry {
            case let polygonGeometry as PolygonGeometry:
                location = polygonGeometry.locate(snappedCoordinate, gridSize: nil)

            case let geometryCollection as GeometryCollection:
                location = geometryCollection.locate(snappedCoordinate)

            default:
                continue
            }

            switch location {
            case .interior:
                return .interior

            case .boundary:
                isOnBoundary = true

            case .exterior:
                continue
            }
        }

        return isOnBoundary ? .boundary : .exterior
    }

    /// Determines if *Coordinate3D* resides in the interior of the *GeometryCollection*.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `true` if the coordinate is in the interior of one of the polygonal members, `false` otherwise.
    public func contains(_ coordinate: Coordinate3D, gridSize: Double? = nil) -> Bool {
        locate(coordinate, gridSize: gridSize) == .interior
    }

    /// Determines if *Coordinate3D* is covered by the *GeometryCollection*.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `true` if the coordinate is inside or on the boundary of one of the polygonal members, `false` otherwise.
    public func covers(_ coordinate: Coordinate3D, gridSize: Double? = nil) -> Bool {
        locate(coordinate, gridSize: gridSize) != .exterior
    }

    /// Determines where *Point* lies relative to the *GeometryCollection*.
    ///
    /// - Parameter point: The point to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `.interior`, `.boundary` or `.exterior`.
    public func locate(_ point: Point, gridSize: Double? = nil) -> PointLocation {
        locate(point.coordinate, gridSize: gridSize)
    }

    /// Determines if *Point* resides in the interior of the *GeometryCollection*.
    ///
    /// - Parameter point: The point to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `true` if the point is in the interior of one of the polygonal members, `false` otherwise.
    public func contains(_ point: Point, gridSize: Double? = nil) -> Bool {
        contains(point.coordinate, gridSize: gridSize)
    }

    /// Determines if *Point* is covered by the *GeometryCollection*.
    ///
    /// - Parameter point: The point to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `true` if the point is inside or on the boundary of one of the polygonal members, `false` otherwise.
    public func covers(_ point: Point, gridSize: Double? = nil) -> Bool {
        covers(point.coordinate, gridSize: gridSize)
    }

}

extension Feature {

    /// Determines where *Coordinate3D* lies relative to the *Feature*.
    ///
    /// Only polygonal geometries (``PolygonGeometry`` and ``GeometryCollection``)
    /// contribute, matching ``contains(_:gridSize:)``.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `.interior`, `.boundary` or `.exterior`.
    public func locate(_ coordinate: Coordinate3D, gridSize: Double? = nil) -> PointLocation {
        let snappedSelf = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let snappedCoordinate = gridSize.map { coordinate.snappedToGrid(tolerance: $0) } ?? coordinate

        switch snappedSelf.geometry {
        case let polygonGeometry as PolygonGeometry:
            return polygonGeometry.locate(snappedCoordinate, gridSize: nil)

        case let geometryCollection as GeometryCollection:
            return geometryCollection.locate(snappedCoordinate)

        default:
            return .exterior
        }
    }

    /// Determines if *Coordinate3D* resides in the interior of the *Feature*.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `true` if the coordinate is in the interior of the feature's geometry, `false` otherwise.
    public func contains(_ coordinate: Coordinate3D, gridSize: Double? = nil) -> Bool {
        locate(coordinate, gridSize: gridSize) == .interior
    }

    /// Determines if *Coordinate3D* is covered by the *Feature*.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `true` if the coordinate is inside or on the boundary of the feature's geometry, `false` otherwise.
    public func covers(_ coordinate: Coordinate3D, gridSize: Double? = nil) -> Bool {
        locate(coordinate, gridSize: gridSize) != .exterior
    }

    /// Determines where *Point* lies relative to the *Feature*.
    ///
    /// - Parameter point: The point to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `.interior`, `.boundary` or `.exterior`.
    public func locate(_ point: Point, gridSize: Double? = nil) -> PointLocation {
        locate(point.coordinate, gridSize: gridSize)
    }

    /// Determines if *Point* resides in the interior of the *Feature*.
    ///
    /// - Parameter point: The point to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `true` if the point is in the interior of the feature's geometry, `false` otherwise.
    public func contains(_ point: Point, gridSize: Double? = nil) -> Bool {
        contains(point.coordinate, gridSize: gridSize)
    }

    /// Determines if *Point* is covered by the *Feature*.
    ///
    /// - Parameter point: The point to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `true` if the point is inside or on the boundary of the feature's geometry, `false` otherwise.
    public func covers(_ point: Point, gridSize: Double? = nil) -> Bool {
        covers(point.coordinate, gridSize: gridSize)
    }

}

extension FeatureCollection {

    /// Determines where *Coordinate3D* lies relative to the *FeatureCollection*.
    ///
    /// Each feature contributes through ``Feature/locate(_:gridSize:)``. A
    /// coordinate interior to any feature is `.interior`; otherwise a boundary
    /// of any feature makes it `.boundary`.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `.interior`, `.boundary` or `.exterior`.
    public func locate(_ coordinate: Coordinate3D, gridSize: Double? = nil) -> PointLocation {
        let snappedSelf = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let snappedCoordinate = gridSize.map { coordinate.snappedToGrid(tolerance: $0) } ?? coordinate

        var isOnBoundary = false
        for feature in snappedSelf.features {
            switch feature.locate(snappedCoordinate) {
            case .interior:
                return .interior

            case .boundary:
                isOnBoundary = true

            case .exterior:
                continue
            }
        }

        return isOnBoundary ? .boundary : .exterior
    }

    /// Determines if *Coordinate3D* resides in the interior of the *FeatureCollection*.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `true` if the coordinate is in the interior of one of the features, `false` otherwise.
    public func contains(_ coordinate: Coordinate3D, gridSize: Double? = nil) -> Bool {
        locate(coordinate, gridSize: gridSize) == .interior
    }

    /// Determines if *Coordinate3D* is covered by the *FeatureCollection*.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `true` if the coordinate is inside or on the boundary of one of the features, `false` otherwise.
    public func covers(_ coordinate: Coordinate3D, gridSize: Double? = nil) -> Bool {
        locate(coordinate, gridSize: gridSize) != .exterior
    }

    /// Determines where *Point* lies relative to the *FeatureCollection*.
    ///
    /// - Parameter point: The point to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `.interior`, `.boundary` or `.exterior`.
    public func locate(_ point: Point, gridSize: Double? = nil) -> PointLocation {
        locate(point.coordinate, gridSize: gridSize)
    }

    /// Determines if *Point* resides in the interior of the *FeatureCollection*.
    ///
    /// - Parameter point: The point to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `true` if the point is in the interior of one of the features, `false` otherwise.
    public func contains(_ point: Point, gridSize: Double? = nil) -> Bool {
        contains(point.coordinate, gridSize: gridSize)
    }

    /// Determines if *Point* is covered by the *FeatureCollection*.
    ///
    /// - Parameter point: The point to check
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `true` if the point is inside or on the boundary of one of the features, `false` otherwise.
    public func covers(_ point: Point, gridSize: Double? = nil) -> Bool {
        covers(point.coordinate, gridSize: gridSize)
    }

}

// MARK: - Robust orientation

/// Robust orientation and point-in-ring predicates, following JTS/GEOS.
private enum PointInRing {

    /// Returns `1` if `p1 → p2 → q` turns counter-clockwise, `-1` if it turns
    /// clockwise, and `0` when the points are collinear.
    ///
    /// Uses a floating-point filter with a double-double fallback for
    /// near-degenerate inputs, matching JTS `CGAlgorithmsDD.orientationIndex`.
    static func orientationIndex(
        _ p1x: Double, _ p1y: Double,
        _ p2x: Double, _ p2y: Double,
        _ qx: Double, _ qy: Double
    ) -> Int {
        let dx1 = p2x - p1x
        let dy1 = p2y - p1y
        let dx2 = qx - p2x
        let dy2 = qy - p2y

        let detLeft = dx1 * dy2
        let detRight = dy1 * dx2
        let det = detLeft - detRight

        let detSum: Double
        if detLeft > 0.0 {
            if detRight <= 0.0 {
                return sign(of: det)
            }
            detSum = detLeft + detRight
        }
        else if detLeft < 0.0 {
            if detRight >= 0.0 {
                return sign(of: det)
            }
            detSum = -detLeft - detRight
        }
        else {
            return sign(of: det)
        }

        let errorBound = 0.000000000000001 * detSum
        if det >= errorBound || -det >= errorBound {
            return sign(of: det)
        }

        let ddx1 = DoubleDouble(p2x).subtracting(DoubleDouble(p1x))
        let ddy1 = DoubleDouble(p2y).subtracting(DoubleDouble(p1y))
        let ddx2 = DoubleDouble(qx).subtracting(DoubleDouble(p2x))
        let ddy2 = DoubleDouble(qy).subtracting(DoubleDouble(p2y))
        return ddx1.multiplying(ddy2).subtracting(ddy1.multiplying(ddx2)).signum
    }

    private static func sign(of value: Double) -> Int {
        if value > 0.0 {
            return 1
        }
        if value < 0.0 {
            return -1
        }
        return 0
    }

}

/// A minimal double-double value used for the exact orientation fallback.
private struct DoubleDouble {

    let hi: Double
    let lo: Double

    init(_ value: Double) {
        hi = value
        lo = 0.0
    }

    init(hi: Double, lo: Double) {
        let sum = hi + lo
        let error = lo - (sum - hi)
        self.hi = sum
        self.lo = error
    }

    var negated: DoubleDouble {
        DoubleDouble(hi: -hi, lo: -lo)
    }

    var signum: Int {
        if hi > 0.0 {
            return 1
        }
        if hi < 0.0 {
            return -1
        }
        if lo > 0.0 {
            return 1
        }
        if lo < 0.0 {
            return -1
        }
        return 0
    }

    func adding(_ other: DoubleDouble) -> DoubleDouble {
        let (sHi, sLo) = DoubleDouble.twoSum(hi, other.hi)
        let (tHi, tLo) = DoubleDouble.twoSum(lo, other.lo)
        let (uHi, uLo) = DoubleDouble.twoSum(sHi, tHi)
        return DoubleDouble(hi: uHi, lo: sLo + tLo + uLo)
    }

    func subtracting(_ other: DoubleDouble) -> DoubleDouble {
        adding(other.negated)
    }

    func multiplying(_ other: DoubleDouble) -> DoubleDouble {
        let (pHi, pLo) = DoubleDouble.twoProduct(hi, other.hi)
        let error = (hi * other.lo) + (lo * other.hi) + pLo
        return DoubleDouble(hi: pHi, lo: error + (lo * other.lo))
    }

    private static func twoSum(_ a: Double, _ b: Double) -> (Double, Double) {
        let sum = a + b
        let bb = sum - a
        let error = (a - (sum - bb)) + (b - bb)
        return (sum, error)
    }

    private static func twoProduct(_ a: Double, _ b: Double) -> (Double, Double) {
        let product = a * b
        let (aHi, aLo) = split(a)
        let (bHi, bLo) = split(b)
        let error = (((aHi * bHi) - product) + (aHi * bLo) + (aLo * bHi)) + (aLo * bLo)
        return (product, error)
    }

    private static func split(_ value: Double) -> (Double, Double) {
        let factor = 134_217_729.0 * value
        let high = factor - (factor - value)
        return (high, value - high)
    }

}
