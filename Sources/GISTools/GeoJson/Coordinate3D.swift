#if canImport(CoreLocation)
import CoreLocation
#else
public typealias CLLocationDirection = Double
public typealias CLLocationDistance = Double
public typealias CLLocationDegrees = Double
#endif
import Foundation

// MARK: -

/// A three dimensional coordinate (``latitude``/``y``, ``longitude``/``x``, ``altitude``/``z``)
/// plus a generic value ``m``.
public struct Coordinate3D:
    CustomStringConvertible,
    Sendable
{

    /// A coordinate at (0.0, 0.0) aka Null Island.
    public static var zero: Coordinate3D {
        Coordinate3D(latitude: 0.0, longitude: 0.0)
    }

    /// The coordinates projection.
    public let projection: Projection

    /// The coordinate's `latitude` or `northing`, depending on the projection.
    public var latitude: CLLocationDegrees
    /// The coordinate's `longitude` or `easting`, depending on the projection.
    public var longitude: CLLocationDegrees
    /// The coordinate's `altitude`, in meters.
    public var altitude: CLLocationDistance?

    /// Linear referencing, timestamp or whatever you want it to use for.
    ///
    /// The GeoJSON specification doesn't specifiy the meaning of this value,
    /// and it doesn't guarantee that parsers won't ignore or discard it. See
    /// [chapter 3.1.1 in the spec](https://datatracker.ietf.org/doc/html/rfc7946#section-3.1.1).
    /// - Important: ``asJson`` will output a `null` altitude value if ``altitude`` is `nil` so that
    ///              `m` won't get lost. This might lead to compatibilty issues with other GeoJSON readers.
    public var m: Double?

    /// Alias for longitude
    @inlinable
    public var x: Double { longitude }

    /// Alias for latitude
    @inlinable
    public var y: Double { latitude }

    /// Alias for altitude
    @inlinable
    public var z: Double? { altitude }

    /// Create a coordinate with ``latitude``, ``longitude``, ``altitude`` and ``m``.
    /// Projection will be *EPSG:4326*.
    ///
    /// - Parameters:
    ///    - latitude: The latitude (or northing)
    ///    - longitude: The longitude (or easting)
    ///    - altitude: The altitude in meters (optional)
    ///    - m: A generic value (optional)
    public init(
        latitude: CLLocationDegrees,
        longitude: CLLocationDegrees,
        altitude: CLLocationDistance? = nil,
        m: Double? = nil
    ) {
        self.projection = .epsg4326
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.m = m
    }

    /// Create a coordinate with ``x``, ``y``, ``z`` and ``m``.
    /// Default projection will we *EPSG:3857* but can be overridden.
    ///
    /// - Parameters:
    ///    - x: The easting (or longitude)
    ///    - y: The northing (or latitude)
    ///    - z: The altitude in meters (optional)
    ///    - m: A generic value (optional)
    ///    - projection: The coordinate projection (default `.epsg3857`)
    public init(
        x: Double,
        y: Double,
        z: Double? = nil,
        m: Double? = nil,
        projection: Projection = .epsg3857
    ) {
        self.projection = projection
        self.longitude = x
        self.latitude = y
        self.altitude = z
        self.m = m
    }

    /// A boolean value indicating if this coordinate is (0.0, 0.0) aka Null Island.
    public var isZero: Bool {
        latitude == 0.0 && longitude == 0.0
    }

    /// A textual representation of the coordinate.
    public var description: String {
        var components: [String] = []
        if projection == .epsg4326 {
            components.append(contentsOf: [
                "latitude: \(latitude)",
                "longitude: \(longitude)",
            ])
        }
        else {
            components.append(contentsOf: [
                "x: \(longitude)",
                "y: \(latitude)",
            ])
        }
        if let altitude {
            components.append("\(projection == .epsg4326 ? "altitude" : "z"): \(altitude)")
        }
        if let m {
            components.append("m: \(m)")
        }
        return "Coordinate3D<\(projection.description)>(\(components.joined(separator: ", ")))"
    }

}

// MARK: - DMS (Degrees, Minutes, Seconds)

extension Coordinate3D {

    /// Creates a coordinate from a DMS string.
    ///
    /// Supported formats:
    /// - `"40°26'46\" N 79°58'56\" W"`
    /// - `"40 26 46 N 79 58 56 W"`
    /// - `"40°26.767' N 79°58.933' W"`
    ///
    /// - Parameters:
    ///    - dms: A DMS-formatted coordinate string
    /// - Returns: A coordinate, or `nil` if parsing fails
    public init?(dms: String) {
        let cleaned = dms
            .replacingOccurrences(of: "\u{2032}", with: "'")  // prime
            .replacingOccurrences(of: "\u{2033}", with: "\"") // double prime
            .replacingOccurrences(of: "\u{00B0}", with: "°")  // degree
        let pattern = #"(\d{1,3})[°\s]+(\d{1,2})[′'\s]+([\d.]+)["\s]*\s*([NSEWnsew])\s+(\d{1,3})[°\s]+(\d{1,2})[′'\s]+([\d.]+)["\s]*\s*([NSEWnsew])"#

        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)),
              match.numberOfRanges == 9
        else { return nil }

        let ns = cleaned as NSString
        func val(_ i: Int) -> Double? { Double(ns.substring(with: match.range(at: i))) }
        func dir(_ i: Int) -> String { ns.substring(with: match.range(at: i)).uppercased() }

        guard let d1 = val(1), let m1 = val(2), let s1 = val(3),
              let d2 = val(5), let m2 = val(6), let s2 = val(7)
        else { return nil }

        let dir1 = dir(4)
        let dir2 = dir(8)

        let latitude = (dir1 == "N" ? 1.0 : -1.0) * (d1 + m1 / 60.0 + s1 / 3600.0)
        let longitude = (dir2 == "E" ? 1.0 : -1.0) * (d2 + m2 / 60.0 + s2 / 3600.0)

        self.init(latitude: latitude, longitude: longitude)
    }

    /// Creates a coordinate from separate DMS components.
    ///
    /// - Parameters:
    ///    - latitudeDegrees: Degrees of latitude
    ///    - latitudeMinutes: Minutes of latitude
    ///    - latitudeSeconds: Seconds of latitude
    ///    - latitudeDirection: `"N"` or `"S"`
    ///    - longitudeDegrees: Degrees of longitude
    ///    - longitudeMinutes: Minutes of longitude
    ///    - longitudeSeconds: Seconds of longitude
    ///    - longitudeDirection: `"E"` or `"W"`
    /// - Returns: A coordinate, or `nil` if direction is invalid
    public init?(
        latitudeDegrees: Double,
        latitudeMinutes: Double,
        latitudeSeconds: Double,
        latitudeDirection: String,
        longitudeDegrees: Double,
        longitudeMinutes: Double,
        longitudeSeconds: Double,
        longitudeDirection: String
    ) {
        guard latitudeDirection.uppercased().isIn(["N", "S"]),
              longitudeDirection.uppercased().isIn(["E", "W"])
        else { return nil }

        let latitude = (latitudeDirection.uppercased() == "N" ? 1.0 : -1.0)
            * (latitudeDegrees + latitudeMinutes / 60.0 + latitudeSeconds / 3600.0)
        let longitude = (longitudeDirection.uppercased() == "E" ? 1.0 : -1.0)
            * (longitudeDegrees + longitudeMinutes / 60.0 + longitudeSeconds / 3600.0)
        self.init(latitude: latitude, longitude: longitude)
    }

}

// MARK: - UTM (Universal Transverse Mercator)

extension Coordinate3D {

    /// Creates a coordinate from UTM zone, easting, northing, and hemisphere.
    ///
    /// - Parameters:
    ///   - easting: Easting in meters.
    ///   - northing: Northing in meters.
    ///   - zone: UTM zone number (1-60).
    ///   - hemisphere: "N" for northern, "S" for southern.
    public init?(
        easting: Double,
        northing: Double,
        zone: Int,
        hemisphere: String
    ) {
        guard zone >= 1,
              zone <= 60,
              hemisphere.uppercased().isIn(["N", "S"])
        else { return nil }

        let isNorth = hemisphere.uppercased() == "N"

        // WGS84 ellipsoid constants
        let a = GISTool.equatorialRadius
        let e2 = GISTool.wgs84EccentricitySquared
        let e1sq = e2 / (1.0 - e2)
        let k0: Double = 0.9996

        let falseEasting: Double = 500_000.0
        let falseNorthing: Double = isNorth ? 0.0 : 10_000_000.0

        let x = easting - falseEasting
        let y = northing - falseNorthing

        let M = y / k0
        let mu = M / (a * (1.0 - e2 / 4.0 - 3.0 * e2 * e2 / 64.0 - 5.0 * pow(e2, 3) / 256.0))

        let e1 = (1.0 - sqrt(1.0 - e2)) / (1.0 + sqrt(1.0 - e2))

        let phi1 = mu
            + (3.0 * e1 / 2.0 - 27.0 * pow(e1, 3) / 32.0) * sin(2.0 * mu)
            + (21.0 * e1 * e1 / 16.0 - 55.0 * pow(e1, 4) / 32.0) * sin(4.0 * mu)
            + (151.0 * pow(e1, 3) / 96.0) * sin(6.0 * mu)
            + (1097.0 * pow(e1, 4) / 512.0) * sin(8.0 * mu)

        let N1 = a / sqrt(1.0 - e2 * sin(phi1) * sin(phi1))
        let T1 = tan(phi1) * tan(phi1)
        let C1 = e1sq * cos(phi1) * cos(phi1)
        let R1 = a * (1.0 - e2) / pow(1.0 - e2 * sin(phi1) * sin(phi1), 1.5)
        let D = x / (N1 * k0)

        let lat1 = N1 * tan(phi1) / R1
        let lat2 = lat1 * (D * D / 2.0
                           - (5.0 + 3.0 * T1 + 10.0 * C1 - 4.0 * C1 * C1 - 9.0 * e1sq) * pow(D, 4) / 24.0
                           + (61.0 + 90.0 * T1 + 298.0 * C1 + 45.0 * T1 * T1 - 252.0 * e1sq - 3.0 * C1 * C1) * pow(D, 6) / 720.0)
        let latitude = phi1 - lat2

        let lon0 = Double((zone - 1) * 6 - 180 + 3) * .pi / 180.0
        let lon1 = (D - (1.0 + 2.0 * T1 + C1) * pow(D, 3) / 6.0
                    + (5.0 - 2.0 * C1 + 28.0 * T1 - 3.0 * C1 * C1 + 8.0 * e1sq + 24.0 * T1 * T1) * pow(D, 5) / 120.0) / cos(phi1)
        let longitude = lon0 + lon1

        self.init(latitude: latitude * 180.0 / .pi,
                  longitude: longitude * 180.0 / .pi)
    }

}

// MARK: - CoreLocation compatibility

#if canImport(CoreLocation)
extension Coordinate3D {

    /// Create a `Coordinate3D` from a `CLLocationCoordinate2D`.
    ///
    /// - Parameters:
    ///    - coordinate: The Core Location coordinate
    ///    - altitude: The altitude in meters (optional)
    public init(
        _ coordinate: CLLocationCoordinate2D,
        altitude: CLLocationDistance? = nil
    ) {
        self.projection = .epsg4326
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.altitude = altitude
        self.m = nil
    }

    /// This coordinate as `CLLocationCoordinate2D`.
    ///
    /// - Returns: A `CLLocationCoordinate2D` projected to EPSG:4326
    public var coordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: latitudeProjected(to: .epsg4326),
            longitude: longitudeProjected(to: .epsg4326))
    }

    /// Create a `Coordinate3D` from a `CLLocation`.
    ///
    /// This will set ``m`` to the location's timestamp using `timeIntervalSinceReferenceDate`.
    ///
    /// - Parameters:
    ///    - location: The Core Location object
    public init(_ location: CLLocation) {
        self.projection = .epsg4326
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.altitude = (location.verticalAccuracy > 0.0 ? location.altitude : nil)
        self.m = location.timestamp.timeIntervalSinceReferenceDate
    }

    /// This coordinate as `CLLocation`.
    ///
    /// - Important: This will set the location's timestamp using ``m``
    ///              if it exists, using `Date(timeIntervalSinceReferenceDate:)`.
    ///              See also ``init(_:)`` and ``asJson``.
    /// - Returns: A `CLLocation` representing this coordinate
    public var location: CLLocation {
        let timestamp = (m != nil
            ? Date(timeIntervalSinceReferenceDate: m!)
            : Date())

        return CLLocation(
            coordinate: coordinate2D,
            altitude: altitude ?? -1.0,
            horizontalAccuracy: 1.0, // always valid
            verticalAccuracy: altitude == nil ? -1.0 : 1.0, // valid if altitude != nil
            timestamp: timestamp)
    }

}

extension CLLocation {

    /// The receiver as a ``Coordinate3D``.
    ///
    /// - Returns: A `Coordinate3D` representing this location
    public var coordinate3D: Coordinate3D {
        Coordinate3D(self)
    }

}

extension CLLocationCoordinate2D {

    /// The receiver as a ``Coordinate3D``.
    ///
    /// - Returns: A `Coordinate3D` representing this coordinate
    public var coordinate3D: Coordinate3D {
        Coordinate3D(self)
    }

}
#endif

// MARK: - Helpers

extension Coordinate3D {

    /// `true` when the receiver is equal to `other` within
    /// the global equality delta.
    ///
    /// - Parameter other: The other coordinate
    /// - Returns: `true` if coincident, `false` otherwise
    public func isCoincident(to other: Coordinate3D?) -> Bool {
        guard let other else { return false }
        return self.equals(other: other, includingAltitude: false)
    }

    /// Normalize this coordinate in place (no-op for Cartesian projections).
    public mutating func normalize() {
        self = self.normalized()
    }

    /// Normalize this coordinate.
    ///
    /// For EPSG:4326 and EPSG:3857, clamps the longitude to the valid range.
    /// For EPSG:4978 (ECEF) this is a no-op.
    ///
    /// - Returns: A copy with longitude normalized to the valid range
    public func normalized() -> Coordinate3D {
        switch projection {
        case .epsg3857:
            guard longitude < -GISTool.originShift
                    || longitude > GISTool.originShift
            else { return self }

            var longitude = self.longitude
            while longitude < -GISTool.originShift { longitude += (2.0 * GISTool.originShift) }
            while longitude > GISTool.originShift { longitude -= (2.0 * GISTool.originShift) }

            return Coordinate3D(x: longitude, y: latitude, z: altitude, m: m)

        case .epsg4326:
            guard longitude < -180.0
                    || longitude > 180.0
            else { return self }

            var longitude = self.longitude
            while longitude < -180.0 { longitude += 360.0 }
            while longitude > 180.0 { longitude -= 360.0 }

            return Coordinate3D(latitude: latitude, longitude: longitude, altitude: altitude, m: m)

        default:
            return self
        }
    }

    /// Clamped to [[-180,-90], [180,90]]  (no-op for Cartesian projections).
    public mutating func clamp() {
        self = self.clamped()
    }

    /// Clamped to [[-180,-90], [180,90]].
    ///
    /// For EPSG:4326 and EPSG:3857, clamps the longitude to the valid range.
    /// For EPSG:4978 (ECEF) this is a no-op.
    ///
    /// - Returns: A copy clamped to the valid coordinate range
    public func clamped() -> Coordinate3D {
        switch projection {
        case .epsg3857:
            guard longitude < -GISTool.originShift || longitude > GISTool.originShift
                || latitude < -GISTool.originShift || latitude > GISTool.originShift
            else { return self }

            return Coordinate3D(
                x: min(GISTool.originShift, max(-GISTool.originShift, longitude)),
                y: min(GISTool.originShift, max(-GISTool.originShift, latitude)),
                z: altitude,
                m: m)

        case .epsg4326:
            guard longitude < -180.0 || longitude > 180.0
                || latitude < -90.0 || latitude > 90.0
            else { return self }

            return Coordinate3D(
                latitude: min(90.0, max(-90.0, latitude)),
                longitude: min(180.0, max(-180.0, longitude)),
                altitude: altitude,
                m: m)

        default:
            return self
        }
    }

}

// MARK: - Projection

extension Coordinate3D: Projectable {

    /// Reproject this coordinate.
    ///
    /// - Parameters:
    ///    - newProjection: The target projection
    /// - Returns: A new coordinate in the requested projection
    public func projected(to newProjection: Projection) -> Coordinate3D {
        guard newProjection != projection else { return self }

        switch newProjection {
        case .epsg3857:
            switch projection {
            case .epsg3857:
                return self
            case .epsg4326, .noSRID:
                return Coordinate3D(
                    x: longitudeProjected(to: newProjection),
                    y: latitudeProjected(to: newProjection),
                    z: altitude,
                    m: m,
                    projection: newProjection)
            case .epsg4978:
                return projected(to: .epsg4326).projected(to: .epsg3857)
            }

        case .epsg4326:
            switch projection {
            case .epsg4326:
                return self
            case .epsg3857, .noSRID:
                return Coordinate3D(
                    x: longitudeProjected(to: newProjection),
                    y: latitudeProjected(to: newProjection),
                    z: altitude,
                    m: m,
                    projection: newProjection)
            case .epsg4978:
                let (lat, lon, alt) = Coordinate3D.ecefToGeodetic(
                    x: longitude, y: latitude, z: altitude ?? 0.0)
                return Coordinate3D(latitude: lat, longitude: lon, altitude: alt, m: m)
            }

        case .epsg4978:
            switch projection {
            case .epsg4978:
                return self
            case .epsg4326, .noSRID:
                let (x, y, z) = Coordinate3D.geodeticToEcef(
                    latitude: latitude, longitude: longitude, altitude: altitude ?? 0.0)
                return Coordinate3D(x: x, y: y, z: z, m: m, projection: .epsg4978)
            case .epsg3857:
                return projected(to: .epsg4326).projected(to: .epsg4978)
            }

        case .noSRID:
            return Coordinate3D(
                x: longitude,
                y: latitude,
                z: altitude,
                m: m,
                projection: .noSRID)
        }
    }

    /// Project this coordinate's latitude.
    ///
    /// - Parameters:
    ///    - newProjection: The target projection
    /// - Returns: The latitude value in the requested projection
    public func latitudeProjected(to newProjection: Projection) -> Double {
        switch newProjection {
        case .epsg3857:
            switch projection {
            case .epsg3857, .noSRID:
                return latitude
            case .epsg4326:
                var y: Double = log(tan((90.0 + latitude) * Double.pi / 360.0)) / (Double.pi / 180.0)
                y *= GISTool.originShift / 180.0
                return y
            case .epsg4978:
                return projected(to: .epsg4326).latitudeProjected(to: .epsg3857)
            }

        case .epsg4326:
            switch projection {
            case .epsg4326, .noSRID:
                return latitude
            case .epsg3857:
                return 180.0 / Double.pi * (2.0 * atan(exp((latitude / GISTool.originShift) * 180.0 * Double.pi / 180.0)) - Double.pi / 2.0)
            case .epsg4978:
                let (lat, _, _) = Coordinate3D.ecefToGeodetic(
                    x: longitude,
                    y: latitude,
                    z: altitude ?? 0.0)
                return lat
            }

        case .epsg4978:
            switch projection {
            case .epsg4978, .noSRID:
                return latitude
            case .epsg4326:
                let (_, y, _) = Coordinate3D.geodeticToEcef(
                    latitude: latitude,
                    longitude: longitude,
                    altitude: altitude ?? 0.0)
                return y
            case .epsg3857:
                return projected(to: .epsg4326).latitudeProjected(to: .epsg4978)
            }

        case .noSRID:
            return latitude
        }
    }

    /// Project this coordinate's longitude.
    ///
    /// - Parameters:
    ///    - newProjection: The target projection
    /// - Returns: The longitude value in the requested projection
    public func longitudeProjected(to newProjection: Projection) -> Double {
        switch newProjection {
        case .epsg3857:
            switch projection {
            case .epsg3857, .noSRID:
                return longitude
            case .epsg4326:
                return longitude * GISTool.originShift / 180.0
            case .epsg4978:
                return projected(to: .epsg4326).longitudeProjected(to: .epsg3857)
            }

        case .epsg4326:
            switch projection {
            case .epsg4326, .noSRID:
                return longitude
            case .epsg3857:
                return (longitude / GISTool.originShift) * 180.0
            case .epsg4978:
                let (_, lon, _) = Coordinate3D.ecefToGeodetic(
                    x: longitude,
                    y: latitude,
                    z: altitude ?? 0.0)
                return lon
            }

        case .epsg4978:
            switch projection {
            case .epsg4978, .noSRID:
                return longitude
            case .epsg4326:
                let (x, _, _) = Coordinate3D.geodeticToEcef(
                    latitude: latitude,
                    longitude: longitude,
                    altitude: altitude ?? 0.0)
                return x
            case .epsg3857:
                return projected(to: .epsg4326).longitudeProjected(to: .epsg4978)
            }

        case .noSRID:
            return longitude
        }
    }

}

// MARK: - EPSG:4978 (ECEF) Helpers

extension Coordinate3D {

    /// Convert geodetic (EPSG:4326) to geocentric (EPSG:4978) coordinates.
    ///
    /// Uses the WGS84 ellipsoid: a = 6,378,137 m, 1/f = 298.257223563.
    ///
    /// - Parameters:
    ///   - latitude: Latitude in degrees
    ///   - longitude: Longitude in degrees
    ///   - altitude: Height above ellipsoid in meters
    /// - Returns: ECEF X, Y, Z in meters
    fileprivate static func geodeticToEcef(
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
    fileprivate static func ecefToGeodetic(
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
        for _ in 0..<10 {
            let sinPhi = sin(phi)
            let N = a / sqrt(1.0 - e2 * sinPhi * sinPhi)
            let h = p / cos(phi) - N
            phi = atan2(z * (N + h), p * ((1.0 - e2) * N + h))
        }

        let sinPhi = sin(phi)
        let N = a / sqrt(1.0 - e2 * sinPhi * sinPhi)
        let h = p / cos(phi) - N

        let lat = phi * 180.0 / .pi
        let lon = atan2(y, x) * 180.0 / .pi

        return (lat, lon, h)
    }

}

// MARK: - GeoJsonReadable

extension Coordinate3D: GeoJsonReadable {

    /// Create a coordinate from a JSON object, which can either be
    /// - GeoJSON,
    /// - or a dictionary with `x`, `y` and `z` values.
    ///
    /// - Note: The [GeoJSON spec](https://datatracker.ietf.org/doc/html/rfc7946)
    ///         uses CRS:84 that specifies coordinates in longitude/latitude order.
    /// - Important: The third value in GeoJSON coordinates will always be ``altitude``, the fourth value
    ///              will be ``m`` if it exists. ``altitude`` can be a JSON `null` value.
    /// - important: The source is expected to be in EPSG:4326.
    /// - Parameters:
    ///    - json: A GeoJSON position array or a dictionary with `x`, `y`, `z` keys
    /// - Returns: A coordinate, or `nil` if parsing fails
    public init?(json: Any?) {
        var pLongitude: Double?
        var pLatitude: Double?
        var pAltitude: CLLocationDistance?
        var pM: Double?

        if let pointArray = json as? [Double?],
           pointArray.count >= 2
        {
            pLongitude = pointArray[0]
            pLatitude = pointArray[1]
            pAltitude = if pointArray.count >= 3 { pointArray[2] } else { nil }
            pM = if pointArray.count >= 4 { pointArray[3] } else { nil }
        }
        else if let pointDictionary = json as? [String: Any] {
            pLongitude = pointDictionary["x"] as? Double
            pLatitude = pointDictionary["y"] as? Double
            pAltitude = pointDictionary["z"] as? CLLocationDistance
            pM = pointDictionary["m"] as? Double
        }
        else {
            return nil
        }

        guard let pLongitude, let pLatitude else { return nil }

        self.init(latitude: pLatitude, longitude: pLongitude, altitude: pAltitude, m: pM)
    }

    /// Dump the coordinate as a GeoJSON coordinate.
    ///
    /// - Important: The result JSON object will have a `null` value for the altitude
    ///              if the ``altitude`` is `nil` and ``m`` exists.
    /// - important: Always projected to EPSG:4326, unless the coordinate has no SRID.
    /// - Returns: An array of doubles (and `nil` placeholders) in GeoJSON order
    public var asJson: [Double?] {
        var result: [Double?] = (projection == .epsg4326 || projection == .noSRID
            ? [longitude, latitude]
            : [longitudeProjected(to: .epsg4326), latitudeProjected(to: .epsg4326)])

        if let altitude {
            result.append(altitude)
            if let m {
                result.append(m)
            }
        }
        else if let m {
            result.append(nil)
            result.append(m)
        }

        return result
    }

    /// Dump the coordinate as a JSON object, as defined in the specification.
    ///
    /// - important: The returned array will always contain ``latitude`` and ``longitude``,
    ///              and ``altitude`` only if it exists.
    /// - Returns: An array of doubles in GeoJSON order (no `nil` placeholders)
    public var asMinimalJson: [Double] {
        var result: [Double] = (projection == .epsg4326 || projection == .noSRID
            ? [longitude, latitude]
            : [longitudeProjected(to: .epsg4326), latitudeProjected(to: .epsg4326)])

        if let altitude {
            result.append(altitude)
        }

        return result
    }

}

// Custom implementation, because the protocol has different prerequisites
extension Coordinate3D {

    /// Dump the coordinate as JSON data.
    ///
    /// - important: Always projected to EPSG:4326, unless the coordinate has no SRID.
    /// - Parameters:
    ///    - prettyPrinted: Whether to pretty-print the output (default `false`)
    /// - Returns: JSON data, or `nil` if serialization fails
    public func asJsonData(prettyPrinted: Bool = false) -> Data? {
        var options: JSONSerialization.WritingOptions = []
        if prettyPrinted {
            options.insert(.prettyPrinted)
            options.insert(.sortedKeys)
        }

        return try? JSONSerialization.data(withJSONObject: asJson, options: options)
    }

    /// Dump the coordinate as JSON.
    ///
    /// - important: Always projected to EPSG:4326, unless the coordinate has no SRID.
    /// - Parameters:
    ///    - prettyPrinted: Whether to pretty-print the output (default `false`)
    /// - Returns: A JSON string, or `nil` if serialization fails
    public func asJsonString(prettyPrinted: Bool = false) -> String? {
        guard let data = asJsonData(prettyPrinted: prettyPrinted) else { return nil }

        return String(data: data, encoding: .utf8)
    }

    /// Write the coordinate in it's JSON representation to a file.
    ///
    /// - important: Always projected to EPSG:4326, unless the coordinate has no SRID.
    /// - Parameters:
    ///    - url: The file URL to write to
    ///    - prettyPrinted: Whether to pretty-print the output (default `false`)
    /// - Returns: `true` if the write succeeded, `false` if serialization failed.
    @discardableResult
    public func write(to url: URL, prettyPrinted: Bool = false) -> Bool {
        guard let data = asJsonData(prettyPrinted: prettyPrinted) else { return false }

        do {
            try data.write(to: url)
            return true
        }
        catch {
            return false
        }
    }

}

// Helper extension to create a valid json array from a sequence of GeoJsonConvertible objects.
extension Sequence<Coordinate3D> {

    /// Returns all elements as an array of JSON objects
    ///
    /// - important: Always projected to EPSG:4326, unless the coordinate has no SRID.
    /// - Returns: An array of GeoJSON position arrays
    public var asJson: [[Double?]] {
        self.map(\.asJson)
    }

}

// MARK: - Equatable

extension Coordinate3D: Equatable {

    /// Coordinates are regarded as equal when they are within a few μm from each other
    /// (mainly to counter small rounding errors).
    /// See also `GISTool.equalityDelta`.
    ///
    /// - note: `GISTool.equalityDelta` works only for coordinates in EPSG:4326 projection.
    ///         Use `equals(other:includingAltitude:equalityDelta:altitudeDelta:)`
    ///         for other projections or if you need more control.
    ///
    /// - note: This also compares the altitudes of coordinates.
    public static func == (
        lhs: Coordinate3D,
        rhs: Coordinate3D
    ) -> Bool {
        lhs.projection == rhs.projection
            && abs(lhs.latitude - rhs.latitude) <= GISTool.equalityDelta
            && abs(lhs.longitude - rhs.longitude) <= GISTool.equalityDelta
            && lhs.altitude == rhs.altitude
    }

    /// Compares two coordinates with the given deltas.
    ///
    /// - note: The `other` coordinate will be projected to the projection of the reveiver.
    /// - Parameters:
    ///    - other: The coordinate to compare against
    ///    - includingAltitude: Whether to compare altitude (default `true`)
    ///    - equalityDelta: The horizontal tolerance (default `GISTool.equalityDelta`)
    ///    - altitudeDelta: The vertical tolerance (default `0.0`)
    /// - Returns: `true` if the coordinates are within the given deltas
    public func equals(
        other: Coordinate3D,
        includingAltitude: Bool = true,
        equalityDelta: Double = GISTool.equalityDelta,
        altitudeDelta: Double = 0.0
    ) -> Bool {
        let other = other.projected(to: projection)

        if abs(latitude - other.latitude) > equalityDelta
            || abs(longitude - other.longitude) > equalityDelta
        {
            return false
        }

        if includingAltitude {
            if let altitude, let otherAltitude = other.altitude {
                return abs(altitude - otherAltitude) <= altitudeDelta
            }

            return altitude == other.altitude
        }

        return true
    }

}

// MARK: - Hashable

extension Coordinate3D: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(projection)
        let lat = (latitude / GISTool.equalityDelta).rounded()
        let lon = (longitude / GISTool.equalityDelta).rounded()
        hasher.combine(lat)
        hasher.combine(lon)
        hasher.combine(altitude)
    }

}
