#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

extension Polygon {
    public func union(with other: PolygonGeometry) -> MultiPolygon? {
        var all = self.polygons
        all.append(contentsOf: other.polygons)
        return Union.unionPolygons(all)
    }
}

extension MultiPolygon {
    public func union(with other: PolygonGeometry) -> MultiPolygon? {
        var all = self.polygons
        all.append(contentsOf: other.polygons)
        return Union.unionPolygons(all)
    }
    public mutating func formUnion(with other: PolygonGeometry) {
        guard let merged = union(with: other) else { return }
        self = merged
    }
}

extension FeatureCollection {
    public func union() -> FeatureCollection? {
        let geometries = features
            .compactMap { ($0.geometry as? PolygonGeometry)?.polygons }
            .flatMap { $0 }
        guard let result = Union.unionPolygons(geometries) else { return nil }
        return FeatureCollection(Feature(result))
    }
}

// MARK: - Implementation

enum Union {

    public static func unionPolygons(_ polygons: [Polygon]) -> MultiPolygon? {
        guard polygons.isNotEmpty else { return nil }

        return MultiPolygon(unchecked: polygons)
    }

}
