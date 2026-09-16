#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// NAD83 / Conus Albers math for EPSG:5070, the CONUS-wide equal-area
/// standard (USGS, EPA, NLCD rasters).
///
/// Albers equal-area on the GRS80 ellipsoid: origin 23°N/96°W, standard
/// parallels 29.5°/45.5°N, false easting/northing 0. The geodetic reference
/// is NAD83 (``Datum/nad83``), effectively coincident with WGS84 at meter
/// accuracy (see ``Nad83Definition``), so the forward conversion is the
/// projection itself.
struct Epsg5070Definition: ProjectionDefinition {

    private static let math = AlbersEqualAreaMath(
        ellipsoid: .grs80,
        latitudeOfOrigin: 23.0,
        longitudeOfOrigin: -96.0,
        latitudeOfFirstParallel: 29.5,
        latitudeOfSecondParallel: 45.5,
        falseEasting: 0.0,
        falseNorthing: 0.0)

    var projection: Projection {
        Projection(uncheckedSrid: 5070, definition: self)
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
            ["PROJCS", "Conus Albers"],
            ["PROJCS", "NAD83 / Conus Albers"],
            ["PROJCS", "USA_Contiguous_Albers_Equal_Area_Conic"],
            ["PROJCS", "North_America_Albers_Equal_Area_Conic"],
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
