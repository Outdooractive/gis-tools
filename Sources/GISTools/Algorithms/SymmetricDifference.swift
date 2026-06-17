import Foundation

extension Polygon {

    /// Returns the symmetric difference (geometric XOR) of the receiver with another
    /// polygon geometry.
    ///
    /// The result is the parts of each polygon that do not overlap — i.e. (A ∪ B) − (A ∩ B).
    ///
    /// - Parameter other: The other polygon geometry
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: A `PolygonGeometry` representing the symmetric difference, or `nil` if empty.
    public func symmetricDifference(
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
        return SymmetricDifference.symmetricDifferencePolygons(all)
    }

}

extension MultiPolygon {

    /// Returns the symmetric difference (geometric XOR) of the receiver with another
    /// polygon geometry.
    ///
    /// - Parameter other: The other polygon geometry
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: A `PolygonGeometry` representing the symmetric difference, or `nil` if empty.
    public func symmetricDifference(
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
        return SymmetricDifference.symmetricDifferencePolygons(all)
    }

}

// MARK: - SymmetricDifference implementation

enum SymmetricDifference {

    /// - Note: The symmetric difference algorithm works in EPSG:3857 (Web Mercator)
    ///   for uniform Cartesian tolerances. Inputs are automatically reprojected.
    ///   This limits the usable latitude range to approximately ±85°.
    static func symmetricDifferencePolygons(_ polygons: [Polygon]) -> PolygonGeometry? {
        guard polygons.isNotEmpty else { return nil }
        guard polygons.count > 1 else { return MultiPolygon(unchecked: polygons) }

        let originalProj = polygons.first?.projection ?? .epsg4326
        let polygons3857 = originalProj == .epsg3857
            ? polygons
            : polygons.map { $0.projected(to: .epsg3857) }

        // polygon[0...] = A (self), polygon[remaining] = B (other)
        let boundaryTest = Overlay.makeBoundaryTest { point, _ in
            let inA = polygons3857[0].contains(point, ignoringBoundary: true)
            let inB = polygons3857.dropFirst().contains { $0.contains(point, ignoringBoundary: true) }
            return inA != inB
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
