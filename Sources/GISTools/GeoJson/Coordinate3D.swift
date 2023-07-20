#if os(Linux)
public typealias CLLocationDirection = Double
public typealias CLLocationDistance = Double
public typealias CLLocationDegrees = Double
#else
import CoreLocation
#endif
import Foundation

// MARK: Coordinate3D

/// A three dimensional coordinate (``latitude``/``y``, ``longitude``/``x``, ``altitude``/``z``)
/// plus a generic value ``m``.
public struct Coordinate3D: Projectable, CustomStringConvertible, Sendable {

    /// A coordinate at (0.0, 0.0) aka Null Island.
    public static var zero: Coordinate3D {
        Coordinate3D(latitude: 0.0, longitude: 0.0)
    }

    /// The coordinates projection, either EPSG:4326 or EPSG:3857.
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
    /// - Important: ``asJson`` will output `m` only if the coordinate also has an ``altitude``.
    public var m: Double?

    /// Alias for longitude
    @inlinable
    public var x: Double { longitude }

    /// Alias for latitude
    @inlinable
    public var y: Double { latitude }

    /// Create a coordinate with ``latitude`` and ``longitude``.
    /// Projection will be EPSG:4326.
    public init(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        self.projection = .epsg4326
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = nil
        self.m = nil
    }

    /// Create a coordinate with ``latitude``, ``longitude``, ``altitude`` and ``m``.
    /// Projection will be EPSG:4326.
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
    /// Default projection will we EPSG:3857 but can be overridden.
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

    /// A textual representation of the receiver.
    public var description: String {
        var compontents: [String] = [
            "\(projection == .epsg4326 ? "longitude" : "x"): \(longitude)",
            "\(projection == .epsg4326 ? "latitude" : "y"): \(latitude)",
        ]
        if let altitude {
            compontents.append("\(projection == .epsg4326 ? "altitude" : "z"): \(altitude)")
        }
        if let m {
            compontents.append("m: \(m)")
        }
        return "Coordinate3D<\(projection.description)>(\(compontents.joined(separator: ", ")))"
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

extension Coordinate3D {

    /// Clamped to [-180.0, 180.0].
    public mutating func normalize() {
        self = self.normalized()
    }

    /// Clamped to [-180.0, 180.0].
    public func normalized() -> Coordinate3D {
        switch projection {
        case .epsg3857:
            guard longitude < -Projection.originShift || longitude > Projection.originShift else { return self }

            var longitude = self.longitude
            while longitude < -Projection.originShift { longitude += (2.0 * Projection.originShift) }
            while longitude > Projection.originShift { longitude -= (2.0 * Projection.originShift) }

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

}

extension Coordinate3D {

    /// Clamped to [[-180,-90], [180,90]]
    public mutating func clamp() {
        self = self.clamped()
    }

    /// Clamped to [[-180,-90], [180,90]]
    public func clamped() -> Coordinate3D {
        switch projection {
        case .epsg3857:
            guard longitude < -Projection.originShift || longitude > Projection.originShift
                || latitude < -Projection.originShift || latitude > Projection.originShift
            else { return self }

            return Coordinate3D(
                x: min(Projection.originShift, max(-Projection.originShift, longitude)),
                y: min(Projection.originShift, max(-Projection.originShift, latitude)),
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

extension Coordinate3D {

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
                y *= Projection.originShift / 180.0
                return y
            }

        case .epsg4326:
            switch projection {
            case .epsg4326, .noSRID:
                return latitude
            case .epsg3857:
                return 180.0 / Double.pi * (2.0 * atan(exp((latitude / Projection.originShift) * 180.0 * Double.pi / 180.0)) - Double.pi / 2.0)
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
                return longitude * Projection.originShift / 180.0
            }

        case .epsg4326:
            switch projection {
            case .epsg4326, .noSRID:
                return longitude
            case .epsg3857:
                return (longitude / Projection.originShift) * 180.0
            }

        case .noSRID:
            return longitude
        }
    }

}

// MARK: - GeoJsonReadable

extension Coordinate3D: GeoJsonReadable {

    /// Create a coordinate from a JSON object.
    ///
    /// - Note: The [GeoJSON spec](https://datatracker.ietf.org/doc/html/rfc7946)
    ///         uses CRS:84 that specifies coordinates in longitude/latitude order.
    /// - Important: The third value will always be ``altitude``, the fourth value
    ///              will be ``m`` if it exists.
    public init?(json: Any?) {
        guard let pointArray = json as? [Double],
              pointArray.count >= 2
        else { return nil }

        if pointArray.count == 2 {
            self.init(latitude: pointArray[1], longitude: pointArray[0])
        }
        else if pointArray.count == 3 {
            self.init(latitude: pointArray[1], longitude: pointArray[0], altitude: pointArray[2])
        }
        else {
            self.init(latitude: pointArray[1], longitude: pointArray[0], altitude: pointArray[2], m: pointArray[3])
        }
    }

    /// Dump the coordinate as a JSON object.
    ///
    /// - Important: The output array will contain ``m`` only if this coordinate
    ///              also contains ``altitude`` to prevent any disambiguity.
    public var asJson: [Double] {
        var result: [Double] = (projection == .epsg4326 || projection == .noSRID
            ? [longitude, latitude]
            : [longitudeProjected(to: .epsg4326), latitudeProjected(to: .epsg4326)])

        if let altitude {
            result.append(altitude)

            // We can't add `m` if we don't have an altitude
            if let m {
                result.append(m)
            }
        }

        return result
    }

}

// Custom implementation, because the protocol has different prerequisites
extension Coordinate3D {

    /// Dump the coordinate as JSON data.
    public func asJsonData(prettyPrinted: Bool = false) -> Data? {
        var options: JSONSerialization.WritingOptions = []
        if prettyPrinted {
            options.insert(.prettyPrinted)
            options.insert(.sortedKeys)
        }

        return try? JSONSerialization.data(withJSONObject: asJson, options: options)
    }

    /// Dump the coordinate as JSON.
    public func asJsonString(prettyPrinted: Bool = false) -> String? {
        guard let data = asJsonData(prettyPrinted: prettyPrinted) else { return nil }

        return String(data: data, encoding: .utf8)!
    }

    /// Write the coordinate in it's JSON represenation to a file.
    public func write(to url: URL, prettyPrinted: Bool = false) throws {
        try asJsonData(prettyPrinted: prettyPrinted)?.write(to: url)
    }

}

// Helper extension to create a valid json array from a sequence of GeoJsonConvertible objects.
extension Sequence<Coordinate3D> {

    // Return the coordinate as JSON.
    public var asJson: [[Double]] {
        self.map(\.asJson)
    }

}

// MARK: - Coordinate3D + Equatable

extension Coordinate3D: Equatable {

    public static func == (
        lhs: Coordinate3D,
        rhs: Coordinate3D)
        -> Bool
    {
        lhs.projection == rhs.projection
            && abs(lhs.latitude - rhs.latitude) < GISTool.equalityDelta
            && abs(lhs.longitude - rhs.longitude) < GISTool.equalityDelta
            && lhs.altitude == rhs.altitude
    }

}

// MARK: - Coordinate3D + Hashable

extension Coordinate3D: Hashable {}

#if !os(Linux)
extension CLLocation {

    /// The receiver as a ``Coordinate3D``.
    public var coordinate3D: Coordinate3D {
        Coordinate3D(self)
    }

}

#endif
