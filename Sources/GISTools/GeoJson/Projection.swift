
/// Projections that this library can handle.
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
    /// EPSG:4978 - geocentric (ECEF) (https://epsg.io/4978).
    case epsg4978 = 4978
    /// EPSG:3395 - WGS 84 / World Mercator, ellipsoidal Mercator
    /// (https://epsg.io/3395).
    case epsg3395 = 3395
    /// EPSG:32662 - WGS 84 / Plate Carree, equirectangular
    /// (https://epsg.io/32662).
    case epsg32662 = 32662

    /// Initialize a Projection with a SRID number.
    ///
    /// - Parameters:
    ///    - srid: The SRID number (e.g. 4326, 3857)
    /// - Returns: A `Projection`, or `nil` if the SRID is not supported
    public init?(srid: Int) {
        switch srid {
        // A placeholder for 'No SRID'
        case 0: self = .noSRID
        case 102_100, 102_113, 900_913, 3587, 3785, 3857, 41001, 54004: self = .epsg3857
        case 4326: self = .epsg4326
        case 4978: self = .epsg4978
        case 3395: self = .epsg3395
        case 32662: self = .epsg32662
        default: return nil
        }
    }

    /// Initialize a Projection from a WKT projection string (e.g. from a `.prj` file).
    ///
    /// The string is matched against the WKT patterns registered by the
    /// library's projections (in registry order, first match wins):
    /// - EPSG:3857 — `PROJCS["...Pseudo-Mercator..."...]`
    /// - EPSG:3395 — `PROJCS["...Mercator..."...]` (without "Pseudo")
    /// - EPSG:32662 — `PROJCS["...Plate Carree..."...]`
    /// - EPSG:4326 — `GEOGCS["...WGS 84..."...]` or `GEOGCS["...WGS_1984..."...]`
    /// - EPSG:4978 — `GEOCCS["...WGS 84..."...]` or `GEOCCS["...WGS_1984..."...]`
    ///
    /// - Parameter wkt: A WKT projection string
    /// - Returns: A `Projection`, or `nil` if the string is not recognised
    public init?(wkt: String) {
        guard let definition = ProjectionRegistry.definition(matchingWkt: wkt) else {
            return nil
        }
        self = definition.projection
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
        case .epsg4978: return "EPSG:4978"
        case .epsg3395: return "EPSG:3395"
        case .epsg32662: return "EPSG:32662"
        }
    }

}

// MARK: - ProjectionKind

extension Projection {

    /// The receiver's semantic category.
    public var kind: ProjectionKind {
        switch self {
        case .noSRID: .undefined
        case .epsg3857, .epsg3395, .epsg32662: .planar
        case .epsg4326: .geographic
        case .epsg4978: .geocentric
        }
    }

    /// `true` if the receiver uses angular (degree-based) coordinates.
    public var isGeographic: Bool {
        kind == .geographic
    }

    /// `true` if the receiver uses planar (meter-based, Euclidean) coordinates.
    public var isPlanar: Bool {
        kind == .planar
    }

    /// `true` if the receiver uses geocentric 3D cartesian coordinates.
    public var isGeocentric: Bool {
        kind == .geocentric
    }

    /// `false` for ``Projection/noSRID``, `true` otherwise.
    public var hasSRID: Bool {
        kind != .undefined
    }

    /// The absolute value beyond which the receiver's horizontal axis wraps
    /// around (±180° for EPSG:4326, ±`originShift` meters for EPSG:3857),
    /// or `nil` if the horizontal axis does not wrap.
    public var wraparoundExtent: Double? {
        switch self {
        case .noSRID, .epsg4978:
            nil
        case .epsg3857, .epsg3395:
            GISTool.originShift
        case .epsg4326, .epsg32662:
            180.0
        }
    }

    /// Converts a length in meters to the receiver's native coordinate units.
    ///
    /// For geographic (degree-based) projections the value is divided by an
    /// approximate meters-per-degree factor; for all other projections
    /// coordinates are already in meters and the value is returned unchanged.
    ///
    /// - Parameter meters: The length in meters
    /// - Returns: The length in the receiver's coordinate units
    public func crsLength(fromMeters meters: Double) -> Double {
        isGeographic ? meters / 111_325.0 : meters
    }

}
