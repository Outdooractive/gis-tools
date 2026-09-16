#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// ETRS89-LCC math for EPSG:3034 (LCC Europe), the European Lambert
/// conformal conic ensemble representation (EPSG method 9801 on the
/// GRS80 ellipsoid).
///
/// Standard parallels 35°/65°, origin 52°N/10°E, false easting/northing
/// 4_000_000/2_800_000. The geodetic reference is ETRS89, treated as an
/// identity over WGS84 (see ``Etrs89Definition``).
struct Etrs89LccDefinition: ProjectionDefinition {

    private static let math = LambertConformalConicMath(
        ellipsoid: .grs80,
        latitudeOfOrigin: 52.0,
        longitudeOfOrigin: 10.0,
        latitudeOfFirstParallel: 35.0,
        latitudeOfSecondParallel: 65.0,
        scaleFactor: 1.0,
        falseEasting: 4_000_000.0,
        falseNorthing: 2_800_000.0)

    var projection: Projection { Projection(uncheckedSrid: 3034, definition: self) }
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

    private var falseEasting: Double { 4_000_000.0 }
    private var falseNorthing: Double { 2_800_000.0 }

    var worldBoundingBox: BoundingBox? {
        nil
    }

    var wktMatchers: [[String]] {
        [
            ["PROJCS", "LCC Europe"],
            ["PROJCS", "ETRS89-LCC"],
            ["PROJCS", "ETRS89_Extended_LCC"],
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
