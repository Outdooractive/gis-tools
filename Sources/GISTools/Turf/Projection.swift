#if !os(Linux)
import CoreLocation
#endif
import Foundation

public enum Projection: CustomStringConvertible {

    /// EPSG:3857 - web mercator
    case epsg3857
    /// EPSG:4326 - geodetic
    case epsg4326

    public init?(srid: Int) {
        switch srid {
        // See https://epsg.io/3857
        case 3857, 900913, 3587, 54004, 41001, 102113, 102100, 3785: self = .epsg3857
        // See https://epsg.io/4326
        case 4326: self = .epsg4326
        default: return nil
        }
    }

    public var srid: Int {
        switch self {
        case .epsg3857: return 3857
        case .epsg4326: return 4326
        }
    }

    public var description: String {
        switch self {
        case .epsg3857: return "EPSG:3857"
        case .epsg4326: return "EPSG:4326"
        }
    }

}

extension Coordinate3D {

    /// Project EPSG:4326 to EPSG:3857
    public func projectToEpsg3857() -> CoordinateXY {
        let originShift: Double = 20037508.342789244

        let coordinate = self.normalized()
        let x: Double = coordinate.longitude * originShift / 180.0
        var y: Double = log(tan((90.0 + coordinate.latitude) * Double.pi / 360.0)) / (Double.pi / 180.0)
        y *= originShift / 180.0

        return CoordinateXY(x: x, y: y, z: altitude, m: m)
    }

}

extension CoordinateXY {

    /// Project EPSG:3857 to EPSG:4326
    public func projectToEpsg4326() -> Coordinate3D {
        let originShift: Double = 20037508.342789244

        let longitude: Double = (x / originShift) * 180.0
        var latitude: Double = (y / originShift) * 180.0
        latitude = 180.0 / Double.pi * (2.0 * atan(exp(latitude * Double.pi / 180.0)) - Double.pi / 2.0)

        return Coordinate3D(latitude: latitude, longitude: longitude, altitude: z, m: m)
    }

}
