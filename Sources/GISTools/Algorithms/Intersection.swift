import Foundation

extension Polygon {

    /// Returns the geometric intersection of the receiver with another polygon geometry.
    ///
    /// The result is the overlapping region that lies inside both polygons.
    ///
    /// - Parameter other: The other polygon geometry
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: A `PolygonGeometry` representing the intersection, or `nil` if the polygons do not overlap.
    public func intersection(
        with other: PolygonGeometry,
        gridSize: Double? = nil
    ) -> PolygonGeometry? {
        let all: [Polygon]
        if let gridSize {
            all = [self.snappedToGrid(tolerance: gridSize)]
                + other.polygons.map { $0.snappedToGrid(tolerance: gridSize) }
        } else {
            all = self.polygons + other.polygons
        }
        return Intersection.intersectPolygons(all)
    }

}

extension MultiPolygon {

    /// Returns the geometric intersection of the receiver with another polygon geometry.
    ///
    /// - Parameter other: The other polygon geometry
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: A `PolygonGeometry` representing the intersection, or `nil` if the polygons do not overlap.
    public func intersection(
        with other: PolygonGeometry,
        gridSize: Double? = nil
    ) -> PolygonGeometry? {
        let all: [Polygon]
        if let gridSize {
            all = self.polygons.map { $0.snappedToGrid(tolerance: gridSize) }
                + other.polygons.map { $0.snappedToGrid(tolerance: gridSize) }
        } else {
            all = self.polygons + other.polygons
        }
        return Intersection.intersectPolygons(all)
    }

}

// MARK: - Intersection implementation

enum Intersection {

    /// - Note: The intersection algorithm works in EPSG:3857 (Web Mercator) for uniform
    ///   Cartesian tolerances. Inputs are automatically reprojected. This limits
    ///   the usable latitude range to approximately ±85°.
    static func intersectPolygons(_ polygons: [Polygon]) -> PolygonGeometry? {
        guard polygons.isNotEmpty else { return nil }
        guard polygons.count > 1 else { return nil }

        // Work in EPSG:3857 so all tolerances are uniform meters
        let originalProj = polygons.first?.projection ?? .epsg4326
        let polygons3857 = originalProj == .epsg3857
            ? polygons
            : polygons.map { $0.projected(to: .epsg3857) }

        let boundaryTest = Overlay.makeBoundaryTest { point, polygons in
            polygons.allSatisfy { $0.contains(point, ignoringBoundary: true) }
        }
        guard let result = Overlay.overlayPolygons(polygons3857, boundaryTest: boundaryTest) else {
            return nil
        }

        let projected = result.projected(to: originalProj)
        // Return a single Polygon if possible, MultiPolygon otherwise
        if projected.polygons.count == 1 {
            return projected.polygons[0]
        }
        return projected
    }

}
