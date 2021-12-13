#if os(Linux)
public typealias CLLocationDirection = Double
public typealias CLLocationDistance = Double
public typealias CLLocationDegrees = Double
#else
import CoreLocation
#endif

// MARK: Coordinate3D

/// A three dimensional coordinate (``latitude``, ``longitude``, ``altitude``)
/// plus a generic value ``m``.
public struct Coordinate3D: CustomStringConvertible {

    // A coordinate at (0.0, 0.0) aka Null Island.
    public static var zero: Coordinate3D {
        return Coordinate3D(latitude: 0.0, longitude: 0.0)
    }

    /// The coordinate's `latitude`.
    public var latitude: CLLocationDegrees
    /// The coordinate's `longitude`.
    public var longitude: CLLocationDegrees
    /// The coordinate's `altitude`.
    public var altitude: CLLocationDistance?

    /// Linear referencing, timestamp or whatever you want it to use for.
    ///
    /// The GeoJSON specification doesn't specifiy the meaning of this value,
    /// and it doesn't guarantee that parsers won't ignore or discard it. See
    /// [chapter 3.1.1 in the spec](https://datatracker.ietf.org/doc/html/rfc7946#section-3.1.1).
    /// - Important: ``asJson`` will output `m` only if the coordinate also has an ``altitude``.
    public var m: Double?

    /// Create a coordinate with ``latitude`` and ``longitude``.
    public init(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        self.latitude = latitude
        self.longitude = longitude
    }

    /// Create a coordinate with ``latitude``, ``longitude``, ``altitude`` and ``m``.
    public init(
        latitude: CLLocationDegrees,
        longitude: CLLocationDegrees,
        altitude: CLLocationDistance? = nil,
        m: Double? = nil)
    {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.m = m
    }

    /// A boolean value indicating if this coordinate is (0.0, 0.0) aka Null Island.
    public var isZero: Bool {
        latitude == 0.0 && longitude == 0.0
    }

    public var description: String {
        var compontents: [String] = [
            "longitude: \(longitude)",
            "latitude: \(latitude)",
        ]
        if let altitude = altitude {
            compontents.append("altitude: \(altitude)")
        }
        if let m = m {
            compontents.append("m: \(m)")
        }
        return "Coordinate3D(\(compontents.joined(separator: ", ")))"
    }

}

// MARK: - CoreLocation compatibility

#if !os(Linux)
extension Coordinate3D {

    /// Create a `Coordinate3D` from a `CLLocationCoordinate2D`.
    public init(_ coordinate: CLLocationCoordinate2D, altitude: CLLocationDistance? = nil) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.altitude = altitude
    }

    /// This coordinate as `CLLocationCoordinate2D`.
    public var coordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Create a `Coordinate3D` from a `CLLocation`.
    ///
    /// This will set ``m`` to the location's timestamp using `timeIntervalSinceReferenceDate`.
    public init(_ location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude

        if location.verticalAccuracy > 0.0 {
            self.altitude = location.altitude
        }

        self.m = location.timestamp.timeIntervalSinceReferenceDate
    }

    /// THis coordinate as `CLLocation`.
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
            verticalAccuracy: (altitude == nil ? -1.0 : 1.0), // valid if altitude != nil
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
        var longitude = self.longitude

        guard longitude < -180.0 || longitude > 180.0 else { return self }

        while longitude < -180.0 { longitude += 360.0 }
        while longitude > 180.0 { longitude -= 360.0 }

        return Coordinate3D(latitude: latitude, longitude: longitude, altitude: altitude)
    }

}

// MARK: - GeoJsonConvertible

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
        var result: [Double] = [longitude, latitude]

        if let altitude = altitude {
            result.append(altitude)

            // We can't add `m` if we don't have an altitude
            if let m = m {
                result.append(m)
            }
        }

        return result
    }

}

// Custom implementation, because the protocol has different prerequisites
extension Coordinate3D {

    public func asJsonData(prettyPrinted: Bool = false) -> Data? {
        var options: JSONSerialization.WritingOptions = []
        if prettyPrinted {
            options.insert(.prettyPrinted)
            options.insert(.sortedKeys)
        }

        return try? JSONSerialization.data(withJSONObject: asJson, options: options)
    }

    public func asJsonString(prettyPrinted: Bool = false) -> String? {
        guard let data = asJsonData(prettyPrinted: prettyPrinted) else { return nil }

        return String(data: data, encoding: .utf8)!
    }

    public func write(to url: URL, prettyPrinted: Bool = false) throws {
        try asJsonData(prettyPrinted: prettyPrinted)?.write(to: url)
    }

}

// Helper extension to create a valid json array from a sequence of GeoJsonConvertible objects
extension Sequence where Element == Coordinate3D {

    public var asJson: [[Double]] {
        self.map({ $0.asJson })
    }

}

// MARK: - Equatable

extension Coordinate3D: Equatable {

    public static func == (
        lhs: Coordinate3D,
        rhs: Coordinate3D)
        -> Bool
    {
        abs(lhs.latitude - rhs.latitude) < GISTool.equalityDelta
            && abs(lhs.longitude - rhs.longitude) < GISTool.equalityDelta
            && lhs.altitude == rhs.altitude
    }

}

// MARK: - Hashable

extension Coordinate3D: Hashable {}

// MARK: - Coordinate2D

/// Two dimensional coordinates (`latitute`, `longitude`).
public protocol Coordinate2D {

    var latitude: CLLocationDegrees { get set }
    var longitude: CLLocationDegrees { get set }

    init(latitude: CLLocationDegrees, longitude: CLLocationDegrees)

}

extension Coordinate2D {

    public var coordinate3D: Coordinate3D {
        Coordinate3D(latitude: latitude, longitude: longitude)
    }

}

extension Coordinate3D: Coordinate2D {}

#if !os(Linux)
extension CLLocationCoordinate2D: Coordinate2D {}

extension CLLocation {

    public var coordinate3D: Coordinate3D {
        Coordinate3D(self)
    }

}

#endif
