#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-polygon-smooth
// Based on Chaikin's algorithm: https://www.cs.unc.edu/~dm/UNC/COMP258/LECTURES/Chaikins-Algorithm.pdf

extension Polygon {

    /// Smooths the polygon using Chaikin's algorithm.
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
                        latitude: coord.latitude,
                        longitude: coord.longitude < 0.0 ? coord.longitude + 360.0 : coord.longitude)
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
                        latitude: coord.latitude,
                        longitude: coord.longitude > 180.0 ? coord.longitude - 360.0 : coord.longitude)
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
            var smoothed: [Coordinate3D] = []
            let n = ring.count - 1 // last == first
            for i in 0..<n {
                let p0 = ring[i]
                let p1 = ring[(i + 1) % n]
                // Chaikin: insert Q (3/4, 1/4) and R (1/4, 3/4)
                let q = Coordinate3D(
                    latitude: 0.75 * p0.latitude + 0.25 * p1.latitude,
                    longitude: 0.75 * p0.longitude + 0.25 * p1.longitude)
                let r = Coordinate3D(
                    latitude: 0.25 * p0.latitude + 0.75 * p1.latitude,
                    longitude: 0.25 * p0.longitude + 0.75 * p1.longitude)
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
    /// - Parameter iterations: Number of smoothing passes (default 1).
    /// - Returns: A new smoothed MultiPolygon.
    /// - Warning: May create degenerate polygons at high iteration counts.
    public func smooth(iterations: Int = 1) -> MultiPolygon {
        let smoothed = polygons.map { $0.smooth(iterations: iterations) }
        return MultiPolygon(unchecked: smoothed)
    }

}
