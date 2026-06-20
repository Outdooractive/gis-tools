#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-boolean-point-in-polygon

extension Ring {

    /// Determines if *Coordinate3D* resides inside the *Ring*. The ring can be convex or concave.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Parameter ignoringBoundary: `true` if the ring boundary should be ignored when determining if the coordinate is inside the ring (default `false`).
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    ///
    /// - Returns: `true` if the coordinate is inside the ring, `false` otherwise.
    public func contains(
        _ coordinate: Coordinate3D,
        ignoringBoundary: Bool = false,
        gridSize: Double? = nil
    ) -> Bool {
        let coordinate = coordinate.projected(to: projection)
        let snappedCoordinate = gridSize.map { coordinate.snappedToGrid(tolerance: $0) } ?? coordinate
        let snappedCoordinates = gridSize.map { Ring(unchecked: coordinates).snappedToGrid(tolerance: $0).coordinates } ?? coordinates

        var isInside = false

        var coordinatesCount = snappedCoordinates.count
        if snappedCoordinates.first == snappedCoordinates.last {
            coordinatesCount -= 1
        }

        // Detect antimeridian crossing (EPSG:4326 only): check if any edge
        // jumps more than 180° in longitude, which indicates the ring wraps
        // across ±180°. For projected systems (3857, 4978) the X values are
        // in meters where a >180 jump is just a long edge.
        var crossesAntimeridian = false
        if projection == .epsg4326 {
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

        var testLon = snappedCoordinate.longitude
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

            let onBoundary = (snappedCoordinate.latitude * (xi - xj) + yi * (xj - testLon) + yj * (testLon - xi) == 0.0)
                && ((xi - testLon) * (xj - testLon) <= 0.0)
                && ((yi - snappedCoordinate.latitude) * (yj - snappedCoordinate.latitude) <= 0.0)
            if onBoundary {
                return !ignoringBoundary
            }

            let intersect = ((yi > snappedCoordinate.latitude) != (yj > snappedCoordinate.latitude))
                && (testLon < (xj - xi) * (snappedCoordinate.latitude - yi) / (yj - yi) + xi)
            if (intersect) {
                isInside = !isInside
            }
        }

        return isInside
    }

    /// Determines if *Point* resides inside the *Ring*. The ring can be convex or concave.
    ///
    /// - Parameter point: The point to check
    /// - Parameter ignoringBoundary: `true` if the ring boundary should be ignored when determining if the point is inside the ring (default `false`).
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    ///
    /// - Returns: `true` if the point is inside the ring, `false` otherwise.
    public func contains(
        _ point: Point,
        ignoringBoundary: Bool = false,
        gridSize: Double? = nil
    ) -> Bool {
        contains(point.coordinate, ignoringBoundary: ignoringBoundary, gridSize: gridSize)
    }

}

extension Polygon {

    /// Determines if *Coordinate3D* resides inside the *Polygon*. The polygon can be convex or concave.
    /// The function accounts for holes.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Parameter ignoringBoundary: `true` if the polygon boundary should be ignored when determining if the coordinate is inside the polygon (default `false`).
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    ///
    /// - Returns: `true` if the coordinate is inside the polygon, `false` otherwise.
    public func contains(
        _ coordinate: Coordinate3D,
        ignoringBoundary: Bool = false,
        gridSize: Double? = nil
    ) -> Bool {
        let snappedSelf = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let snappedCoordinate = gridSize.map { coordinate.snappedToGrid(tolerance: $0) } ?? coordinate

        if let boundingBox = snappedSelf.boundingBox,
           !boundingBox.contains(snappedCoordinate)
        {
            // Bounding box doesn't contain the point. If the polygon crosses the
            // antimeridian, the point may still be inside the wrapped side.
            if let outerRing = snappedSelf.outerRing,
               projection == .epsg4326
            {
                let coords = outerRing.coordinates
                var crossesAM = false
                for i in 1..<coords.count {
                    let dLon = coords[i].longitude - coords[i-1].longitude
                    if abs(dLon) > 180.0, abs(dLon) < 360.0 {
                        crossesAM = true
                        break
                    }
                }
                if !crossesAM {
                    return false
                }
            } else {
                return false
            }
        }

        guard let outerRing = snappedSelf.outerRing,
              outerRing.contains(snappedCoordinate, ignoringBoundary: ignoringBoundary)
        else { return false }

        if let innerRings = snappedSelf.innerRings {
            for ring in innerRings {
                if ring.contains(snappedCoordinate, ignoringBoundary: ignoringBoundary) {
                    return false
                }
            }
        }

        return true
    }

    /// Determines if *Point* resides inside the *Polygon*. The polygon can be convex or concave.
    /// The function accounts for holes.
    ///
    /// - Parameter point: The point to check
    /// - Parameter ignoringBoundary: `true` if the polygon boundary should be ignored when determining if the point is inside the polygon (default `false`).
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    ///
    /// - Returns: `true` if the point is inside the ring, `false` otherwise.
    public func contains(
        _ point: Point,
        ignoringBoundary: Bool = false,
        gridSize: Double? = nil
    ) -> Bool {
        contains(point.coordinate, ignoringBoundary: ignoringBoundary, gridSize: gridSize)
    }

}

extension MultiPolygon {

    /// Determines if *Coordinate3D* resides inside the *MultiPolygon*. The polygons can be convex or concave.
    /// The function accounts for holes.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Parameter ignoringBoundary: `true` if the polygon boundaries should be ignored when determining if the coordinate is inside of one of the polygons (default `false`).
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    ///
    /// - Returns: `true` if the coordinate is inside of one of the polygons, `false` otherwise.
    public func contains(
        _ coordinate: Coordinate3D,
        ignoringBoundary: Bool = false,
        gridSize: Double? = nil
    ) -> Bool {
        let snappedSelf = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let snappedCoordinate = gridSize.map { coordinate.snappedToGrid(tolerance: $0) } ?? coordinate

        if let boundingBox = snappedSelf.boundingBox, !boundingBox.contains(snappedCoordinate) {
            return false
        }

        for polygon in snappedSelf.polygons {
            if polygon.contains(snappedCoordinate, ignoringBoundary: ignoringBoundary) {
                return true
            }
        }

        return false
    }

    /// Determines if *Point* resides inside the *MultiPolygon*. The polygons can be convex or concave.
    /// The function accounts for holes.
    ///
    /// - Parameter point: The coordinate to check
    /// - Parameter ignoringBoundary: `true` if the polygon boundaries should be ignored when determining if the coordinate is inside of one of the polygons (default `false`).
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    ///
    /// - Returns: `true` if the coordinate is inside of one of the polygons, `false` otherwise.
    public func contains(
        _ point: Point,
        ignoringBoundary: Bool = false,
        gridSize: Double? = nil
    ) -> Bool {
        contains(point.coordinate, ignoringBoundary: ignoringBoundary, gridSize: gridSize)
    }

}

extension GeometryCollection {

    /// Determines if *Coordinate3D* resides inside the *GeometryCollection*.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Parameter ignoringBoundary: `true` if the boundaries should be ignored when determining if the coordinate is inside of one of the geometries (default `false`).
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    ///
    /// - Returns: `true` if the coordinate is inside of one of the geometries, `false` otherwise.
    public func contains(
        _ coordinate: Coordinate3D,
        ignoringBoundary: Bool = false,
        gridSize: Double? = nil
    ) -> Bool {
        let snappedSelf = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let snappedCoordinate = gridSize.map { coordinate.snappedToGrid(tolerance: $0) } ?? coordinate

        return snappedSelf.geometries.contains { (geometry) -> Bool in
            guard let polygonGeometry = geometry as? PolygonGeometry else { return false }

            return polygonGeometry.contains(snappedCoordinate, ignoringBoundary: ignoringBoundary, gridSize: nil)
        }
    }

}

extension Feature {

    /// Determines if *Coordinate3D* resides inside the *Feature*.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Parameter ignoringBoundary: `true` if the boundaries should be ignored when determining if the coordinate is inside of the Feature's geometry (default `false`).
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    ///
    /// - Returns: `true` if the coordinate is inside of one of the Feature's geometry, `false` otherwise.
    public func contains(
        _ coordinate: Coordinate3D,
        ignoringBoundary: Bool = false,
        gridSize: Double? = nil
    ) -> Bool {
        let snappedSelf = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let snappedCoordinate = gridSize.map { coordinate.snappedToGrid(tolerance: $0) } ?? coordinate

        guard let polygonGeometry = snappedSelf.geometry as? PolygonGeometry else { return false }

        return polygonGeometry.contains(snappedCoordinate, ignoringBoundary: ignoringBoundary, gridSize: nil)
    }

}

extension FeatureCollection {

    /// Determines if *Coordinate3D* resides inside the *FeatureCollection*.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Parameter ignoringBoundary: `true` if the boundaries should be ignored when determining if the coordinate is inside of one of the geometries (default `false`).
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    ///
    /// - Returns: `true` if the coordinate is inside of one of the geometries, `false` otherwise.
    public func contains(
        _ coordinate: Coordinate3D,
        ignoringBoundary: Bool = false,
        gridSize: Double? = nil
    ) -> Bool {
        let snappedSelf = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let snappedCoordinate = gridSize.map { coordinate.snappedToGrid(tolerance: $0) } ?? coordinate

        return snappedSelf.features.contains(where: { $0.contains(snappedCoordinate, ignoringBoundary: ignoringBoundary, gridSize: nil) })
    }

}
