#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-union

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

    /// Computes the union of all polygon features in the collection.
    public func union() -> FeatureCollection? {
        let geometries = features
            .compactMap { ($0.geometry as? PolygonGeometry)?.polygons }
            .flatMap { $0 }
        guard let result = Union.unionPolygons(geometries) else { return nil }
        return FeatureCollection(Feature(result))
    }

}

// MARK: - Private implementation

enum Union {

    public static func unionPolygons(
        _ polygons: [Polygon]
    ) -> MultiPolygon? {
        guard polygons.isNotEmpty else { return nil }

        var result: [Polygon] = []
        var remaining = polygons

        while remaining.isNotEmpty {
            var merged = remaining.removeFirst()
            var didMerge: Bool
            repeat {
                didMerge = false
                var newRemaining: [Polygon] = []
                for poly in remaining {
                    if let union = mergeTwo(merged, poly) {
                        merged = union
                        didMerge = true
                    }
                    else {
                        newRemaining.append(poly)
                    }
                }
                remaining = newRemaining
            } while didMerge
            result.append(merged)
        }

        return MultiPolygon(unchecked: result)
    }

    private static func mergeTwo(
        _ a: Polygon,
        _ b: Polygon
    ) -> Polygon? {
        guard let outerA = a.outerRing?.coordinates.first,
              let outerB = b.outerRing?.coordinates.first
        else { return nil }

        if a.contains(outerB, ignoringBoundary: true) { return a }
        if b.contains(outerA, ignoringBoundary: true) { return b }

        guard a.intersects(b.calculateBoundingBox() ?? BoundingBox(coordinates: b.allCoordinates)!),
              b.intersects(a.calculateBoundingBox() ?? BoundingBox(coordinates: a.allCoordinates)!)
        else { return nil }

        return nil
    }

}
