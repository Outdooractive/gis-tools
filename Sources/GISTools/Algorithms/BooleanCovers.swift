import Foundation

// Ported from GEOS Covers / CoveredBy

extension GeoJson {

    /// Compares two geometries and returns `true` if the receiver covers the
    /// other geometry.
    ///
    /// "A covers B" means that no points of B lie in the exterior of A.
    /// Unlike ``contains(_:)``, points on the boundary are considered covered.
    ///
    /// For ``Projection/epsg3857`` and ``Projection/epsg4978`` the geometries
    /// are projected to ``Projection/epsg4326`` first. Altitude differences
    /// are ignored.
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

        let normalised1 = geom1.projected(to: .epsg4326)
        let normalised2 = geom2.projected(to: .epsg4326)

        return BooleanContains.contains(
            normalised1 as! GeoJsonGeometry,
            normalised2 as! GeoJsonGeometry)
    }

    /// Compares two geometries and returns `true` if the receiver is covered by
    /// the other geometry.
    ///
    /// "A is covered by B" means that no points of A lie in the exterior of B.
    /// Unlike ``isWithin(_:)``, points on the boundary are considered covered.
    ///
    /// For ``Projection/epsg3857`` and ``Projection/epsg4978`` the geometries
    /// are projected to ``Projection/epsg4326`` first. Altitude differences
    /// are ignored.
    ///
    /// - Parameter other: The other geometry
    /// - Returns: `true` if the receiver is covered by the other geometry
    public func coveredBy(_ other: GeoJson) -> Bool {
        other.covers(self)
    }

}
