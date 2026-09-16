#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// Amersfoort/RD New math for EPSG:28992, the official Dutch grid.
///
/// Oblique stereographic (EPSG method 9809) on the Bessel 1841 ellipsoid:
/// origin 52°09'22.178"N / 5°23'15.5"E, scale factor 0.9999079, false
/// easting/northing 155_000/463_000. Transformations use the Helmert
/// "Amersfoort to WGS 84 (4)" (stated accuracy approximately 1 m),
/// position-vector parameters, flipped to the WGS84→Amersfoort direction.
struct RdNewDefinition: ProjectionDefinition {

    /// **Amersfoort to WGS 84 (4)**: the position-vector equivalent of the
    /// coordinate-frame parameters published in the EPSG registry
    /// (rotations negated).
    private static let helmert = HelmertTransformation(
        datum: .amersfoort,
        dx: 565.4171,
        dy: 50.3319,
        dz: 465.5524,
        rx: -0.398957388243134,
        ry: 0.343987817378283,
        rz: -1.87740163998045,
        scalePpm: 4.0725)

    private static let math = ObliqueStereographicMath(
        ellipsoid: .bessel1841,
        latitudeOfOrigin: 52.15616055555555,
        longitudeOfOrigin: 5.38763888888889,
        scaleFactor: 0.9999079,
        falseEasting: 155_000.0,
        falseNorthing: 463_000.0)

    var projection: Projection { Projection(uncheckedSrid: 28992, definition: self) }
    var kind: ProjectionKind { .planar }
    var datum: Datum { .amersfoort }

    var wraparoundExtent: Double? { nil }

    var validExtent: ProjectionExtent? {
        ProjectionExtent(
            minX: falseEasting - 2_500_000.0,
            minY: falseNorthing - 2_500_000.0,
            maxX: falseEasting + 2_500_000.0,
            maxY: falseNorthing + 2_500_000.0)
    }

    private var falseEasting: Double { 155_000.0 }
    private var falseNorthing: Double { 463_000.0 }

    var worldBoundingBox: BoundingBox? {
        nil
    }

    var wktMatchers: [[String]] {
        [
            ["PROJCS", "RD New"],
            ["PROJCS", "RD_New"],
            ["PROJCS", "Amersfoort"],
        ]
    }

    var prepared: BatchPreparedTransforms {
        let steps = Self.helmert.prepared()
        let math = Self.math
        let projection = self.projection

        return BatchPreparedTransforms(
            forward: { coordinate in
                let datumCoordinate = Self.helmert.transform(
                    wgs84ToDatum: coordinate,
                    step: steps.wgs84ToDatum,
                    targetProjection: projection)
                let (x, y) = math.forward(
                    latitude: datumCoordinate.latitude,
                    longitude: datumCoordinate.longitude)
                return Coordinate3D(
                    x: x,
                    y: y,
                    z: coordinate.altitude,
                    m: coordinate.m,
                    projection: projection)
            },
            inverse: { coordinate in
                let (latitude, longitude) = math.inverse(
                    x: coordinate.x,
                    y: coordinate.y)
                let datumCoordinate = Coordinate3D(
                    latitude: latitude,
                    longitude: longitude,
                    altitude: coordinate.altitude,
                    m: coordinate.m)
                return Self.helmert.transform(
                    datumToWgs84: datumCoordinate,
                    step: steps.datumToWgs84)
            })
    }

    func forward(_ coordinate: Coordinate3D) -> Coordinate3D {
        let datumCoordinate = Self.helmert.transform(
            wgs84ToDatum: coordinate,
            projection: projection)
        let (x, y) = Self.math.forward(
            latitude: datumCoordinate.latitude,
            longitude: datumCoordinate.longitude)

        return Coordinate3D(
            x: x,
            y: y,
            z: coordinate.altitude,
            m: coordinate.m,
            projection: projection)
    }

    func inverse(_ coordinate: Coordinate3D) -> Coordinate3D {
        let (latitude, longitude) = Self.math.inverse(
            x: coordinate.x,
            y: coordinate.y)
        let datumCoordinate = Coordinate3D(
            latitude: latitude,
            longitude: longitude,
            altitude: coordinate.altitude,
            m: coordinate.m)

        return Self.helmert.transform(datumToWgs84: datumCoordinate)
    }

}
