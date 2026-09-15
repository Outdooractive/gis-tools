import Foundation

// MARK: - EPSG:3395

/// Ellipsoidal Mercator math for EPSG:3395 (WGS 84 / World Mercator).
///
/// Unlike EPSG:3857 (spherical formulas on the WGS84 ellipsoid), EPSG:3395
/// uses the ellipsoidal Mercator formulas, so y values differ from
/// EPSG:3857 away from the equator.
struct Epsg3395Definition: ProjectionDefinition {

    /// The EPSG-registered projected bound of EPSG:3395 on the y axis
    /// (corresponding to roughly ±85° latitude; the y value diverges
    /// towards ±90°).
    private static let maxExtent = 20_048_966.104014604

    var projection: Projection { Projection(uncheckedSrid: 3395, definition: self) }
    var kind: ProjectionKind { .planar }

    var wraparoundExtent: Double? { GISTool.originShift }
    var wktMatchers: [[String]] {
        [
            ["PROJCS", "Mercator"],
        ]
    }

    var validExtent: ProjectionExtent? {
        ProjectionExtent(
            minX: -GISTool.originShift,
            minY: -Self.maxExtent,
            maxX: GISTool.originShift,
            maxY: Self.maxExtent)
    }

    var worldBoundingBox: BoundingBox? {
        BoundingBox(
            southWest: Coordinate3D(x: -GISTool.originShift, y: -Self.maxExtent, projection: .epsg3395),
            northEast: Coordinate3D(x: GISTool.originShift, y: Self.maxExtent, projection: .epsg3395))
    }

    func forward(_ coordinate: Coordinate3D) -> Coordinate3D {
        let a = GISTool.equatorialRadius
        let e = sqrt(GISTool.wgs84EccentricitySquared)

        let x = coordinate.longitude * GISTool.originShift / 180.0

        let phi = coordinate.latitude * .pi / 180.0
        let sinPhi = sin(phi)
        let conformalLatitudeFactor = pow((1.0 - e * sinPhi) / (1.0 + e * sinPhi), e / 2.0)
        let y = a * log(tan(Double.pi / 4.0 + phi / 2.0) * conformalLatitudeFactor)

        return Coordinate3D(
            x: x,
            y: y,
            z: coordinate.altitude,
            m: coordinate.m,
            projection: .epsg3395)
    }

    func inverse(_ coordinate: Coordinate3D) -> Coordinate3D {
        let a = GISTool.equatorialRadius
        let e = sqrt(GISTool.wgs84EccentricitySquared)

        let longitude = (coordinate.longitude / GISTool.originShift) * 180.0

        // Iteratively solve the inverse ellipsoidal Mercator formula for
        // latitude (converges in a few iterations; 10 for safety).
        //
        // Forward: y = a * ln(tan(π/4 + φ/2) * c) with
        // c = ((1 - e·sinφ) / (1 + e·sinφ))^(e/2), so with t = exp(y/a):
        // tan(π/4 + φ/2) = t / c  →  φ = 2·atan(t / c) - π/2.
        let t = exp(coordinate.y / a)
        var phi = 2.0 * atan(t) - Double.pi / 2.0
        for _ in 0 ..< 10 {
            let sinPhi = sin(phi)
            let conformalLatitudeFactor = pow((1.0 - e * sinPhi) / (1.0 + e * sinPhi), e / 2.0)
            phi = 2.0 * atan(t / conformalLatitudeFactor) - Double.pi / 2.0
        }

        let latitude = phi * 180.0 / .pi

        return Coordinate3D(
            latitude: latitude,
            longitude: longitude,
            altitude: coordinate.altitude,
            m: coordinate.m)
    }

}
