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
    ///
    /// - Returns: `true` if the coordinate is inside the ring, `false` otherwise.
    public func contains(
        _ coordinate: Coordinate3D,
        ignoringBoundary: Bool = false
    ) -> Bool {
        let coordinate = coordinate.projected(to: projection)

        var isInside = false

        var coordinatesCount = coordinates.count
        if coordinates.first == coordinates.last {
            coordinatesCount -= 1
        }

        var j = coordinatesCount - 1
        for i in 0 ..< coordinatesCount {
            defer {
                j = i
            }

            let xi = coordinates[i].longitude
            let yi = coordinates[i].latitude
            let xj = coordinates[j].longitude
            let yj = coordinates[j].latitude

            let onBoundary = (coordinate.latitude * (xi - xj) + yi * (xj - coordinate.longitude) + yj * (coordinate.longitude - xi) == 0.0)
                && ((xi - coordinate.longitude) * (xj - coordinate.longitude) <= 0.0)
                && ((yi - coordinate.latitude) * (yj - coordinate.latitude) <= 0.0)
            if onBoundary {
                return !ignoringBoundary
            }

            let intersect = ((yi > coordinate.latitude) != (yj > coordinate.latitude))
                && (coordinate.longitude < (xj - xi) * (coordinate.latitude - yi) / (yj - yi) + xi)
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
    ///
    /// - Returns: `true` if the point is inside the ring, `false` otherwise.
    public func contains(
        _ point: Point,
        ignoringBoundary: Bool = false
    ) -> Bool {
        contains(point.coordinate, ignoringBoundary: ignoringBoundary)
    }

}

extension Polygon {

    /// Determines if *Coordinate3D* resides inside the *Polygon*. The polygon can be convex or concave.
    /// The function accounts for holes.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Parameter ignoringBoundary: `true` if the polygon boundary should be ignored when determining if the coordinate is inside the polygon (default `false`).
    ///
    /// - Returns: `true` if the coordinate is inside the polygon, `false` otherwise.
    public func contains(
        _ coordinate: Coordinate3D,
        ignoringBoundary: Bool = false
    ) -> Bool {
        if let boundingBox, !boundingBox.contains(coordinate) {
            return false
        }

        guard let outerRing = outerRing,
              outerRing.contains(coordinate, ignoringBoundary: ignoringBoundary)
        else { return false }

        if let innerRings {
            for ring in innerRings {
                if ring.contains(coordinate, ignoringBoundary: ignoringBoundary) {
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
    ///
    /// - Returns: `true` if the point is inside the ring, `false` otherwise.
    public func contains(
        _ point: Point,
        ignoringBoundary: Bool = false
    ) -> Bool {
        contains(point.coordinate, ignoringBoundary: ignoringBoundary)
    }

}

extension MultiPolygon {

    /// Determines if *Coordinate3D* resides inside the *MultiPolygon*. The polygons can be convex or concave.
    /// The function accounts for holes.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Parameter ignoringBoundary: `true` if the polygon boundaries should be ignored when determining if the coordinate is inside of one of the polygons (default `false`).
    ///
    /// - Returns: `true` if the coordinate is inside of one of the polygons, `false` otherwise.
    public func contains(
        _ coordinate: Coordinate3D,
        ignoringBoundary: Bool = false
    ) -> Bool {
        if let boundingBox, !boundingBox.contains(coordinate) {
            return false
        }

        for polygon in polygons {
            if polygon.contains(coordinate, ignoringBoundary: ignoringBoundary) {
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
    ///
    /// - Returns: `true` if the coordinate is inside of one of the polygons, `false` otherwise.
    public func contains(
        _ point: Point,
        ignoringBoundary: Bool = false
    ) -> Bool {
        contains(point.coordinate, ignoringBoundary: ignoringBoundary)
    }

}

extension GeometryCollection {

    /// Determines if *Coordinate3D* resides inside the *GeometryCollection*.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Parameter ignoringBoundary: `true` if the boundaries should be ignored when determining if the coordinate is inside of one of the geometries (default `false`).
    ///
    /// - Returns: `true` if the coordinate is inside of one of the geometries, `false` otherwise.
    public func contains(
        _ coordinate: Coordinate3D,
        ignoringBoundary: Bool = false
    ) -> Bool {
        geometries.contains { (geometry) -> Bool in
            guard let polygonGeometry = geometry as? PolygonGeometry else { return false }

            return polygonGeometry.contains(coordinate, ignoringBoundary: ignoringBoundary)
        }
    }

}

extension Feature {

    /// Determines if *Coordinate3D* resides inside the *Feature*.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Parameter ignoringBoundary: `true` if the boundaries should be ignored when determining if the coordinate is inside of the Feature's geometry (default `false`).
    ///
    /// - Returns: `true` if the coordinate is inside of one of the Feature's geometry, `false` otherwise.
    public func contains(
        _ coordinate: Coordinate3D,
        ignoringBoundary: Bool = false
    ) -> Bool {
        guard let polygonGeometry = geometry as? PolygonGeometry else { return false }

        return polygonGeometry.contains(coordinate, ignoringBoundary: ignoringBoundary)
    }

}

extension FeatureCollection {

    /// Determines if *Coordinate3D* resides inside the *FeatureCollection*.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Parameter ignoringBoundary: `true` if the boundaries should be ignored when determining if the coordinate is inside of one of the geometries (default `false`).
    ///
    /// - Returns: `true` if the coordinate is inside of one of the geometries, `false` otherwise.
    public func contains(
        _ coordinate: Coordinate3D,
        ignoringBoundary: Bool = false
    ) -> Bool {
        features.contains(where: { $0.contains(coordinate, ignoringBoundary: ignoringBoundary) })
    }

}
