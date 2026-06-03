#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-great-circle

extension Coordinate3D {

    /// Calculates a great circle route from `self` to `end`.
    ///
    /// If the start and end are identical a single-point ``LineString``
    /// of length `npoints` is returned.
    ///
    /// - Parameters:
    ///   - end: End coordinate.
    ///   - npoints: Number of points along the arc (default 100).
    ///   - offset: Controls anti-meridian split threshold (default 10).
    /// - Returns: A ``LineString`` or ``MultiLineString`` representing the arc.
    public func greatCircle(
        to end: Coordinate3D,
        npoints: Int = 100,
        offset: Int = 10
    ) -> any LineStringGeometry {
        guard npoints > 1 else {
            return LineString([self, end]) ?? LineString(unchecked: [self, end])
        }

        // Identical coordinates: return a line with npoints copies
        if self == end {
            let coords = Array(repeating: self, count: npoints)
            return LineString(unchecked: coords)
        }

        let coords = Self.greatCircleCoordinates(
            from: self,
            to: end,
            npoints: npoints,
            offset: offset)

        // Check if the arc crosses the anti-meridian
        var crossesAM = false
        for i in 1..<coords.count {
            if abs(coords[i - 1].longitude - coords[i].longitude) > 180.0 {
                crossesAM = true
                break
            }
        }

        if !crossesAM {
            return LineString(unchecked: coords)
        }

        // Split at the anti-meridian
        var lines: [[Coordinate3D]] = []
        var current: [Coordinate3D] = [coords[0]]

        for i in 1..<coords.count {
            let prev = current.last!
            let curr = coords[i]

            if abs(prev.longitude - curr.longitude) > 180.0 {
                // Crossing detected — find intersection at ±180
                let intersection = Self.interpolateIntersection(prev, curr)
                current.append(intersection.first)
                lines.append(current)
                current = [intersection.second, curr]
            }
            else {
                current.append(curr)
            }
        }
        if current.isNotEmpty {
            lines.append(current)
        }

        if lines.count == 1 {
            return LineString(unchecked: lines[0])
        }
        let lineStrings = lines.map { LineString(unchecked: $0) }
        return MultiLineString(unchecked: lineStrings)
    }

    // MARK: - Great circle interpolation

    /// Computes `npoints` coordinates along the great circle arc from `start` to `end`.
    private static func greatCircleCoordinates(
        from start: Coordinate3D,
        to end: Coordinate3D,
        npoints: Int,
        offset: Int
    ) -> [Coordinate3D] {
        let startCart = toCartesian(start)
        let endCart = toCartesian(end)

        let dot = startCart.x * endCart.x + startCart.y * endCart.y + startCart.z * endCart.z
        let angle = acos(max(-1.0, min(1.0, dot)))

        var coords: [Coordinate3D] = []
        for i in 0..<npoints {
            let t = Double(i) / Double(npoints - 1)
            let pt: Cartesian3D
            if angle < 1e-10 {
                // Start ≈ end; just use start
                pt = startCart
            }
            else {
                let sinAngle = sin(angle)
                let a = sin((1.0 - t) * angle) / sinAngle
                let b = sin(t * angle) / sinAngle
                pt = Cartesian3D(
                    x: a * startCart.x + b * endCart.x,
                    y: a * startCart.y + b * endCart.y,
                    z: a * startCart.z + b * endCart.z)
            }
            coords.append(toGeo(pt))
        }
        return coords
    }

    // MARK: - Cartesian helpers

    private struct Cartesian3D {
        let x: Double
        let y: Double
        let z: Double
    }

    /// Convert lat/lon (degrees) to a unit-sphere Cartesian point.
    private static func toCartesian(_ coord: Coordinate3D) -> Cartesian3D {
        let lat = coord.latitude * .pi / 180.0
        let lon = coord.longitude * .pi / 180.0
        return Cartesian3D(
            x: cos(lat) * cos(lon),
            y: cos(lat) * sin(lon),
            z: sin(lat))
    }

    /// Convert a unit-sphere Cartesian point back to lat/lon (degrees).
    private static func toGeo(_ p: Cartesian3D) -> Coordinate3D {
        let lat = asin(p.z) * 180.0 / .pi
        let lon = atan2(p.y, p.x) * 180.0 / .pi
        return Coordinate3D(latitude: lat, longitude: lon)
    }

    // MARK: - Anti-meridian intersection

    /// Computes the two ±180° intersection points for a segment crossing the anti-meridian.
    private static func interpolateIntersection(
        _ p1: Coordinate3D,
        _ p2: Coordinate3D
    ) -> (first: Coordinate3D, second: Coordinate3D) {
        var unwrapped = p2.longitude
        if p2.longitude - p1.longitude > 180.0 {
            unwrapped = p2.longitude - 360.0
        }
        else if p1.longitude - p2.longitude > 180.0 {
            unwrapped = p2.longitude + 360.0
        }
        let fraction = (180.0 - p1.longitude) / (unwrapped - p1.longitude)
        let lat = p1.latitude + fraction * (p2.latitude - p1.latitude)

        let first: Coordinate3D
        let second: Coordinate3D
        if p1.longitude >= 0.0 {
            first = Coordinate3D(latitude: lat, longitude: 180.0)
            second = Coordinate3D(latitude: lat, longitude: -180.0)
        }
        else {
            first = Coordinate3D(latitude: lat, longitude: -180.0)
            second = Coordinate3D(latitude: lat, longitude: 180.0)
        }
        return (first, second)
    }

}
