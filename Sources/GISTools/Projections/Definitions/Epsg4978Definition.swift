import Foundation

// MARK: - EPSG:4978

/// Geocentric (ECEF) math for EPSG:4978.
struct Epsg4978Definition: ProjectionDefinition {

    var projection: Projection { Projection(uncheckedSrid: 4978, definition: self) }
    var kind: ProjectionKind { .geocentric }

    var wraparoundExtent: Double? { nil }
    var wktMatchers: [[String]] {
        [
            ["GEOCCS", "WGS 84"],
            ["GEOCCS", "WGS_1984"],
        ]
    }

    /// Geocentric coordinates are unbounded.
    var validExtent: ProjectionExtent? {
        nil
    }

    var worldBoundingBox: BoundingBox? {
        let radius = GISTool.equatorialRadius
        return BoundingBox(
            southWest: Coordinate3D(x: -radius, y: -radius, z: -radius, projection: .epsg4978),
            northEast: Coordinate3D(x: radius, y: radius, z: radius, projection: .epsg4978))
    }

    func forward(_ coordinate: Coordinate3D) -> Coordinate3D {
        let (x, y, z) = Self.geodeticToEcef(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            altitude: coordinate.altitude ?? 0.0)

        return Coordinate3D(x: x, y: y, z: z, m: coordinate.m, projection: .epsg4978)
    }

    func inverse(_ coordinate: Coordinate3D) -> Coordinate3D {
        let (latitude, longitude, altitude) = Self.ecefToGeodetic(
            x: coordinate.longitude,
            y: coordinate.latitude,
            z: coordinate.altitude ?? 0.0)

        return Coordinate3D(latitude: latitude, longitude: longitude, altitude: altitude, m: coordinate.m)
    }

    // MARK: Private helpers

    /// Convert geodetic (EPSG:4326) to geocentric (EPSG:4978) coordinates.
    ///
    /// Uses the WGS84 ellipsoid: a = 6,378,137 m, 1/f = 298.257223563.
    ///
    /// - Parameters:
    ///   - latitude: Latitude in degrees
    ///   - longitude: Longitude in degrees
    ///   - altitude: Height above ellipsoid in meters
    /// - Returns: ECEF X, Y, Z in meters
    private static func geodeticToEcef(
        latitude: Double,
        longitude: Double,
        altitude: Double
    ) -> (x: Double, y: Double, z: Double) {
        let a = GISTool.equatorialRadius
        let e2 = GISTool.wgs84EccentricitySquared

        let phi = latitude * .pi / 180.0
        let lambda = longitude * .pi / 180.0
        let h = altitude

        let sinPhi = sin(phi)
        let N = a / sqrt(1.0 - e2 * sinPhi * sinPhi)

        let x = (N + h) * cos(phi) * cos(lambda)
        let y = (N + h) * cos(phi) * sin(lambda)
        let z = ((1.0 - e2) * N + h) * sinPhi

        return (x, y, z)
    }

    /// Convert geocentric (EPSG:4978) to geodetic (EPSG:4326) coordinates.
    ///
    /// Uses the iterative Bowring method (typically converges in ~3 iterations).
    ///
    /// - Parameters:
    ///   - x: ECEF X in meters
    ///   - y: ECEF Y in meters
    ///   - z: ECEF Z in meters
    /// - Returns: Latitude (degrees), longitude (degrees), altitude (meters)
    private static func ecefToGeodetic(
        x: Double,
        y: Double,
        z: Double
    ) -> (latitude: Double, longitude: Double, altitude: Double) {
        let a = GISTool.equatorialRadius
        let e2 = GISTool.wgs84EccentricitySquared

        let p = sqrt(x * x + y * y)

        guard p > GISTool.intersectionEpsilon else {
            let lat = z >= 0.0 ? 90.0 : -90.0
            let h = abs(z) - a * (1.0 - e2)
            return (lat, 0.0, h)
        }

        var phi = atan2(z, p * (1.0 - e2))
        var h: Double = 0.0
        for _ in 0 ..< 10 {
            let sinPhi = sin(phi)
            let cosPhi = cos(phi)
            let N = a / sqrt(1.0 - e2 * sinPhi * sinPhi)
            h = p / cosPhi - N
            phi = atan2(z * (N + h), p * ((1.0 - e2) * N + h))
        }

        // Clamp latitude to the valid geodetic range. The iterative solver
        // can diverge for points near the geocenter (huge negative altitude),
        // producing |lat| > 90.
        let lat = Swift.min(90.0, Swift.max(-90.0, phi * 180.0 / .pi))
        let lon = atan2(y, x) * 180.0 / .pi

        return (lat, lon, h)
    }

}
