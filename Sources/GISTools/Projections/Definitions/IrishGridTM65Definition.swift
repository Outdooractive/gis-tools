#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// Irish Grid math for EPSG:29902 (TM65 / Irish Grid): a transverse
/// Mercator on the **Modified Airy** ellipsoid with the Irish datum.
///
/// The Helmert transformation uses the EPSG registry set
/// "TM65 to WGS 84 (2)" (EPSG:1641, 7-parameter, stated accuracy
/// approximately 1 m).
///
/// Published origin parameters (EPSG:29902): lat0 = 53°30' N,
/// lon0 = 8°W, scale factor 1.000035, false easting 200_000 m, false
/// northing 250_000 m.
///
/// - Note: EPSG:29902 is the datum-aware *TM65* Irish Grid. The 1975
///   readjustment ("Geodetic Datum of 1965"/TM75) ships as EPSG:29903,
///   and the modern IRENET95 realization as EPSG:2157.
struct IrishGridTM65Definition: ProjectionDefinition {

    private static let helmert = HelmertTransformation(
        datum: .tm65,
        dx: 482.5,
        dy: -130.6,
        dz: 564.6,
        rx: -1.042,
        ry: -0.214,
        rz: -0.631,
        scalePpm: 8.15)

    /// The transverse Mercator projection parameters of the Irish Grid.
    private static let transverseMercator = TransverseMercatorMath(
        ellipsoid: .modifiedAiry,
        latitudeOfOrigin: 53.5,
        longitudeOfOrigin: -8.0,
        scaleFactor: 1.000035,
        falseEasting: 200_000.0,
        falseNorthing: 250_000.0)

    var projection: Projection { Projection(uncheckedSrid: 29_902, definition: self) }
    var kind: ProjectionKind { .planar }
    var datum: Datum { .tm65 }

    /// Irish Grid coordinates never wrap.
    var wraparoundExtent: Double? {
        nil
    }

    /// Unbounded: grid coordinates outside the typical Irish sector are
    /// mathematical extrapolations, not clamped.
    var validExtent: ProjectionExtent? {
        nil
    }

    var worldBoundingBox: BoundingBox? {
        nil
    }

    var wktMatchers: [[String]] {
        [
            ["PROJCS", "TM65 / Irish Grid"],
            ["PROJCS", "TM65_Irish_Grid"],
            ["PROJCS", "Irish Grid"],
        ]
    }

    func forward(_ coordinate: Coordinate3D) -> Coordinate3D {
        let tm65 = Self.helmert.transform(wgs84ToDatum: coordinate)
        let (easting, northing) = Self.transverseMercator.forward(
            latitude: tm65.latitude,
            longitude: tm65.longitude)

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

        let tm65 = Coordinate3D(
            latitude: latitude,
            longitude: longitude,
            altitude: coordinate.altitude,
            m: coordinate.m)

        let wgs84 = Self.helmert.transform(datumToWgs84: tm65)

        return Coordinate3D(
            latitude: wgs84.latitude,
            longitude: wgs84.longitude,
            altitude: wgs84.altitude,
            m: coordinate.m)
    }

}
