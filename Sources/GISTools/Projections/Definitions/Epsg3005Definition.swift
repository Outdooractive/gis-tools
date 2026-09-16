#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// NAD83 / BC Albers math for EPSG:3005, British Columbia's official
/// provincial projection.
///
/// Albers equal-area on the GRS80 ellipsoid: origin 45°N/126°W, standard
/// parallels 50°/58.5°N, false easting 1_000_000 m, false northing 0. The
/// geodetic reference is NAD83 (``Datum/nad83``), effectively coincident
/// with WGS84 at meter accuracy (see ``Nad83Definition``), so the forward
/// conversion is the projection itself.
struct Epsg3005Definition: ProjectionDefinition {

    private static let math = AlbersEqualAreaMath(
        ellipsoid: .grs80,
        latitudeOfOrigin: 45.0,
        longitudeOfOrigin: -126.0,
        latitudeOfFirstParallel: 50.0,
        latitudeOfSecondParallel: 58.5,
        falseEasting: 1_000_000.0,
        falseNorthing: 0.0)

    var projection: Projection {
        Projection(uncheckedSrid: 3005, definition: self)
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
            ["PROJCS", "BC Albers"],
            ["PROJCS", "NAD83 / BC Albers"],
            ["PROJCS", "Canada_Albers_Equal_Area_Conic"],
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
