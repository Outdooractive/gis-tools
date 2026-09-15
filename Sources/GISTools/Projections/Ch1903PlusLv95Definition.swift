#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// Swiss LV95 math for EPSG:2056 (CH1903+ / LV95, easting/northing on
/// the Bessel 1841 ellipsoid, Swiss oblique Mercator).
///
/// The Helmert transformation uses the EPSG registry set
/// "CH1903+ to WGS 84 (1)" (EPSG:1676, `_3`_parameter translation-only,
/// stated accuracy approximately 1 m). Both CH1903 and CH1903+ (EPSG
/// 1646/1647/1676/1510) coincide on that 3-param set at meter accuracy.
///
/// Published origin parameters (EPSG:2056): lat0 = 46°57'08.66"",
/// lon0 = 7°26'22.5"", scale factor 1, false easting 2_600_000 m, false
/// northing 1_200_000 m.
struct Ch1903PlusLv95Definition: ProjectionDefinition {

    private static let helmert = HelmertTransformation(
        datum: .ch1903plus,
        dx: 674.374,
        dy: 15.056,
        dz: 405.346)

    /// The Swiss oblique Mercator projection parameters of LV95.
    private static let transverseMercator = SwissObliqueMercatorMath(
        ellipsoid: .bessel1841,
        latitudeOfOrigin: 46.95240555555556,
        longitudeOfOrigin: 7.439583333333333,
        scaleFactor: 1.0,
        falseEasting: 2_600_000.0,
        falseNorthing: 1_200_000.0)

    var projection: Projection { Projection(uncheckedSrid: 2056, definition: self) }
    var kind: ProjectionKind { .planar }
    var datum: Datum { .ch1903plus }

    /// Swiss LV95 coordinates never wrap.
    var wraparoundExtent: Double? {
        nil
    }

    /// Unbounded: coordinates outside the Swiss National Grid's typical
    /// federal extent stay valid rather than being clamped away.
    var validExtent: ProjectionExtent? {
        nil
    }

    var worldBoundingBox: BoundingBox? {
        nil
    }

    var wktMatchers: [[String]] {
        [
            ["PROJCS", "LV95"],
            ["PROJCS", "Swiss Oblique Mercator"],
            ["PROJCS", "CH1903+"],
        ]
    }

    var prepared: BatchPreparedTransforms {
        let helmertMatrix = Self.helmert.prepared()
        let somerc = Self.transverseMercator
        let projection = self.projection

        return BatchPreparedTransforms(
            forward: { coordinate in
                let ch1903plus = Self.helmert.transform(
                    wgs84ToDatum: coordinate,
                    step: helmertMatrix.wgs84ToDatum)
                let (easting, northing) = somerc.forward(
                    latitude: ch1903plus.latitude,
                    longitude: ch1903plus.longitude)
                return Coordinate3D(
                    x: easting,
                    y: northing,
                    z: coordinate.altitude,
                    m: coordinate.m,
                    projection: projection)
            },
            inverse: { coordinate in
                let (latitude, longitude) = somerc.inverse(
                    x: coordinate.longitude,
                    y: coordinate.latitude)
                let ch1903plus = Coordinate3D(
                    latitude: latitude,
                    longitude: longitude,
                    altitude: coordinate.altitude,
                    m: coordinate.m)
                return Self.helmert.transform(
                    datumToWgs84: ch1903plus,
                    step: helmertMatrix.datumToWgs84)
            })
    }

    func forward(_ coordinate: Coordinate3D) -> Coordinate3D {
        let ch1903plus = Self.helmert.transform(wgs84ToDatum: coordinate)
        let (easting, northing) = Self.transverseMercator.forward(
            latitude: ch1903plus.latitude,
            longitude: ch1903plus.longitude)

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

        let ch1903plus = Coordinate3D(
            latitude: latitude,
            longitude: longitude,
            altitude: coordinate.altitude,
            m: coordinate.m)

        let wgs84 = Self.helmert.transform(datumToWgs84: ch1903plus)

        return Coordinate3D(
            latitude: wgs84.latitude,
            longitude: wgs84.longitude,
            altitude: wgs84.altitude,
            m: coordinate.m)
    }

}
