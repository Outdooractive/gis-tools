#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// ETRS89-LAEA math for EPSG:3035 (LAEA Europe), the official EU-wide
/// equal-area grid (Eurostat/INSPIRE pan-European thematic mapping).
///
/// Lambert azimuthal equal-area on the GRS80 ellipsoid (EPSG method 9820):
/// origin 52°N/10°E, false easting/northing 4_321_000/3_210_000. The
/// geodetic reference is ETRS89, treated as an identity over WGS84 (see
/// ``Etrs89Definition``), so the forward conversion is the projection
/// itself.
struct Etrs89LaeaDefinition: ProjectionDefinition {

    private static let math = LambertAzimuthalEqualAreaMath(
        ellipsoid: .grs80,
        latitudeOfOrigin: 52.0,
        longitudeOfOrigin: 10.0,
        scaleFactor: 1.0,
        falseEasting: 4_321_000.0,
        falseNorthing: 3_210_000.0)

    var projection: Projection { Projection(uncheckedSrid: 3035, definition: self) }
    var kind: ProjectionKind { .planar }
    var datum: Datum { .etrs89 }

    var wraparoundExtent: Double? { nil }

    var validExtent: ProjectionExtent? {
        ProjectionExtent(
            minX: falseEasting - 8_000_000.0,
            minY: falseNorthing - 8_000_000.0,
            maxX: falseEasting + 8_000_000.0,
            maxY: falseNorthing + 8_000_000.0)
    }

    private var falseEasting: Double { 4_321_000.0 }
    private var falseNorthing: Double { 3_210_000.0 }

    var worldBoundingBox: BoundingBox? {
        nil
    }

    var wktMatchers: [[String]] {
        [
            ["PROJCS", "LAEA Europe"],
            ["PROJCS", "ETRS89-LAEA"],
            ["PROJCS", "ETRS89_Extended_LAEA"],
            ["PROJCS", "ETRS89-extended / LAEA"],
        ]
    }

    var prepared: BatchPreparedTransforms {
        let math = Self.math
        let projection = self.projection

        return BatchPreparedTransforms(
            forward: { coordinate in
                let (x, y) = math.forward(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude)
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
                return Coordinate3D(
                    latitude: latitude,
                    longitude: longitude,
                    altitude: coordinate.altitude,
                    m: coordinate.m)
            })
    }

    func forward(_ coordinate: Coordinate3D) -> Coordinate3D {
        let (x, y) = Self.math.forward(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude)

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

        return Coordinate3D(
            latitude: latitude,
            longitude: longitude,
            altitude: coordinate.altitude,
            m: coordinate.m)
    }

}
