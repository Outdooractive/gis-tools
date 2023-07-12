#if !os(Linux)
import CoreLocation
#endif
import Foundation

/// A three dimensional coordinate (``latitude``, ``longitude``, ``altitude``)
/// plus a projection.
public struct ProjectedCoordinate {

    /// The coordinate's `latitude`.
    public var latitude: CLLocationDegrees
    /// The coordinate's `longitude`.
    public var longitude: CLLocationDegrees
    /// The coordinate's `altitude`.
    public var altitude: CLLocationDistance?
    /// The coordinate's `projection`
    public let projection: Projection

    /// Create a coordinate with ``latitude``, ``longitude``, ``altitude`` and ``projection``.
    public init(
        latitude: CLLocationDegrees,
        longitude: CLLocationDegrees,
        altitude: CLLocationDistance? = nil,
        projection: Projection)
    {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.projection = projection
    }

    /// A textual representation of the receiver.
    public var description: String {
        var compontents: [String] = [
            projection.description,
            "longitude: \(longitude)",
            "latitude: \(latitude)",
        ]
        if let altitude = altitude {
            compontents.append("altitude: \(altitude)")
        }
        return "Coordinate3D(\(compontents.joined(separator: ", ")))"
    }

}

extension ProjectedCoordinate {

    /// Clamped to the projection's limits
    public mutating func clamp() {
        self = self.clamped()
    }

    /// Clamped to the projection's limits
    public func clamped() -> ProjectedCoordinate {
        switch projection {
        case .noSRID:
            return self
        case .epsg3857:
            return ProjectedCoordinate(
                latitude: min(Projection.originShift, max(-Projection.originShift, latitude)),
                longitude: min(Projection.originShift, max(-Projection.originShift, longitude)),
                altitude: altitude,
                projection: projection)
        case .epsg4326:
            return ProjectedCoordinate(
                latitude: min(90.0, max(-90.0, latitude)),
                longitude: min(180.0, max(-180.0, longitude)),
                altitude: altitude,
                projection: projection)
        }
    }

}

// MARK: - Compatibility

extension ProjectedCoordinate {

    /// Returns the receiver as a ``Coordinate3D``.
    public var coordinate3D: Coordinate3D {
        let projected = projectedToEpsg4326
        return Coordinate3D(latitude: projected.latitude, longitude: projected.longitude)
    }

    /// Returns the receiver as a ``CoordinateXY``.
    public var coordinateXY: CoordinateXY {
        let projected = projectedToEpsg3857
        return CoordinateXY(x: projected.longitude, y: projected.latitude)
    }

}

// MARK: - Equatable

extension ProjectedCoordinate: Equatable {

    public static func == (
        lhs: ProjectedCoordinate,
        rhs: ProjectedCoordinate)
        -> Bool
    {
        lhs.projection == rhs.projection
            && abs(lhs.latitude - rhs.latitude) < GISTool.equalityDelta
            && abs(lhs.longitude - rhs.longitude) < GISTool.equalityDelta
            && lhs.altitude == rhs.altitude
    }

}

// MARK: - Hashable

extension ProjectedCoordinate: Hashable {}
