import Foundation

/// A point in 3D Cartesian space on the unit sphere.
public struct Cartesian3D {

    public let x: Double
    public let y: Double
    public let z: Double

    /// Create a Cartesian 3D point.
    ///
    /// - Parameters:
    ///    - x: The X coordinate
    ///    - y: The Y coordinate
    ///    - z: The Z coordinate
    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

}

// MARK: - Coordinate3D conversion

extension Cartesian3D {

    /// Convert a lat/lon coordinate (degrees) to a unit-sphere Cartesian point.
    ///
    /// - Parameters:
    ///    - coordinate: The geographic coordinate to convert
    public init(_ coordinate: Coordinate3D) {
        let lat = coordinate.latitude * .pi / 180.0
        let lon = coordinate.longitude * .pi / 180.0
        self.init(
            x: cos(lat) * cos(lon),
            y: cos(lat) * sin(lon),
            z: sin(lat))
    }

}

extension Coordinate3D {

    /// Create a coordinate from a unit-sphere Cartesian point.
    ///
    /// - Parameters:
    ///    - cartesian: The Cartesian point to convert
    public init(_ cartesian: Cartesian3D) {
        let lat = asin(cartesian.z) * 180.0 / .pi
        let lon = atan2(cartesian.y, cartesian.x) * 180.0 / .pi
        self.init(latitude: lat, longitude: lon)
    }

}
