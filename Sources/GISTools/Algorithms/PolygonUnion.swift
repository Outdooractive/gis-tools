#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

extension Polygon {

    public func union(_ other: PolygonGeometry) -> MultiPolygon {
        UnionHelper.union(polygons: [self, other])
    }

}

extension MultiPolygon {

    public func union(_ other: PolygonGeometry) -> MultiPolygon {
        UnionHelper.union(polygons: [self, other])
    }

    public mutating func formUnion(_ other: PolygonGeometry) {
        self = union(other)
    }

}

struct UnionHelper {

    static func union(polygons: [PolygonGeometry]) -> MultiPolygon {
        assert(polygons.isNotEmpty, "Input polygons must not be empty")

        let inputPolygons = polygons.map(\.polygons).flatMap({ $0 })

        return MultiPolygon(inputPolygons)!
    }

}
