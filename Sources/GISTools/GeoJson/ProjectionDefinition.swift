import Foundation
import Synchronization

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

    /// The geodetic datum of the projection's coordinate frame.
    var datum: Datum { get }

    /// The valid coordinate extent of the projection, or `nil` if the
    /// coordinate space is unbounded (e.g. geocentric or no SRID).
    var validExtent: ProjectionExtent? { get }

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

    /// The absolute value beyond which the horizontal axis of the
    /// projection wraps around (e.g. ±180° for geographic coordinates),
    /// or `nil` if it does not wrap.
    var wraparoundExtent: Double? { get }

    /// Converts a coordinate from the receiver's projection into EPSG:4326.
    ///
    /// - Parameter coordinate: A coordinate in the receiver's projection
    /// - Returns: The coordinate in EPSG:4326
    func inverse(_ coordinate: Coordinate3D) -> Coordinate3D

}

extension ProjectionDefinition {

    /// The geodetic datum of the projection's coordinate frame.
    ///
    /// Default is ``Datum/wgs84``; datum-capable projections override this.
    var datum: Datum {
        .wgs84
    }

}

/// Registry providing ``ProjectionDefinition`` implementations for
/// registered projections.
///
/// The registry is **add-only**: the built-in projections are seeded once
/// and custom definitions can be added through ``Projection/register(_:)`` —
/// nothing can be removed or replaced afterwards. Lookups take a consistent
/// snapshot; the internal `Mutex` makes a completed registration visible to
/// all subsequent readers.
enum ProjectionRegistry {

    // MARK: - Definitions

    private static let noSridDefinition = NoSridDefinition()
    private static let epsg3857Definition = Epsg3857Definition()
    private static let epsg4326Definition = Epsg4326Definition()
    private static let epsg4978Definition = Epsg4978Definition()
    private static let epsg3395Definition = Epsg3395Definition()
    private static let epsg32662Definition = Epsg32662Definition()
    private static let nad27Definition = Nad27Definition()
    private static let etrs89Definition = Etrs89Definition()
    private static let osgb1936Definition = Osgb1936Definition()
    private static let osgb1936BngDefinition = Osgb1936BngDefinition()

    /// All built-in definitions: the 6 base definitions and all UTM zones,
    /// keyed by canonical SRID.
    ///
    /// `UtmTests` sweeps every UTM SRID and asserts that lookups resolve to
    /// definitions whose ``ProjectionDefinition/projection`` matches.
    private static let builtinDefinitions: [Int: any ProjectionDefinition] = {
        var map: [Int: any ProjectionDefinition] = [
            0: noSridDefinition,
            3857: epsg3857Definition,
            4326: epsg4326Definition,
            4978: epsg4978Definition,
            3395: epsg3395Definition,
            32_662: epsg32662Definition,
            4258: etrs89Definition,
            4267: nad27Definition,
            4277: osgb1936Definition,
            27700: osgb1936BngDefinition,
        ]

        for srid in 32_601 ... 32_660 {
            map[srid] = UtmDefinition.definition(forSrid: srid)
        }
        for srid in 32_701 ... 32_760 {
            map[srid] = UtmDefinition.definition(forSrid: srid)
        }

        return map
    }()

    /// The mutable registry state guarded by the mutex.
    private struct State {
        /// Definitions keyed by canonical SRID.
        var definitions: [Int: any ProjectionDefinition]

        /// WKT probes in match order: the ordered built-in list first
        /// (specific patterns before generic ones), custom registrations
        /// last.
        var wktDefinitions: [any ProjectionDefinition]
    }

    private static let builtinWktDefinitions: [any ProjectionDefinition] = [
        epsg3857Definition,
        osgb1936BngDefinition,
        epsg3395Definition,
        epsg32662Definition,
        etrs89Definition,
        nad27Definition,
        osgb1936Definition,
        epsg4978Definition,
        epsg4326Definition,
    ]

    private static let state = State(
        definitions: builtinDefinitions,
        wktDefinitions: builtinWktDefinitions)

    private static let stateMutex = Mutex<State>(state)

    // MARK: - Lookup

    /// The registered definition for a canonical SRID.
    ///
    /// - Parameter srid: A canonical SRID (aliases are resolved by ``Projection``)
    /// - Returns: The definition, or `nil` if the SRID is not registered
    static func definition(forSrid srid: Int) -> (any ProjectionDefinition)? {
        stateMutex.withLock { snapshot in
            snapshot.definitions[srid]
        }
    }

    /// Whether a canonical SRID has a registered definition.
    static func isRegisteredSrid(_ srid: Int) -> Bool {
        stateMutex.withLock { snapshot in
            snapshot.definitions[srid] != nil
        }
    }

    /// The first definition with a WKT alternative fully contained in the string.
    ///
    /// - Parameter wkt: A WKT projection string
    /// - Returns: The matching definition, or `nil` if the string is not recognised
    static func definition(matchingWkt wkt: String) -> (any ProjectionDefinition)? {
        stateMutex.withLock { snapshot in
            snapshot.wktDefinitions.first { definition in
                definition.wktMatchers.contains { alternative in
                    alternative.allSatisfy { wkt.contains($0) }
                }
            }
        }
    }

    // MARK: - Registration

    /// Registers a custom definition. Add-only: entries are never removed
    /// or replaced.
    ///
    /// Rejected when the SRID is `<= 0` or already registered; the state
    /// stays unchanged in that case.
    ///
    /// - Parameter definition: The custom projection to register
    /// - Returns: `true` when the registration succeeded
    static func register(_ definition: CustomProjection) -> Bool {
        guard definition.srid > 0 else { return false }

        return stateMutex.withLock { state in
            guard state.definitions[definition.srid] == nil else { return false }

            let registered = RegisteredCustomDefinition(custom: definition)
            var definitions = state.definitions
            definitions[definition.srid] = registered

            var wktDefinitions = state.wktDefinitions
            if definition.wktMatchers.isNotEmpty {
                wktDefinitions.append(registered)
            }

            state = State(definitions: definitions, wktDefinitions: wktDefinitions)
            return true
        }
    }

}

// MARK: - EPSG:4326

/// Identity math for the EPSG:4326 pivot projection.
struct Epsg4326Definition: ProjectionDefinition {

    var projection: Projection { Projection(uncheckedSrid: 4326, definition: self) }
    var kind: ProjectionKind { .geographic }

    var wraparoundExtent: Double? { 180.0 }
    var wktMatchers: [[String]] {
        [
            ["GEOGCS", "WGS 84"],
            ["GEOGCS", "WGS_1984"],
        ]
    }

    var validExtent: ProjectionExtent? {
        ProjectionExtent(minX: -180.0, minY: -90.0, maxX: 180.0, maxY: 90.0)
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

    var projection: Projection { Projection(uncheckedSrid: 3857, definition: self) }
    var kind: ProjectionKind { .planar }

    var wraparoundExtent: Double? { GISTool.originShift }
    var wktMatchers: [[String]] {
        [
            ["PROJCS", "Pseudo-Mercator"],
        ]
    }

    var validExtent: ProjectionExtent? {
        ProjectionExtent(
            minX: -GISTool.originShift,
            minY: -GISTool.originShift,
            maxX: GISTool.originShift,
            maxY: GISTool.originShift)
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

    var projection: Projection { Projection(uncheckedSrid: 3395, definition: self) }
    var kind: ProjectionKind { .planar }

    var wraparoundExtent: Double? { GISTool.originShift }
    var wktMatchers: [[String]] {
        [
            ["PROJCS", "Mercator"],
        ]
    }

    var validExtent: ProjectionExtent? {
        ProjectionExtent(
            minX: -GISTool.originShift,
            minY: -Self.maxExtent,
            maxX: GISTool.originShift,
            maxY: Self.maxExtent)
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

    var projection: Projection { Projection(uncheckedSrid: 32_662, definition: self) }
    var kind: ProjectionKind { .planar }

    var wraparoundExtent: Double? { 180.0 }
    var wktMatchers: [[String]] {
        [
            ["PROJCS", "Plate Carree"],
        ]
    }

    var validExtent: ProjectionExtent? {
        ProjectionExtent(minX: -180.0, minY: -90.0, maxX: 180.0, maxY: 90.0)
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

    var projection: Projection { Projection(uncheckedSrid: 0, definition: self) }
    var kind: ProjectionKind { .undefined }

    var wraparoundExtent: Double? { nil }
    var wktMatchers: [[String]] {
        []
    }

    /// Coordinates without an SRID have no defined extent.
    var validExtent: ProjectionExtent? {
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
