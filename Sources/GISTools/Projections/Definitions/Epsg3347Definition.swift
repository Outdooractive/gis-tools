#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// NAD83 / Statistics Canada Lambert math for EPSG:3347, the
/// Statistics Canada projection used for national thematic mapping.
///
/// Lambert conformal conic on the GRS80 ellipsoid: origin
/// 63.390675°N/91.866667°W, standard parallels 49°/77°N, false
/// easting/northing 6_200_000/3_000_000. The geodetic reference is NAD83
/// (``Datum/nad83``), effectively coincident with WGS84 at meter accuracy
/// (see ``Nad83Definition``), so the forward conversion is the projection
/// itself.
struct Epsg3347Definition: ProjectionDefinition {

    private static let math = LambertConformalConicMath(
        ellipsoid: .grs80,
        latitudeOfOrigin: 63.390675,
        longitudeOfOrigin: -91.8666666666667,
        latitudeOfFirstParallel: 49.0,
        latitudeOfSecondParallel: 77.0,
        scaleFactor: 1.0,
        falseEasting: 6_200_000.0,
        falseNorthing: 3_000_000.0)

    var projection: Projection {
        Projection(uncheckedSrid: 3347, definition: self)
    }

    var kind: ProjectionKind {
        .planar
    }

    var datum: Datum {
        .nad83
    }

    var wraparoundExtent: Double? {
        nil
    }

    var validExtent: ProjectionExtent? {
        nil
    }

    var worldBoundingBox: BoundingBox? {
        nil
    }

    var wktMatchers: [[String]] {
        [
            ["PROJCS", "Statistics Canada Lambert"],
            ["PROJCS", "NAD83 / Statistics Canada Lambert"],
            ["PROJCS", "Canada_Lambert_Conformal_Conic"],
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
                    x: coordinate.longitude,
                    y: coordinate.latitude)
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
            x: coordinate.longitude,
            y: coordinate.latitude)

        return Coordinate3D(
            latitude: latitude,
            longitude: longitude,
            altitude: coordinate.altitude,
            m: coordinate.m)
    }

}
