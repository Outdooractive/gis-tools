#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// Swiss LV03 math for EPSG:21781 (CH1903 / LV03, easting/northing on
/// the Bessel 1841 ellipsoid, Swiss oblique Mercator — the projection
/// parameters coincide with EPSG:2056; the false easting/northing differ).
///
/// The Helmert transformation uses the EPSG registry set
/// "CH1903 to WGS 84 (2)" (EPSG:1510, translation-only, identical 3-param
/// values as the LV95 set — CH1903 and CH1903+ coincide at meter accuracy;
/// EPSG also documents accuracy 1.5 m for the related entry 1766).
struct Ch1903Lv03Definition: ProjectionDefinition {

    private static let helmert = HelmertTransformation(
        datum: .ch1903,
        dx: 674.374,
        dy: 15.056,
        dz: 405.346)

    /// The Swiss oblique Mercator projection parameters of LV03.
    private static let transverseMercator = SwissObliqueMercatorMath(
        ellipsoid: .bessel1841,
        latitudeOfOrigin: 46.95240555555556,
        longitudeOfOrigin: 7.439583333333333,
        scaleFactor: 1.0,
        falseEasting: 600_000.0,
        falseNorthing: 200_000.0)

    var projection: Projection { Projection(uncheckedSrid: 21_781, definition: self) }
    var kind: ProjectionKind { .planar }
    var datum: Datum { .ch1903 }

    /// Swiss LV03 coordinates never wrap.
    var wraparoundExtent: Double? {
        nil
    }

    /// Unbounded, matching the LV95 sister CRS.
    var validExtent: ProjectionExtent? {
        nil
    }

    var worldBoundingBox: BoundingBox? {
        nil
    }

    var wktMatchers: [[String]] {
        [
            ["PROJCS", "LV03"],
            ["PROJCS", "CH1903"],
        ]
    }

    var prepared: BatchPreparedTransforms {
        let helmertMatrix = Self.helmert.prepared()
        let snowmer = Self.transverseMercator
        let projection = self.projection

        return BatchPreparedTransforms(
            forward: { coordinate in
                let ch1903 = Self.helmert.transform(
                    wgs84ToDatum: coordinate,
                    step: helmertMatrix.wgs84ToDatum)
                let (easting, northing) = snowmer.forward(
                    latitude: ch1903.latitude,
                    longitude: ch1903.longitude)
                return Coordinate3D(
                    x: easting,
                    y: northing,
                    z: coordinate.altitude,
                    m: coordinate.m,
                    projection: projection)
            },
            inverse: { coordinate in
                let (latitude, longitude) = snowmer.inverse(
                    x: coordinate.longitude,
                    y: coordinate.latitude)
                let ch1903 = Coordinate3D(
                    latitude: latitude,
                    longitude: longitude,
                    altitude: coordinate.altitude,
                    m: coordinate.m)
                return Self.helmert.transform(
                    datumToWgs84: ch1903,
                    step: helmertMatrix.datumToWgs84)
            })
    }

    func forward(_ coordinate: Coordinate3D) -> Coordinate3D {
        let ch1903 = Self.helmert.transform(wgs84ToDatum: coordinate)
        let (easting, northing) = Self.transverseMercator.forward(
            latitude: ch1903.latitude,
            longitude: ch1903.longitude)

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

        let ch1903 = Coordinate3D(
            latitude: latitude,
            longitude: longitude,
            altitude: coordinate.altitude,
            m: coordinate.m)

        let wgs84 = Self.helmert.transform(datumToWgs84: ch1903)

        return Coordinate3D(
            latitude: wgs84.latitude,
            longitude: wgs84.longitude,
            altitude: wgs84.altitude,
            m: coordinate.m)
    }

}
