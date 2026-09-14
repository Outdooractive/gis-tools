import Foundation

/// Internal strategy providing the transform math for a single projection.
///
/// All conversions are expressed relative to the EPSG:4326 pivot:
/// ``forward(_:)`` maps geographic coordinates into the receiver's
/// projection, ``inverse(_:)`` maps back. Any projection pair is routed
/// through that pivot (source → EPSG:4326 → target).
protocol ProjectionDefinition: Sendable {

    /// The projection the receiver provides math for.
    var projection: Projection { get }

    /// The semantic category of the projection.
    var kind: ProjectionKind { get }

    /// The valid coordinate extent of the projection, or `nil` if the
    /// coordinate space is unbounded (e.g. geocentric or no SRID).
    var validExtent: (minX: Double, minY: Double, maxX: Double, maxY: Double)? { get }

    /// A bounding box spanning the whole world in this projection,
    /// or `nil` if no meaningful world extent exists.
    var worldBoundingBox: BoundingBox? { get }

    /// Converts a coordinate from EPSG:4326 into the receiver's projection.
    ///
    /// - Parameter coordinate: A coordinate in EPSG:4326
    /// - Returns: The coordinate in the receiver's projection
    func forward(_ coordinate: Coordinate3D) -> Coordinate3D

    /// Converts a coordinate from the receiver's projection into EPSG:4326.
    ///
    /// - Parameter coordinate: A coordinate in the receiver's projection
    /// - Returns: The coordinate in EPSG:4326
    func inverse(_ coordinate: Coordinate3D) -> Coordinate3D

}

/// Registry providing the ``ProjectionDefinition`` for each ``Projection``.
enum ProjectionRegistry {

    // MARK: - Lookup

    /// The definition implementing the math for a projection.
    ///
    /// - Parameter projection: The projection to look up
    /// - Returns: The definition for the projection
    static func definition(for projection: Projection) -> any ProjectionDefinition {
        switch projection {
        case .noSRID: noSridDefinition
        case .epsg3857: epsg3857Definition
        case .epsg4326: epsg4326Definition
        case .epsg4978: epsg4978Definition
        }
    }

    // MARK: - Definitions

    private static let noSridDefinition = NoSridDefinition()
    private static let epsg3857Definition = Epsg3857Definition()
    private static let epsg4326Definition = Epsg4326Definition()
    private static let epsg4978Definition = Epsg4978Definition()

}

// MARK: - EPSG:4326

/// Identity math for the EPSG:4326 pivot projection.
struct Epsg4326Definition: ProjectionDefinition {

    var projection: Projection { .epsg4326 }
    var kind: ProjectionKind { .geographic }

    var validExtent: (minX: Double, minY: Double, maxX: Double, maxY: Double)? {
        (minX: -180.0, minY: -90.0, maxX: 180.0, maxY: 90.0)
    }

    var worldBoundingBox: BoundingBox? {
        BoundingBox.world
    }

    func forward(_ coordinate: Coordinate3D) -> Coordinate3D {
        Coordinate3D(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            altitude: coordinate.altitude,
            m: coordinate.m)
    }

    func inverse(_ coordinate: Coordinate3D) -> Coordinate3D {
        forward(coordinate)
    }

}

// MARK: - EPSG:3857

/// Web Mercator math for EPSG:3857.
struct Epsg3857Definition: ProjectionDefinition {

    var projection: Projection { .epsg3857 }
    var kind: ProjectionKind { .planar }

    var validExtent: (minX: Double, minY: Double, maxX: Double, maxY: Double)? {
        (minX: -GISTool.originShift, minY: -GISTool.originShift, maxX: GISTool.originShift, maxY: GISTool.originShift)
    }

    var worldBoundingBox: BoundingBox? {
        let shift = GISTool.originShift
        return BoundingBox(
            southWest: Coordinate3D(x: -shift, y: -shift, projection: .epsg3857),
            northEast: Coordinate3D(x: shift, y: shift, projection: .epsg3857))
    }

    func forward(_ coordinate: Coordinate3D) -> Coordinate3D {
        let x = coordinate.longitude * GISTool.originShift / 180.0
        var y: Double = log(tan((90.0 + coordinate.latitude) * Double.pi / 360.0)) / (Double.pi / 180.0)
        y *= GISTool.originShift / 180.0

        return Coordinate3D(
            x: x,
            y: y,
            z: coordinate.altitude,
            m: coordinate.m,
            projection: .epsg3857)
    }

    func inverse(_ coordinate: Coordinate3D) -> Coordinate3D {
        let longitude = (coordinate.longitude / GISTool.originShift) * 180.0
        let expArgument = (coordinate.latitude / GISTool.originShift) * 180.0 * Double.pi / 180.0
        let latitude = 180.0 / Double.pi * ((2.0 * atan(exp(expArgument))) - (Double.pi / 2.0))

        return Coordinate3D(
            latitude: latitude,
            longitude: longitude,
            altitude: coordinate.altitude,
            m: coordinate.m)
    }

}

// MARK: - EPSG:4978

/// Geocentric (ECEF) math for EPSG:4978.
struct Epsg4978Definition: ProjectionDefinition {

    var projection: Projection { .epsg4978 }
    var kind: ProjectionKind { .geocentric }

    /// Geocentric coordinates are unbounded.
    var validExtent: (minX: Double, minY: Double, maxX: Double, maxY: Double)? {
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

// MARK: - No SRID

/// Null math for coordinates without an SRID.
///
/// Coordinates without an SRID are *interpreted* as EPSG:4326 when
/// transformed through the pivot (e.g. into EPSG:4978). Verbatim-copy
/// semantics for EPSG:4326/EPSG:3857 targets are handled directly in
/// ``Coordinate3D/projected(to:)`` and never reach this definition.
struct NoSridDefinition: ProjectionDefinition {

    var projection: Projection { .noSRID }
    var kind: ProjectionKind { .undefined }

    /// Coordinates without an SRID have no defined extent.
    var validExtent: (minX: Double, minY: Double, maxX: Double, maxY: Double)? {
        nil
    }

    var worldBoundingBox: BoundingBox? {
        BoundingBox(
            southWest: Coordinate3D(x: -180.0, y: -90.0, projection: .noSRID),
            northEast: Coordinate3D(x: 180.0, y: 90.0, projection: .noSRID))
    }

    func forward(_ coordinate: Coordinate3D) -> Coordinate3D {
        Coordinate3D(
            x: coordinate.longitude,
            y: coordinate.latitude,
            z: coordinate.altitude,
            m: coordinate.m,
            projection: .noSRID)
    }

    func inverse(_ coordinate: Coordinate3D) -> Coordinate3D {
        // Coordinates without an SRID are interpreted as EPSG:4326.
        Coordinate3D(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            altitude: coordinate.altitude,
            m: coordinate.m)
    }

}
