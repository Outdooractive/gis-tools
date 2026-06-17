#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

extension Polygon {

    /// Returns the union of the receiver with another polygon geometry.
    ///
    /// - Parameter other: The other polygon geometry
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: A `MultiPolygon` representing the union, or `nil` if the union is empty.
    public func union(with other: PolygonGeometry, gridSize: Double? = nil) -> MultiPolygon? {
        let all: [Polygon]
        if let gridSize {
            all = [self.snappedToGrid(tolerance: gridSize)]
                + other.polygons.map { $0.snappedToGrid(tolerance: gridSize) }
        } else {
            all = self.polygons + other.polygons
        }
        return Union.unionPolygons(all)
    }

}

extension MultiPolygon {

    /// Returns the union of the receiver with another polygon geometry.
    ///
    /// - Parameter other: The other polygon geometry
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: A `MultiPolygon` representing the union, or `nil` if the union is empty.
    public func union(with other: PolygonGeometry, gridSize: Double? = nil) -> MultiPolygon? {
        let all: [Polygon]
        if let gridSize {
            all = self.polygons.map { $0.snappedToGrid(tolerance: gridSize) }
                + other.polygons.map { $0.snappedToGrid(tolerance: gridSize) }
        } else {
            all = self.polygons + other.polygons
        }
        return Union.unionPolygons(all)
    }

    /// Forms the union of the receiver with another polygon geometry in place.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    public mutating func formUnion(with other: PolygonGeometry, gridSize: Double? = nil) {
        guard let merged = union(with: other, gridSize: gridSize) else { return }
        self = merged
    }

}

extension FeatureCollection {

    /// Returns the union of all polygon features in the collection.
    ///
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: A `FeatureCollection` containing the unioned polygon, or `nil` if no polygons exist.
    public func union(gridSize: Double? = nil) -> FeatureCollection? {
        let snappedFC = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let geometries = snappedFC.features
            .compactMap { ($0.geometry as? PolygonGeometry)?.polygons }
            .flatMap { $0 }
        guard let result = Union.unionPolygons(geometries) else { return nil }
        return FeatureCollection(Feature(result))
    }

}

// MARK: - Union implementation

enum Union {

    /// - Note: The union algorithm works in EPSG:3857 (Web Mercator) for uniform
    ///   Cartesian tolerances. Inputs are automatically reprojected. This limits
    ///   the usable latitude range to approximately ±85°.
    public static func unionPolygons(_ polygons: [Polygon]) -> MultiPolygon? {
        guard polygons.isNotEmpty else { return nil }

        guard polygons.count > 1 else {
            return MultiPolygon(unchecked: polygons)
        }

        // Work in EPSG:3857 so all tolerances are uniform meters
        let originalProj = polygons.first?.projection ?? .epsg4326
        let polygons3857 = originalProj == .epsg3857
            ? polygons
            : polygons.map { $0.projected(to: .epsg3857) }

        let boundaryTest = Overlay.makeBoundaryTest { point, polygons in
            polygons.contains { $0.contains(point, ignoringBoundary: true) }
        }
        guard let result = Overlay.overlayPolygons(polygons3857, boundaryTest: boundaryTest) else {
            return nil
        }

        return result.projected(to: originalProj)
    }

}
