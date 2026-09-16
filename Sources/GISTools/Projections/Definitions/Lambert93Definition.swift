#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// RGF93/Lambert-93 math for EPSG:2154, the official French grid.
///
/// Lambert conformal conic (EPSG method 9801) on the GRS80 ellipsoid:
/// standard parallels 49°/44°, origin 46.5°N/3°E, false easting/northing
/// 700_000/6_600_000. RGF93 coincides with ETRS89 (the identity
/// transformation applies; see ``Etrs89Definition``), so the forward
/// conversion is the projection itself.
struct Lambert93Definition: ProjectionDefinition {

    private static let math = LambertConformalConicMath(
        ellipsoid: .grs80,
        latitudeOfOrigin: 46.5,
        longitudeOfOrigin: 3.0,
        latitudeOfFirstParallel: 49.0,
        latitudeOfSecondParallel: 44.0,
        scaleFactor: 1.0,
        falseEasting: 700_000.0,
        falseNorthing: 6_600_000.0)

    var projection: Projection { Projection(uncheckedSrid: 2154, definition: self) }
    var kind: ProjectionKind { .planar }
    var datum: Datum { .etrs89 }   // RGF93: the French ETRS89 realization

    var wraparoundExtent: Double? { nil }

    var validExtent: ProjectionExtent? {
        ProjectionExtent(
            minX: falseEasting - 1_500_000.0,
            minY: falseNorthing - 1_500_000.0,
            maxX: falseEasting + 1_500_000.0,
            maxY: falseNorthing + 1_500_000.0)
    }

    private var falseEasting: Double { 700_000.0 }
    private var falseNorthing: Double { 6_600_000.0 }

    var worldBoundingBox: BoundingBox? {
        nil
    }

    var wktMatchers: [[String]] {
        [
            ["PROJCS", "Lambert-93"],
            ["PROJCS", "Lambert_93"],
            ["PROJCS", "RGF93"],
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
