#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-polygon-smooth
// Based on Chaikin's algorithm: https://www.cs.unc.edu/~dm/UNC/COMP258/LECTURES/Chaikins-Algorithm.pdf

extension Polygon {

    /// Smooths the polygon using Chaikin's algorithm.
    ///
    /// When all coordinates have an ``altitude`` value, the Z component is
    /// smoothed using the same Chaikin weights (0.75 / 0.25) as the X and Y
    /// components. Otherwise the result has no altitude.
    ///
    /// - Parameter iterations: Number of smoothing passes (default 1).
    /// - Returns: A new smoothed polygon.
    /// - Warning: May create degenerate polygons at high iteration counts.
    public func smooth(iterations: Int = 1) -> Polygon {
        let spansAntimeridian = crossesAntimeridian

        let normalizedCoords: [[Coordinate3D]]
        if spansAntimeridian {
            normalizedCoords = coordinates.map { ring in
                ring.map { coord in
                    Coordinate3D(
                        x: coord.longitude < 0.0 ? coord.longitude + 360.0 : coord.longitude,
                        y: coord.latitude,
                        z: coord.altitude,
                        m: coord.m,
                        projection: coord.projection)
                }
            }
        }
        else {
            normalizedCoords = coordinates
        }

        var resultCoords = normalizedCoords
        for _ in 0..<iterations {
            resultCoords = smoothRings(resultCoords)
        }

        if spansAntimeridian {
            resultCoords = resultCoords.map { ring in
                ring.map { coord in
                    Coordinate3D(
                        x: coord.longitude > 180.0 ? coord.longitude - 360.0 : coord.longitude,
                        y: coord.latitude,
                        z: coord.altitude,
                        m: coord.m,
                        projection: coord.projection)
                }
            }
        }

        return Polygon(unchecked: resultCoords)
    }

    /// Smooths a single set of rings.
    private func smoothRings(_ rings: [[Coordinate3D]]) -> [[Coordinate3D]] {
        var output: [[Coordinate3D]] = []
        for ring in rings {
            guard ring.count >= 3 else {
                output.append(ring)
                continue
            }
            let hasAltitude = ring.allSatisfy({ $0.altitude != nil })
            var smoothed: [Coordinate3D] = []
            let n = ring.count - 1 // last == first
            for i in 0..<n {
                let p0 = ring[i]
                let p1 = ring[(i + 1) % n]
                // Chaikin: insert Q (3/4, 1/4) and R (1/4, 3/4)
                // The same weights apply to X, Y and Z.
                let qLat = 0.75 * p0.latitude + 0.25 * p1.latitude
                let qLon = 0.75 * p0.longitude + 0.25 * p1.longitude
                let rLat = 0.25 * p0.latitude + 0.75 * p1.latitude
                let rLon = 0.25 * p0.longitude + 0.75 * p1.longitude
                let qz: Double?
                let rz: Double?
                if hasAltitude {
                    qz = 0.75 * p0.altitude! + 0.25 * p1.altitude!
                    rz = 0.25 * p0.altitude! + 0.75 * p1.altitude!
                }
                else {
                    qz = nil
                    rz = nil
                }
                let q = Coordinate3D(x: qLon, y: qLat, z: qz, projection: projection)
                let r = Coordinate3D(x: rLon, y: rLat, z: rz, projection: projection)
                smoothed.append(q)
                smoothed.append(r)
            }
            // Close the ring
            smoothed.append(smoothed[0])
            output.append(smoothed)
        }
        return output
    }

}

extension MultiPolygon {

    /// Smooths all polygons in the MultiPolygon using Chaikin's algorithm.
    ///
    /// When all coordinates have an ``altitude`` value, the Z component is
    /// smoothed using the same Chaikin weights as X and Y.
    /// Otherwise the result has no altitude.
    ///
    /// - Parameter iterations: Number of smoothing passes (default 1).
    /// - Returns: A new smoothed MultiPolygon.
    /// - Warning: May create degenerate polygons at high iteration counts.
    public func smooth(iterations: Int = 1) -> MultiPolygon {
        let smoothed = polygons.map { $0.smooth(iterations: iterations) }
        return MultiPolygon(unchecked: smoothed)
    }

}
