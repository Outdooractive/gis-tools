#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// Irish Transverse Mercator math for EPSG:2157 (IRENET95 / Irish
/// Transverse Mercator): a transverse Mercator on the **GRS80**
/// ellipsoid with the IRENET95 datum — an Irish realization of ETRS89,
/// which is effectively coincident with WGS84 at meter accuracy (see
/// ``Etrs89Definition`` for the same treatment).
///
/// Published origin parameters (EPSG:2157): lat0 = 53°30' N,
/// lon0 = 8°W, scale factor 0.99982, false easting 600_000 m, false
/// northing 750_000 m.
///
/// - Note: IRENET95 is the modern, real-meter-consistent Irish frame;
///   EPSG:29902/29903 are the datum-aware predecessors.
struct IrishTransverseMercatorDefinition: ProjectionDefinition {

    /// The transverse Mercator projection parameters of ITM.
    private static let transverseMercator = TransverseMercatorMath(
        ellipsoid: .grs80,
        latitudeOfOrigin: 53.5,
        longitudeOfOrigin: -8.0,
        scaleFactor: 0.99982,
        falseEasting: 600_000.0,
        falseNorthing: 750_000.0)

    var projection: Projection { Projection(uncheckedSrid: 2157, definition: self) }
    var kind: ProjectionKind { .planar }
    var datum: Datum { .irenet95 }

    /// ITM coordinates never wrap.
    var wraparoundExtent: Double? {
        nil
    }

    /// Unbounded: grid coordinates outside the typical Irish sector are
    /// extrapolations, not clamped.
    var validExtent: ProjectionExtent? {
        nil
    }

    var worldBoundingBox: BoundingBox? {
        nil
    }

    var wktMatchers: [[String]] {
        [
            ["PROJCS", "Irish Transverse Mercator"],
            ["PROJCS", "Irish Transverse Mercator (ETRS89)"],
            ["PROJCS", "IRENET95 / Irish Transverse Mercator"],
        ]
    }

    func forward(_ coordinate: Coordinate3D) -> Coordinate3D {
        let (easting, northing) = Self.transverseMercator.forward(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude)

        return Coordinate3D(
            x: easting,
            y: northing,
            z: coordinate.altitude,
            m: coordinate.m,
            projection: projection)
    }

    func inverse(_ coordinate: Coordinate3D) -> Coordinate3D {
        let (latitude, longitude) = Self.transverseMercator.inverse(
            x: coordinate.longitude,
            y: coordinate.latitude)

        return Coordinate3D(
            latitude: latitude,
            longitude: longitude,
            altitude: coordinate.altitude,
            m: coordinate.m)
    }

}
