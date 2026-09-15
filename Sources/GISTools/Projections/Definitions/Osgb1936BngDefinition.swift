#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// British National Grid math for EPSG:27700 (OSGB 1936 / British National
/// Grid): a modified transverse Mercator projection on the Airy 1830
/// ellipsoid with the OS-documented approximate Helmert transformation
/// (stated accuracy approximately 2 m; the OS-recommended route for
/// sub-meter accuracy is the OSTN15 grid, which the library does not
/// incorporate: see the grid shift support issue).
///
/// Reference parameters (EPSG:27700 / OS Guide, appendix A):
/// TM origin at 49°N / 2°W, scale factor 0.9996012717, false easting
/// 400_000 m, false northing −100_000 m.
///
/// The valid extent is `nil` (unbounded): coordinates south of the false
/// northing (northern Scilly, southwest of the projection origin) carry
/// *negative* northings, so a nominal sector extent would reject or clamp
/// valid values.
struct Osgb1936BngDefinition: ProjectionDefinition {

    private static let helmert = HelmertTransformation.osgb1936

    /// The projection parameters of the British National Grid.
    private static let transverseMercator = TransverseMercatorMath(
        ellipsoid: .airy1830,
        latitudeOfOrigin: 49.0,
        longitudeOfOrigin: -2.0,
        scaleFactor: 0.9996012717,
        falseEasting: 400_000.0,
        falseNorthing: -100_000.0)

    var projection: Projection { Projection(uncheckedSrid: 27700, definition: self) }
    var kind: ProjectionKind { .planar }
    var datum: Datum { .osgb1936 }

    /// British National Grid coordinates never wrap.
    var wraparoundExtent: Double? {
        nil
    }

    /// Unbounded: the National Grid sector includes negative northings
    /// southwest of the projection origin.
    var validExtent: ProjectionExtent? {
        nil
    }

    var worldBoundingBox: BoundingBox? {
        nil
    }

    var wktMatchers: [[String]] {
        [
            ["PROJCS", "British National Grid"],
            ["PROJCS", "OSGB_1936_British_National_Grid"],
            ["OSGB 1936 / British National Grid"],
        ]
    }

    /// Hoisted batch conversion functions: the Helmert rotation matrices
    /// and the TM parameterization are built once per batch instead of
    /// per coordinate. The coordinate chain is Helmert -> TM and
    /// TM -> Helmert in the inverse, with the EPSG:4326 label only used as
    /// a staging representation between the two.
    var prepared: BatchPreparedTransforms {
        let steps = Self.helmert.prepared()
        let tm = Self.transverseMercator
        let projection = self.projection

        return BatchPreparedTransforms(
            forward: { coordinate in
                let osgb36 = Self.helmert.transform(
                    wgs84ToDatum: coordinate,
                    step: steps.wgs84ToDatum)
                let (easting, northing) = tm.forward(
                    latitude: osgb36.latitude,
                    longitude: osgb36.longitude)
                return Coordinate3D(
                    x: easting,
                    y: northing,
                    z: coordinate.altitude,
                    m: coordinate.m,
                    projection: projection)
            },
            inverse: { coordinate in
                let (latitude, longitude) = tm.inverse(
                    x: coordinate.longitude,
                    y: coordinate.latitude)
                let osgb36 = Coordinate3D(
                    latitude: latitude,
                    longitude: longitude,
                    altitude: coordinate.altitude,
                    m: coordinate.m)
                let wgs84 = Self.helmert.transform(
                    datumToWgs84: osgb36,
                    step: steps.datumToWgs84)
                return Coordinate3D(
                    latitude: wgs84.latitude,
                    longitude: wgs84.longitude,
                    altitude: wgs84.altitude,
                    m: coordinate.m)
            })
    }

    func forward(_ coordinate: Coordinate3D) -> Coordinate3D {
        let osgb36 = Self.helmert.transform(wgs84ToDatum: coordinate)
        let (easting, northing) = Self.transverseMercator.forward(
            latitude: osgb36.latitude,
            longitude: osgb36.longitude)

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

        let osgb36 = Coordinate3D(
            latitude: latitude,
            longitude: longitude,
            altitude: coordinate.altitude,
            m: coordinate.m)

        let wgs84 = Self.helmert.transform(datumToWgs84: osgb36)

        return Coordinate3D(
            latitude: wgs84.latitude,
            longitude: wgs84.longitude,
            altitude: wgs84.altitude,
            m: coordinate.m)
    }

}
