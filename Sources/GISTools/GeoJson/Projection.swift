import Foundation

// MARK: Projection

/// Projections that this library can handle (EPSG:3857 and EPSG:4326).
public enum Projection: CustomStringConvertible, Sendable {

    /// No SRID (invalid/unknown projection)
    case noSRID
    /// EPSG:3857 - web mercator
    case epsg3857
    /// EPSG:4326 - geodetic
    case epsg4326

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
