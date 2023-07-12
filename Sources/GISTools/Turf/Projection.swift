#if !os(Linux)
import CoreLocation
#endif
import Foundation

// MARK: Projection

/// Projections that this library can handle (EPSG:3857 and EPSG:4326).
public enum Projection: CustomStringConvertible, Sendable {

    /// No SRID (invalid projection)
    case noSRID
    /// EPSG:3857 - web mercator
    case epsg3857
    /// EPSG:4326 - geodetic
    case epsg4326

    public static let originShift = 2.0 * Double.pi * GISTool.equatorialRadius / 2.0 // 20037508.342789244

    /// Initialize a Projection with a SRID number.
    public init?(srid: Int) {
        switch srid {
        // A placeholder for 'No SRID'
        case 0: self = .noSRID
        // See https://epsg.io/3857
        case 102_100, 102_113, 900_913, 3587, 3785, 3857, 41001, 54004: self = .epsg3857
        // See https://epsg.io/4326
        case 4326: self = .epsg4326
        default: return nil
        }
    }

    /// The receiver's SRID number.
    public var srid: Int {
        switch self {
        case .noSRID: return 0
        case .epsg3857: return 3857
        case .epsg4326: return 4326
        }
    }

    /// A human readable description of the receiver.
    public var description: String {
        switch self {
        case .noSRID: return "No SRID"
        case .epsg3857: return "EPSG:3857"
        case .epsg4326: return "EPSG:4326"
        }
    }

}

// MARK: - ProjectedCoordinate extensions

extension ProjectedCoordinate {

    /// Project to EPSG:3857
    public var projectedToEpsg3857: ProjectedCoordinate {
        if projection == .epsg3857 { return self }

        let coordinate3D = Coordinate3D(latitude: latitude, longitude: longitude, altitude: altitude)

        let x: Double = coordinate3D.longitude * Projection.originShift / 180.0
        var y: Double = log(tan((90.0 + coordinate3D.latitude) * Double.pi / 360.0)) / (Double.pi / 180.0)
        y *= Projection.originShift / 180.0

        return ProjectedCoordinate(latitude: y, longitude: x, altitude: altitude, projection: .epsg3857)
    }

    /// Project to EPSG:4326
    public var projectedToEpsg4326: ProjectedCoordinate {
        if projection == .epsg4326 { return self }

        let longitude: Double = (longitude / Projection.originShift) * 180.0
        var latitude: Double = (latitude / Projection.originShift) * 180.0
        latitude = 180.0 / Double.pi * (2.0 * atan(exp(latitude * Double.pi / 180.0)) - Double.pi / 2.0)

        return ProjectedCoordinate(latitude: latitude, longitude: longitude, altitude: altitude, projection: .epsg4326)
    }

}

// MARK: - ProjectedBoundingBox extensions

extension ProjectedBoundingBox {

    /// Project to EPSG:3857
    public var projectedToEpsg3857: ProjectedBoundingBox {
        if projection == .epsg3857 { return self }

        return ProjectedBoundingBox(
            southWest: southWest.projectedToEpsg3857,
            northEast: northEast.projectedToEpsg3857)
    }

    /// Project to EPSG:4326
    public var projectedToEpsg4326: ProjectedBoundingBox {
        if projection == .epsg4326 { return self }

        return ProjectedBoundingBox(
            southWest: southWest.projectedToEpsg4326,
            northEast: northEast.projectedToEpsg4326)
    }

}

// MARK: - BoundingBox extensions

extension BoundingBox {

    /// The receiver as a ``ProjectedBoundingBox``.
    public var projectedBoundingBox: ProjectedBoundingBox {
        ProjectedBoundingBox(
            southWest: southWest.projectedCoordinate,
            northEast: northEast.projectedCoordinate)
    }

    /// Project to EPSG:4326
    public var projectedToEpsg4326: ProjectedBoundingBox {
        projectedBoundingBox
    }

    /// Project to EPSG:3857
    public var projectedToEpsg3857: ProjectedBoundingBox {
        projectedBoundingBox.projectedToEpsg3857
    }

}

// MARK: - Coordinate3D extensions

extension Coordinate3D {

    /// The receiver as a ``ProjectedCoordinate``.
    public var projectedCoordinate: ProjectedCoordinate {
        ProjectedCoordinate(latitude: latitude, longitude: longitude, altitude: altitude, projection: .epsg4326)
    }

    /// Project to EPSG:4326
    public var projectedToEpsg4326: ProjectedCoordinate {
        projectedCoordinate
    }

    /// Project to EPSG:3857
    public var projectedToEpsg3857: ProjectedCoordinate {
        projectedCoordinate.projectedToEpsg3857
    }

    /// Project to EPSG:3857
    public var coordinateXY: CoordinateXY {
        projectedCoordinate.coordinateXY
    }

}

// MARK: - CoordinateXY extensions

extension CoordinateXY {

    /// The receiver as a ``ProjectedCoordinate``.
    public var projectedCoordinate: ProjectedCoordinate {
        ProjectedCoordinate(latitude: y, longitude: x, altitude: z, projection: .epsg3857)
    }

    /// Project to EPSG:4326
    public var projectedToEpsg4326: ProjectedCoordinate {
        projectedCoordinate.projectedToEpsg4326
    }

    /// Project to EPSG:3857
    public var projectedToEpsg3857: ProjectedCoordinate {
        projectedCoordinate
    }

    /// Project to EPSG:4326
    public var coordinate3D: Coordinate3D {
        projectedCoordinate.coordinate3D
    }

}
