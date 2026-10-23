#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: - EPSG:32662

/// Equirectangular (Plate Carrée) math for EPSG:32662
/// (WGS 84 / Plate Carree).
///
/// EPSG:32662 is an equirectangular projection whose coordinate unit is
/// **metres**, not degrees: x = a·λ, and y is the WGS84 meridian arc from
/// the equator to φ. This is the same formula as PROJ's
/// `+proj=eqc +lat_ts=0 +datum=WGS84 +units=m` (EPSG method 9823 applied to
/// the WGS84 ellipsoid). Using raw degrees here would be wrong by a factor
/// of about 111 km per degree.
///
/// The `worldBoundingBox` and `validExtent` therefore span
/// ±`GISTool.originShift` on x and ±`GISTool.originShift / 2` on y.
struct Epsg32662Definition: ProjectionDefinition {

    var projection: Projection { Projection(uncheckedSrid: 32_662, definition: self) }
    var kind: ProjectionKind { .planar }

    var wraparoundExtent: Double? { GISTool.originShift }
    var wktMatchers: [[String]] {
        [
            ["PROJCS", "Plate Carree"],
        ]
    }

    var validExtent: ProjectionExtent? {
        let halfShift = GISTool.originShift / 2.0
        return ProjectionExtent(
            minX: -GISTool.originShift,
            minY: -halfShift,
            maxX: GISTool.originShift,
            maxY: halfShift)
    }

    var worldBoundingBox: BoundingBox? {
        let halfShift = GISTool.originShift / 2.0
        return BoundingBox(
            southWest: Coordinate3D(x: -GISTool.originShift, y: -halfShift, projection: .epsg32662),
            northEast: Coordinate3D(x: GISTool.originShift, y: halfShift, projection: .epsg32662))
    }

    func forward(_ coordinate: Coordinate3D) -> Coordinate3D {
        let meridianArc = TransverseMercatorMath.meridianArc(
            coordinate.latitude.degreesToRadians,
            ellipsoid: .wgs84)

        return Coordinate3D(
            x: coordinate.longitude * GISTool.originShift / 180.0,
            y: meridianArc,
            z: coordinate.altitude,
            m: coordinate.m,
            projection: .epsg32662)
    }

    func inverse(_ coordinate: Coordinate3D) -> Coordinate3D {
        let latitude = TransverseMercatorMath.latitude(
            forMeridianArc: coordinate.y,
            ellipsoid: .wgs84)

        return Coordinate3D(
            latitude: latitude * 180.0 / .pi,
            longitude: coordinate.x / GISTool.originShift * 180.0,
            altitude: coordinate.altitude,
            m: coordinate.m)
    }

}
