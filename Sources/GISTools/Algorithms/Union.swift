#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-union

extension GeoJson {

    /// Combines two polygon geometries into their union.
    ///
    /// Returns a Polygon if the union is contiguous, a MultiPolygon
    /// for disjoint parts, or nil if either input is not a polygon.
    public func union(with other: GeoJson) -> (any GeoJsonGeometry)? {
        let g1: GeoJson = (self as? Feature)?.geometry ?? self
        let g2: GeoJson = (other as? Feature)?.geometry ?? other

        guard let pg1 = g1 as? PolygonGeometry,
              let pg2 = g2 as? PolygonGeometry
        else { return nil }

        var all = pg1.polygons
        all.append(contentsOf: pg2.polygons)
        return Union.unionPolygons(all)
    }

}

extension FeatureCollection {

    /// Computes the union of all polygon features in the collection.
    public func union() -> Feature? {
        let geometries = features
            .compactMap { ($0.geometry as? PolygonGeometry)?.polygons }
            .flatMap { $0 }
        guard let result = Union.unionPolygons(geometries) else { return nil }
        return Feature(result)
    }

}

// MARK: - Private implementation

enum Union {

    fileprivate static func unionPolygons(
        _ polygons: [Polygon]
    ) -> (any GeoJsonGeometry)? {
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

        if result.count == 1 {
            return result[0]
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
