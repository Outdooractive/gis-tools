#if !os(Linux)
import CoreLocation
#endif
import Foundation

// MARK: - Projection

/// Projections that this library can handle (EPSG:3857 and EPSG:4326).
public enum Projection: CustomStringConvertible, Sendable {

    /// No SRID (invalid projection)
    case noSRID
    /// EPSG:3857 - web mercator
    case epsg3857
    /// EPSG:4326 - geodetic
    case epsg4326

    public static let originShift = 2.0 * Double.pi * 6_378_137.0 / 2.0 // 20037508.342789244

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

    public var srid: Int {
        switch self {
        case .noSRID: return 0
        case .epsg3857: return 3857
        case .epsg4326: return 4326
        }
    }

    public var description: String {
        switch self {
        case .noSRID: return "No SRID"
        case .epsg3857: return "EPSG:3857"
        case .epsg4326: return "EPSG:4326"
        }
    }

}

extension ProjectedCoordinate {

    /// Project to EPSG:3857
    public var projectedToEpsg3857: ProjectedCoordinate {
        if projection == .epsg3857 { return self }

        let coordinate3D = Coordinate3D(latitude: latitude, longitude: longitude).normalized()

        let x: Double = coordinate3D.longitude * Projection.originShift / 180.0
        var y: Double = log(tan((90.0 + coordinate3D.latitude) * Double.pi / 360.0)) / (Double.pi / 180.0)
        y *= Projection.originShift / 180.0

        return ProjectedCoordinate(latitude: y, longitude: x, projection: .epsg3857)
    }

    /// Project to EPSG:4326
    public var projectedToEpsg4326: ProjectedCoordinate {
        if projection == .epsg4326 { return self }

        let longitude: Double = (longitude / Projection.originShift) * 180.0
        var latitude: Double = (latitude / Projection.originShift) * 180.0
        latitude = 180.0 / Double.pi * (2.0 * atan(exp(latitude * Double.pi / 180.0)) - Double.pi / 2.0)

        return ProjectedCoordinate(latitude: latitude, longitude: longitude, projection: .epsg4326)
    }

}

extension Coordinate3D {

    /// Project to EPSG:4326
    public var projectedToEpsg4326: ProjectedCoordinate {
        projectedCoordinate
    }

    /// Project to EPSG:3857
    public var projectedToEpsg3857: ProjectedCoordinate {
        projectedCoordinate.projectedToEpsg3857
    }

}

extension CoordinateXY {

    /// Project EPSG:3857 to EPSG:4326
    public var projectedToEpsg4326: Coordinate3D {
        let originShift: Double = 20_037_508.342789244

        let longitude: Double = (x / originShift) * 180.0
        var latitude: Double = (y / originShift) * 180.0
        latitude = 180.0 / Double.pi * (2.0 * atan(exp(latitude * Double.pi / 180.0)) - Double.pi / 2.0)

        return Coordinate3D(latitude: latitude, longitude: longitude, altitude: z, m: m)
    }

}
