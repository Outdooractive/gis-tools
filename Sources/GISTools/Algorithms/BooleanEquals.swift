#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

extension GeoJson {

    /// Returns `true` if the receiver and `other` represent the same point set.
    ///
    /// This is OGC `ST_Equals`. Structural equality remains `==`.
    ///
    /// `==` compares the stored representation: geometry type, projection,
    /// vertex count and coordinates (with ring-start rotation tolerated for
    /// polygons). `equals(_:)` is topological: it ignores representation and
    /// vertex order, and returns `true` whenever each geometry covers the
    /// other. For example, two differently wound polygons with the same area
    /// and boundary are `equals`, but are not necessarily `==`.
    ///
    /// - Parameter other: The other geometry
    /// - Returns: `true` if both geometries cover each other
    public func equals(_ other: GeoJson) -> Bool {
        if let first = self as? PolygonGeometry,
           let second = other as? PolygonGeometry
        {
            guard let intersectionArea = PolygonPredicateHelpers.intersectionArea(first, second) else {
                return false
            }
            return AreaComparison.areEqual(intersectionArea, PolygonPredicateHelpers.area(first))
                && AreaComparison.areEqual(intersectionArea, PolygonPredicateHelpers.area(second))
        }

        return covers(other) && other.covers(self)
    }

}

// MARK: - Area comparison

enum AreaComparison {

    static func areEqual(_ first: Double, _ second: Double) -> Bool {
        let scale = max(abs(first), abs(second), 1.0)
        return abs(first - second) <= scale * 0.000000001
    }

}

// MARK: - Polygon area helpers

enum PolygonPredicateHelpers {

    static func area(_ geometry: PolygonGeometry) -> Double {
        switch geometry {
        case let polygon as Polygon:
            return polygon.area
        case let multiPolygon as MultiPolygon:
            return multiPolygon.area
        default:
            return 0.0
        }
    }

    static func intersectionArea(
        _ first: PolygonGeometry,
        _ second: PolygonGeometry
    ) -> Double? {
        Intersection.intersectPolygons(first.polygons + second.polygons).map(area)
    }

}
