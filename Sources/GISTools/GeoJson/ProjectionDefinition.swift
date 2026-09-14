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

    /// WKT fragment sets identifying this projection in a `.prj` file
    /// (e.g. `["PROJCS", "Pseudo-Mercator"]` for EPSG:3857).
    ///
    /// Each inner list is one alternative: a WKT string matches the
    /// definition when every fragment of at least one alternative is
    /// contained in the string. Definitions are probed in registry order
    /// and the first match wins, so the registry order is significant:
    /// more specific patterns must come before more generic ones (e.g.
    /// EPSG:3857's "Pseudo-Mercator" before EPSG:3395's "Mercator").
    var wktMatchers: [[String]] { get }

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

    /// The definitions in match order. More specific WKT patterns must
    /// come before more generic ones.
    private static let allDefinitions: [any ProjectionDefinition] = [
        epsg3857Definition,
        epsg3395Definition,
        epsg32662Definition,
        epsg4978Definition,
        epsg4326Definition,
        noSridDefinition,
    ]

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
        case .epsg3395: epsg3395Definition
        case .epsg32662: epsg32662Definition
        }
    }

    /// The first definition with a WKT alternative fully contained in the string.
    ///
    /// - Parameter wkt: A WKT projection string
    /// - Returns: The matching definition, or `nil` if the string is not recognised
    static func definition(matchingWkt wkt: String) -> (any ProjectionDefinition)? {
        allDefinitions.first { definition in
            definition.wktMatchers.contains { alternative in
                alternative.allSatisfy { wkt.contains($0) }
            }
        }
    }

    // MARK: - Definitions

    private static let noSridDefinition = NoSridDefinition()
    private static let epsg3857Definition = Epsg3857Definition()
    private static let epsg4326Definition = Epsg4326Definition()
    private static let epsg4978Definition = Epsg4978Definition()
    private static let epsg3395Definition = Epsg3395Definition()
    private static let epsg32662Definition = Epsg32662Definition()

}

// MARK: - EPSG:4326

/// Identity math for the EPSG:4326 pivot projection.
struct Epsg4326Definition: ProjectionDefinition {

    var projection: Projection { .epsg4326 }
    var kind: ProjectionKind { .geographic }

    var wktMatchers: [[String]] {
        [
            ["GEOGCS", "WGS 84"],
            ["GEOGCS", "WGS_1984"],
        ]
    }

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

    var wktMatchers: [[String]] {
        [
            ["PROJCS", "Pseudo-Mercator"],
        ]
    }

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

    var wktMatchers: [[String]] {
        [
            ["GEOCCS", "WGS 84"],
            ["GEOCCS", "WGS_1984"],
        ]
    }

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

// MARK: - EPSG:3395

/// Ellipsoidal Mercator math for EPSG:3395 (WGS 84 / World Mercator).
///
/// Unlike EPSG:3857 (spherical formulas on the WGS84 ellipsoid), EPSG:3395
/// uses the ellipsoidal Mercator formulas, so y values differ from
/// EPSG:3857 away from the equator.
struct Epsg3395Definition: ProjectionDefinition {

    /// The EPSG-registered projected bound of EPSG:3395 on the y axis
    /// (corresponding to roughly ±85° latitude; the y value diverges
    /// towards ±90°).
    private static let maxExtent = 20_048_966.104014604

    var projection: Projection { .epsg3395 }
    var kind: ProjectionKind { .planar }

    var wktMatchers: [[String]] {
        [
            ["PROJCS", "Mercator"],
        ]
    }

    var validExtent: (minX: Double, minY: Double, maxX: Double, maxY: Double)? {
        (minX: -GISTool.originShift, minY: -Self.maxExtent, maxX: GISTool.originShift, maxY: Self.maxExtent)
    }

    var worldBoundingBox: BoundingBox? {
        BoundingBox(
            southWest: Coordinate3D(x: -GISTool.originShift, y: -Self.maxExtent, projection: .epsg3395),
            northEast: Coordinate3D(x: GISTool.originShift, y: Self.maxExtent, projection: .epsg3395))
    }

    func forward(_ coordinate: Coordinate3D) -> Coordinate3D {
        let a = GISTool.equatorialRadius
        let e = sqrt(GISTool.wgs84EccentricitySquared)

        let x = coordinate.longitude * GISTool.originShift / 180.0

        let phi = coordinate.latitude * .pi / 180.0
        let sinPhi = sin(phi)
        let conformalLatitudeFactor = pow((1.0 - e * sinPhi) / (1.0 + e * sinPhi), e / 2.0)
        let y = a * log(tan(Double.pi / 4.0 + phi / 2.0) * conformalLatitudeFactor)

        return Coordinate3D(
            x: x,
            y: y,
            z: coordinate.altitude,
            m: coordinate.m,
            projection: .epsg3395)
    }

    func inverse(_ coordinate: Coordinate3D) -> Coordinate3D {
        let a = GISTool.equatorialRadius
        let e = sqrt(GISTool.wgs84EccentricitySquared)

        let longitude = (coordinate.longitude / GISTool.originShift) * 180.0

        // Iteratively solve the inverse ellipsoidal Mercator formula for
        // latitude (converges in a few iterations; 10 for safety).
        //
        // Forward: y = a * ln(tan(π/4 + φ/2) * c) with
        // c = ((1 - e·sinφ) / (1 + e·sinφ))^(e/2), so with t = exp(y/a):
        // tan(π/4 + φ/2) = t / c  →  φ = 2·atan(t / c) - π/2.
        let t = exp(coordinate.y / a)
        var phi = 2.0 * atan(t) - Double.pi / 2.0
        for _ in 0 ..< 10 {
            let sinPhi = sin(phi)
            let conformalLatitudeFactor = pow((1.0 - e * sinPhi) / (1.0 + e * sinPhi), e / 2.0)
            phi = 2.0 * atan(t / conformalLatitudeFactor) - Double.pi / 2.0
        }

        let latitude = phi * 180.0 / .pi

        return Coordinate3D(
            latitude: latitude,
            longitude: longitude,
            altitude: coordinate.altitude,
            m: coordinate.m)
    }

}

// MARK: - EPSG:32662

/// Plate Carrée (equirectangular) math for EPSG:32662 (WGS 84 / Plate Carree).
///
/// The simplest possible projection: longitude and latitude are used
/// directly as x and y in degrees. Distance and area calculations on
/// Plate Carrée coordinates are NOT metric despite the planar kind.
struct Epsg32662Definition: ProjectionDefinition {

    var projection: Projection { .epsg32662 }
    var kind: ProjectionKind { .planar }

    var wktMatchers: [[String]] {
        [
            ["PROJCS", "Plate Carree"],
        ]
    }

    var validExtent: (minX: Double, minY: Double, maxX: Double, maxY: Double)? {
        (minX: -180.0, minY: -90.0, maxX: 180.0, maxY: 90.0)
    }

    var worldBoundingBox: BoundingBox? {
        BoundingBox(
            southWest: Coordinate3D(x: -180.0, y: -90.0, projection: .epsg32662),
            northEast: Coordinate3D(x: 180.0, y: 90.0, projection: .epsg32662))
    }

    func forward(_ coordinate: Coordinate3D) -> Coordinate3D {
        Coordinate3D(
            x: coordinate.longitude,
            y: coordinate.latitude,
            z: coordinate.altitude,
            m: coordinate.m,
            projection: .epsg32662)
    }

    func inverse(_ coordinate: Coordinate3D) -> Coordinate3D {
        Coordinate3D(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            altitude: coordinate.altitude,
            m: coordinate.m)
    }

}

// MARK: - No SRID

/// Null math for coordinates without an SRID.
///
/// Coordinates without an SRID carry no CRS information, so no transformation
/// math applies to them: ``Coordinate3D/projected(to:)`` copies their values
/// verbatim for every target projection and this definition is never reached
/// through the pivot. Its conversions exist only for completeness and copy
/// values verbatim as well.
struct NoSridDefinition: ProjectionDefinition {

    var projection: Projection { .noSRID }
    var kind: ProjectionKind { .undefined }

    var wktMatchers: [[String]] {
        []
    }

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
        // Verbatim copy; noSRID values are never transformed.
        Coordinate3D(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            altitude: coordinate.altitude,
            m: coordinate.m)
    }

}
