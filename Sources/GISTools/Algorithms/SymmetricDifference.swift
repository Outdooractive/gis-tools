extension Polygon {

    /// Returns the symmetric difference (geometric XOR) of the receiver with another
    /// polygon geometry.
    ///
    /// The result is the parts of each polygon that do not overlap — i.e. (A ∪ B) − (A ∩ B).
    ///
    /// All projections are supported. The internal overlay operates in EPSG:3857
    /// for uniform Cartesian tolerances and projects the result back.
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
            all = [snappedToGrid(tolerance: gridSize)]
                + other.polygons.map { $0.snappedToGrid(tolerance: gridSize) }
        }
        else {
            all = polygons + other.polygons
        }
        return SymmetricDifference.symmetricDifferencePolygons(all, firstCount: 1)
    }

}

extension MultiPolygon {

    /// Returns the symmetric difference (geometric XOR) of the receiver with another
    /// polygon geometry.
    ///
    /// All projections are supported. The internal overlay operates in EPSG:3857
    /// for uniform Cartesian tolerances and projects the result back.
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
            all = polygons.map { $0.snappedToGrid(tolerance: gridSize) }
                + other.polygons.map { $0.snappedToGrid(tolerance: gridSize) }
        }
        else {
            all = polygons + other.polygons
        }
        return SymmetricDifference.symmetricDifferencePolygons(all, firstCount: polygons.count)
    }

}

// MARK: - SymmetricDifference implementation

enum SymmetricDifference {

    /// - Note: The symmetric difference algorithm works in EPSG:3857 (Web Mercator)
    ///   for uniform Cartesian tolerances. Inputs are automatically reprojected.
    ///   This limits the usable latitude range to approximately ±85°.
    static func symmetricDifferencePolygons(
        _ polygons: [Polygon],
        firstCount: Int
    ) -> PolygonGeometry? {
        guard polygons.isNotEmpty else { return nil }
        guard polygons.count > 1 else { return MultiPolygon(unchecked: polygons) }
        guard firstCount > 0, firstCount < polygons.count else { return nil }

        let originalProj = polygons.first?.projection ?? .epsg4326
        let normalized = polygons.map {
            $0.projection == originalProj ? $0 : $0.projected(to: originalProj)
        }

        let first = Array(normalized.prefix(firstCount))
        let second = Array(normalized.suffix(from: firstCount))

        // XOR is the union of the two one-sided differences. Building it from
        // the independently tested difference/union operations avoids the
        // multi-component ring-assembly bug in the previous XOR boundary pass.
        let firstMinusSecond = Difference.differencePolygons(
            first + second,
            firstCount: first.count)
        let secondMinusFirst = Difference.differencePolygons(
            second + first,
            firstCount: second.count)

        let parts = [firstMinusSecond, secondMinusFirst]
            .compactMap { $0?.polygons }
            .flatMap { $0 }

        guard parts.isNotEmpty else { return nil }

        return Union.unionPolygons(parts)
    }

}
