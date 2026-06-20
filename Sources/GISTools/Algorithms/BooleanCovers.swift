import Foundation

// Ported from GEOS Covers / CoveredBy

extension GeoJson {

    /// Compares two geometries and returns `true` if the receiver covers the
    /// other geometry.
    ///
    /// "A covers B" means that no points of B lie in the exterior of A.
    /// Unlike ``contains(_:)``, points on the boundary are considered covered.
    ///
    /// - Parameter other: The other geometry
    /// - Returns: `true` if the receiver covers the other geometry
    public func covers(_ other: GeoJson) -> Bool {
        if let fc1 = self as? FeatureCollection {
            return fc1.features.contains { $0.covers(other) }
        }
        if let fc2 = other as? FeatureCollection {
            return fc2.features.contains { self.covers($0) }
        }

        let geom1: GeoJson = (self as? Feature)?.geometry ?? self
        let geom2: GeoJson = (other as? Feature)?.geometry ?? other

        return BooleanContains.contains(geom1 as! GeoJsonGeometry, geom2 as! GeoJsonGeometry)
    }

    /// Compares two geometries and returns `true` if the receiver is covered by
    /// the other geometry.
    ///
    /// "A is covered by B" means that no points of A lie in the exterior of B.
    /// Unlike ``isWithin(_:)``, points on the boundary are considered covered.
    ///
    /// - Parameter other: The other geometry
    /// - Returns: `true` if the receiver is covered by the other geometry
    public func coveredBy(_ other: GeoJson) -> Bool {
        other.covers(self)
    }

}
