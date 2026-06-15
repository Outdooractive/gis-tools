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

        var j = coordinatesCount - 1
        for i in 0 ..< coordinatesCount {
            defer {
                j = i
            }

            let xi = snappedCoordinates[i].longitude
            let yi = snappedCoordinates[i].latitude
            let xj = snappedCoordinates[j].longitude
            let yj = snappedCoordinates[j].latitude

            let onBoundary = (snappedCoordinate.latitude * (xi - xj) + yi * (xj - snappedCoordinate.longitude) + yj * (snappedCoordinate.longitude - xi) == 0.0)
                && ((xi - snappedCoordinate.longitude) * (xj - snappedCoordinate.longitude) <= 0.0)
                && ((yi - snappedCoordinate.latitude) * (yj - snappedCoordinate.latitude) <= 0.0)
            if onBoundary {
                return !ignoringBoundary
            }

            let intersect = ((yi > snappedCoordinate.latitude) != (yj > snappedCoordinate.latitude))
                && (snappedCoordinate.longitude < (xj - xi) * (snappedCoordinate.latitude - yi) / (yj - yi) + xi)
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

        if let boundingBox = snappedSelf.boundingBox, !boundingBox.contains(snappedCoordinate) {
            return false
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
