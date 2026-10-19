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

        // Detect antimeridian crossing (degree-based projections only): check if any edge
        // jumps more than 180° in longitude, which indicates the ring wraps
        // across ±180°. For projected systems (3857, 4978) the X values are
        // in meters where a >180 jump is just a long edge.
        var crossesAntimeridian = false
        if projection.isGeographic {
            for i in 0 ..< coordinatesCount {
                let j = (i + coordinatesCount - 1) % coordinatesCount
                let dLon = snappedCoordinates[i].longitude - snappedCoordinates[j].longitude
                // Edge jumps between 180° and 360° indicate antimeridian crossing.
                // An edge with exactly 360° (e.g. world polygon from -180 to 180)
                // spans the full globe and does NOT cross.
                if abs(dLon) > 180.0, abs(dLon) < 360.0 {
                    crossesAntimeridian = true
                    break
                }
            }
        }

        var testLon = coordinate.longitude
        if crossesAntimeridian {
            testLon = testLon < 0 ? testLon + 360.0 : testLon
        }

        var j = coordinatesCount - 1
        for i in 0 ..< coordinatesCount {
            defer {
                j = i
            }

            var xi = snappedCoordinates[i].longitude
            let yi = snappedCoordinates[i].latitude
            var xj = snappedCoordinates[j].longitude
            let yj = snappedCoordinates[j].latitude

            if crossesAntimeridian {
                xi = xi < 0 ? xi + 360.0 : xi
                xj = xj < 0 ? xj + 360.0 : xj
            }

            let onBoundary = (coordinate.latitude * (xi - xj) + yi * (xj - testLon) + yj * (testLon - xi) == 0.0)
                && ((xi - testLon) * (xj - testLon) <= 0.0)
                && ((yi - coordinate.latitude) * (yj - coordinate.latitude) <= 0.0)
            if onBoundary {
                return .boundary
            }

            let intersect = ((yi > coordinate.latitude) != (yj > coordinate.latitude))
                && (testLon < (xj - xi) * (coordinate.latitude - yi) / (yj - yi) + xi)
            if (intersect) {
                isInside = !isInside
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
               projection.isGeographic
            {
                let coords = outerRing.coordinates
                var crossesAM = false
                for i in 1 ..< coords.count {
                    let dLon = coords[i].longitude - coords[i - 1].longitude
                    if abs(dLon) > 180.0, abs(dLon) < 360.0 {
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
