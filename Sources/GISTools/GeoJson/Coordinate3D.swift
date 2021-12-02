import Foundation

#if os(Linux)
public typealias CLLocationDirection = Double
public typealias CLLocationDistance = Double
public typealias CLLocationDegrees = Double
#else
import CoreLocation
#endif

// MARK: Coordinate3D

public struct Coordinate3D: CustomStringConvertible {

    public var latitude: CLLocationDegrees
    public var longitude: CLLocationDegrees
    public var altitude: CLLocationDistance?

    /// Linear referencing or whatever you want it to use for.
    ///
    /// The GeoJSON specification doesn't specifiy the meaning of this value,
    /// and it doesn't guarantee that parsers won't ignore or discard it. See
    /// [chapter 3.1.1 in the spec](https://datatracker.ietf.org/doc/html/rfc7946#section-3.1.1).
    public var m: Double?

    public init(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        self.latitude = latitude
        self.longitude = longitude
    }

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

    public init(_ coordinate: CLLocationCoordinate2D, altitude: CLLocationDistance? = nil) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.altitude = altitude
    }

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    public init(_ location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude

        if location.verticalAccuracy > 0 {
            self.altitude = location.altitude
        }
    }

    public var location: CLLocation {
        CLLocation(
            coordinate: coordinate,
            altitude: altitude ?? -1.0,
            horizontalAccuracy: 1.0, // always valid
            verticalAccuracy: (altitude == nil ? -1.0 : 1.0), // valid if altitude != nil
            timestamp: Date())
    }

}
#endif

extension Coordinate3D {

    /// Clamped to [-180.0, 180.0]
    public mutating func normalize() {
        self = self.normalized()
    }

    /// Clamped to [-180.0, 180.0]
    public func normalized() -> Coordinate3D {
        var longitude = self.longitude

        guard longitude < -180.0 || longitude > 180.0 else { return self }

        while longitude < -180.0 { longitude += 360.0 }
        while longitude > 180.0 { longitude -= 360.0 }

        return Coordinate3D(latitude: latitude, longitude: longitude, altitude: altitude)
    }

}

// MARK: - GeoJsonConvertible

// Note: The GeoJSON spec uses CRS:84 that specifies coordinates
// in longitude/latitude order.
extension Coordinate3D: GeoJsonReadable {

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

    public var asJson: [Double] {
        var result: [Double] = [longitude, latitude]

        if let altitude = altitude {
            result.append(altitude)
        }
        if let m = m {
            result.append(m)
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
            if #available(OSX 10.13, iOS 11.0, *) {
                options.insert(.sortedKeys)
            }
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

public protocol Coordinate2D {

    var latitude: CLLocationDegrees { get set }
    var longitude: CLLocationDegrees { get set }

    init(latitude: CLLocationDegrees, longitude: CLLocationDegrees)

}

extension Coordinate3D: Coordinate2D {}

#if !os(Linux)
extension CLLocationCoordinate2D: Coordinate2D {}
#endif
