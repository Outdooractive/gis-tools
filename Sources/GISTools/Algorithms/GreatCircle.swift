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
    /// - Parameter end: End coordinate.
    /// - Parameter npoints: Number of points along the arc (default 100).
    /// - Parameter offset: Controls anti-meridian split threshold (default 10).
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

        guard AntimeridianCutting.coordinatesCrossMeridian(coords) else {
            return LineString(unchecked: coords)
        }

        // Split at the anti-meridian
        var lines: [[Coordinate3D]] = []
        var current: [Coordinate3D] = [coords[0]]

        for i in 1..<coords.count {
            let prev = current.last!
            let curr = coords[i]

            if let intersection = AntimeridianCutting.intersection(prev, curr) {
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
        let startCart = Cartesian3D(start)
        let endCart = Cartesian3D(end)

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
            coords.append(Coordinate3D(pt))
        }
        return coords
    }

}
