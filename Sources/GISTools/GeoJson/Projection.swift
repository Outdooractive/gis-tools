
/// Projections that this library can handle (EPSG:3857 and EPSG:4326).
public enum Projection:
    Int,
    CustomStringConvertible,
    Codable,
    Sendable
{

    /// No SRID (invalid/unknown projection).
    case noSRID = 0
    /// EPSG:3857 - web mercator (https://epsg.io/3857).
    case epsg3857 = 3857
    /// EPSG:4326 - geodetic (https://epsg.io/4326).
    case epsg4326 = 4326

    /// Initialize a Projection with a SRID number.
    public init?(srid: Int) {
        switch srid {
        // A placeholder for 'No SRID'
        case 0: self = .noSRID
        case 102_100, 102_113, 900_913, 3587, 3785, 3857, 41001, 54004: self = .epsg3857
        case 4326: self = .epsg4326
        default: return nil
        }
    }

    /// The receiver's SRID number.
    public var srid: Int {
        self.rawValue
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
