#if !os(Linux)
import CoreLocation
#endif
import Foundation

// MARK: - Projection

public enum Projection: CustomStringConvertible {

    /// No SRID
    case noSRID
    /// EPSG:3857 - web mercator
    case epsg3857
    /// EPSG:4326 - geodetic
    case epsg4326

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

extension Coordinate3D {

    /// Project EPSG:4326 to EPSG:3857
    public var projectedToEpsg3857: CoordinateXY {
        let originShift: Double = 20_037_508.342789244

        let coordinate = self.normalized()
        let x: Double = coordinate.longitude * originShift / 180.0
        var y: Double = log(tan((90.0 + coordinate.latitude) * Double.pi / 360.0)) / (Double.pi / 180.0)
        y *= originShift / 180.0

        return CoordinateXY(x: x, y: y, z: altitude, m: m)
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
