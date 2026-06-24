import Foundation

extension Polygon {

    /// Returns the geometric difference of the receiver minus another polygon geometry.
    ///
    /// The result is the part of the receiver that is not covered by the other polygon (A − B).
    ///
    /// All projections are supported. For non-3857 projections the geometries
    /// are projected to EPSG:3857, the overlay is computed, and the result is
    /// projected back to the original CRS.
    ///
    /// - Parameter other: The other polygon geometry to subtract
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: A `PolygonGeometry` representing the difference, or `nil` if the result is empty.
    public func difference(
        with other: PolygonGeometry,
        gridSize: Double? = nil
    ) -> PolygonGeometry? {
        let all: [Polygon]
        if let gridSize {
            all = [self.snappedToGrid(tolerance: gridSize)]
                + other.polygons.map { $0.snappedToGrid(tolerance: gridSize) }
        }
        else {
            all = self.polygons + other.polygons
        }
        return Difference.differencePolygons(all)
    }

}

extension MultiPolygon {

    /// Returns the geometric difference of the receiver minus another polygon geometry.
    ///
    /// All projections are supported. For non-3857 projections the geometries
    /// are projected to EPSG:3857, the overlay is computed, and the result is
    /// projected back to the original CRS.
    ///
    /// - Parameter other: The other polygon geometry to subtract
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: A `PolygonGeometry` representing the difference, or `nil` if the result is empty.
    public func difference(
        with other: PolygonGeometry,
        gridSize: Double? = nil
    ) -> PolygonGeometry? {
        let all: [Polygon]
        if let gridSize {
            all = self.polygons.map { $0.snappedToGrid(tolerance: gridSize) }
                + other.polygons.map { $0.snappedToGrid(tolerance: gridSize) }
        }
        else {
            all = self.polygons + other.polygons
        }
        return Difference.differencePolygons(all)
    }

}

// MARK: - Difference implementation

enum Difference {

    /// - Note: The difference algorithm works in EPSG:3857 (Web Mercator) for uniform
    ///   Cartesian tolerances. Inputs are automatically reprojected. This limits
    ///   the usable latitude range to approximately ±85°.
    static func differencePolygons(_ polygons: [Polygon]) -> PolygonGeometry? {
        guard polygons.isNotEmpty else { return nil }
        guard polygons.count > 1 else { return MultiPolygon(unchecked: polygons) }

        let originalProj = polygons.first?.projection ?? .epsg4326
        let polygons3857 = originalProj == .epsg3857
            ? polygons
            : polygons.map { $0.projected(to: .epsg3857) }

        // polygon[0] = A (positive), polygon[1...] = B (negative / to subtract)
        let a = polygons3857[0]
        let b = Array(polygons3857.dropFirst())

        let boundaryTest = Overlay.makeBoundaryTest { point, _ in
            a.contains(point, ignoringBoundary: true)
                && !b.contains { $0.contains(point, ignoringBoundary: true) }
        }

        guard let result = Overlay.overlayPolygons(polygons3857, boundaryTest: boundaryTest) else {
            return nil
        }

        let projected = result.projected(to: originalProj)
        if projected.polygons.count == 1 {
            return projected.polygons[0]
        }
        return projected
    }

}
