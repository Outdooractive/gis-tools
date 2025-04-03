#if os(Linux)
public typealias CLLocationDirection = Double
public typealias CLLocationDistance = Double
public typealias CLLocationDegrees = Double
#else
import CoreLocation
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

    /// Create a coordinate with ``latitude`` and ``longitude``.
    /// Projection will be *EPSG:4326*.
    public init(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        self.projection = .epsg4326
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = nil
        self.m = nil
    }

    /// Create a coordinate with ``latitude``, ``longitude``, ``altitude`` and ``m``.
    /// Projection will be *EPSG:4326*.
    public init(
        latitude: CLLocationDegrees,
        longitude: CLLocationDegrees,
        altitude: CLLocationDistance? = nil,
        m: Double? = nil)
    {
        self.projection = .epsg4326
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.m = m
    }

    /// Create a coordinate with ``x``, ``y``, ``z`` and ``m``.
    /// Default projection will we *EPSG:3857* but can be overridden.
    public init(
        x: Double,
        y: Double,
        z: Double? = nil,
        m: Double? = nil,
        projection: Projection = .epsg3857)
    {
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

// MARK: - CoreLocation compatibility

#if !os(Linux)
extension Coordinate3D {

    /// Create a `Coordinate3D` from a `CLLocationCoordinate2D`.
    public init(_ coordinate: CLLocationCoordinate2D, altitude: CLLocationDistance? = nil) {
        self.projection = .epsg4326
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.altitude = altitude
        self.m = nil
    }

    /// This coordinate as `CLLocationCoordinate2D`.
    public var coordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: latitudeProjected(to: .epsg4326),
            longitude: longitudeProjected(to: .epsg4326))
    }

    /// Create a `Coordinate3D` from a `CLLocation`.
    ///
    /// This will set ``m`` to the location's timestamp using `timeIntervalSinceReferenceDate`.
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
#endif

// MARK: - Helpers

extension Coordinate3D {

    /// Clamped to [-180.0, 180.0].
    public mutating func normalize() {
        self = self.normalized()
    }

    /// Clamped to [-180.0, 180.0].
    public func normalized() -> Coordinate3D {
        switch projection {
        case .epsg3857:
            guard longitude < -GISTool.originShift || longitude > GISTool.originShift else { return self }

            var longitude = self.longitude
            while longitude < -GISTool.originShift { longitude += (2.0 * GISTool.originShift) }
            while longitude > GISTool.originShift { longitude -= (2.0 * GISTool.originShift) }

            return Coordinate3D(x: longitude, y: latitude, z: altitude, m: m)

        case .epsg4326:
            guard longitude < -180.0 || longitude > 180.0 else { return self }

            var longitude = self.longitude
            while longitude < -180.0 { longitude += 360.0 }
            while longitude > 180.0 { longitude -= 360.0 }

            return Coordinate3D(latitude: latitude, longitude: longitude, altitude: altitude, m: m)

        default:
            return self
        }
    }

    /// Clamped to [[-180,-90], [180,90]]
    public mutating func clamp() {
        self = self.clamped()
    }

    /// Clamped to [[-180,-90], [180,90]]
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
            }

        case .epsg4326:
            switch projection {
            case .epsg4326, .noSRID:
                return latitude
            case .epsg3857:
                return 180.0 / Double.pi * (2.0 * atan(exp((latitude / GISTool.originShift) * 180.0 * Double.pi / 180.0)) - Double.pi / 2.0)
            }

        case .noSRID:
            return latitude
        }
    }

    /// Project this coordinate's longitude.
    public func longitudeProjected(to newProjection: Projection) -> Double {
        switch newProjection {
        case .epsg3857:
            switch projection {
            case .epsg3857, .noSRID:
                return longitude
            case .epsg4326:
                return longitude * GISTool.originShift / 180.0
            }

        case .epsg4326:
            switch projection {
            case .epsg4326, .noSRID:
                return longitude
            case .epsg3857:
                return (longitude / GISTool.originShift) * 180.0
            }

        case .noSRID:
            return longitude
        }
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
    public func asJsonString(prettyPrinted: Bool = false) -> String? {
        guard let data = asJsonData(prettyPrinted: prettyPrinted) else { return nil }

        return String(data: data, encoding: .utf8)!
    }

    /// Write the coordinate in it's JSON represenation to a file.
    ///
    /// - important: Always projected to EPSG:4326, unless the coordinate has no SRID.
    public func write(to url: URL, prettyPrinted: Bool = false) throws {
        try asJsonData(prettyPrinted: prettyPrinted)?.write(to: url)
    }

}

// Helper extension to create a valid json array from a sequence of GeoJsonConvertible objects.
extension Sequence<Coordinate3D> {

    /// Returns all elements as an array of JSON objects
    ///
    /// - important: Always projected to EPSG:4326, unless the coordinate has no SRID.
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
        rhs: Coordinate3D)
        -> Bool
    {
        lhs.projection == rhs.projection
            && abs(lhs.latitude - rhs.latitude) <= GISTool.equalityDelta
            && abs(lhs.longitude - rhs.longitude) <= GISTool.equalityDelta
            && lhs.altitude == rhs.altitude
    }

    /// Compares two coordinates with the given deltas.
    ///
    /// - note: The `other` coordinate will be projected to the projection of the reveiver.
    public func equals(
        other: Coordinate3D,
        includingAltitude: Bool = true,
        equalityDelta: Double = GISTool.equalityDelta,
        altitudeDelta: Double = 0.0)
        -> Bool
    {
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

extension Coordinate3D: Hashable {}

#if !os(Linux)
extension CLLocation {

    /// The receiver as a ``Coordinate3D``.
    public var coordinate3D: Coordinate3D {
        Coordinate3D(self)
    }

}

extension CLLocationCoordinate2D {

    /// The receiver as a ``Coordinate3D``.
    public var coordinate3D: Coordinate3D {
        Coordinate3D(self)
    }

}
#endif
