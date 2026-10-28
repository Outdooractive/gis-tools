import Foundation

/// Linearizes curved WKB/WKT geometries into the straight geometry types that
/// the GeoJSON model supports.
///
/// The GeoJSON model has no native curve types, so `CircularString`,
/// `CompoundCurve`, `CurvePolygon`, `MultiCurve` and `MultiSurface` are
/// converted while decoding. Circular arcs are sampled with
/// ``segmentsPerQuadrant`` segments per quarter circle.
enum CurveLinearization {

    /// The number of line segments used for a quarter circle.
    static let segmentsPerQuadrant = 32

    /// Converts the points of a `CircularString` into a linear coordinate list.
    ///
    /// A `CircularString` stores arcs as consecutive triples: start, a point on
    /// the arc, and end. Consecutive arcs share their first and last point.
    ///
    /// - Parameter coordinates: The control points of the circular string.
    /// - Returns: The linearized coordinates.
    static func circularString(_ coordinates: [Coordinate3D]) -> [Coordinate3D] {
        guard coordinates.count >= 3 else { return coordinates }

        var result: [Coordinate3D] = [coordinates[0]]
        var index = 0

        while index + 2 < coordinates.count {
            let arc = arc(
                from: coordinates[index],
                through: coordinates[index + 1],
                to: coordinates[index + 2])

            result.append(contentsOf: arc.dropFirst())
            index += 2
        }

        // Invalid input with an even number of points: keep the trailing point
        // instead of silently dropping it.
        if index + 1 < coordinates.count {
            result.append(coordinates[index + 1])
        }

        return result
    }

    /// Samples the circular arc through three points.
    ///
    /// - Parameters:
    ///   - start: The start point.
    ///   - mid: A point on the arc between `start` and `end`.
    ///   - end: The end point.
    /// - Returns: The sampled arc, including both endpoints.
    private static func arc(
        from start: Coordinate3D,
        through mid: Coordinate3D,
        to end: Coordinate3D,
    ) -> [Coordinate3D] {
        let ax = start.x
        let ay = start.y
        let bx = mid.x
        let by = mid.y
        let cx = end.x
        let cy = end.y

        let scale = max(1.0, abs(ax), abs(ay), abs(bx), abs(by), abs(cx), abs(cy))
        let tolerance = 1e-9 * scale

        let determinant = 2.0 * ((ax * (by - cy)) + (bx * (cy - ay)) + (cx * (ay - by)))

        guard abs(determinant) > 1e-12 * scale * scale else {
            // Collinear or coincident points: no meaningful circle.
            return [start, mid, end]
        }

        let aSquared = (ax * ax) + (ay * ay)
        let bSquared = (bx * bx) + (by * by)
        let cSquared = (cx * cx) + (cy * cy)

        let centerX = ((aSquared * (by - cy)) + (bSquared * (cy - ay)) + (cSquared * (ay - by))) / determinant
        let centerY = ((aSquared * (cx - bx)) + (bSquared * (ax - cx)) + (cSquared * (bx - ax))) / determinant

        let radius = hypot(ax - centerX, ay - centerY)
        guard radius > tolerance else { return [start, mid, end] }

        let startAngle = atan2(ay - centerY, ax - centerX)
        let midAngle = atan2(by - centerY, bx - centerX)
        let endAngle = atan2(cy - centerY, cx - centerX)

        let isFullCircle = hypot(ax - cx, ay - cy) <= tolerance
        let sweep: Double

        if isFullCircle {
            // The start and end point are identical, so use the side of the
            // centre that the middle point lies on to choose the direction.
            let cross = ((bx - centerX) * (ay - centerY)) - ((by - centerY) * (ax - centerX))
            sweep = cross >= 0 ? 2.0 * .pi : -2.0 * .pi
        }
        else {
            let counterClockwiseSweep = normalizedAngle(endAngle - startAngle)
            let counterClockwiseMid = normalizedAngle(midAngle - startAngle)
            sweep = counterClockwiseMid <= counterClockwiseSweep
                ? counterClockwiseSweep
                : counterClockwiseSweep - (2.0 * .pi)
        }

        let segmentCount = max(
            2,
            Int(ceil(abs(sweep) / (.pi / 2.0) * Double(segmentsPerQuadrant))))

        var result: [Coordinate3D] = []
        result.reserveCapacity(segmentCount + 1)

        for index in 0 ... segmentCount {
            let fraction = Double(index) / Double(segmentCount)
            let angle = startAngle + (sweep * fraction)

            result.append(
                Coordinate3D(
                    x: centerX + (radius * cos(angle)),
                    y: centerY + (radius * sin(angle)),
                    z: interpolate(start.z, end.z, fraction),
                    m: interpolate(start.m, end.m, fraction),
                    projection: start.projection))
        }

        // Avoid trigonometric drift at the endpoints.
        result[0] = start
        result[result.count - 1] = end

        return result
    }

    /// Normalizes an angle to `0 ..< 2π`.
    private static func normalizedAngle(_ angle: Double) -> Double {
        var result = angle.truncatingRemainder(dividingBy: 2.0 * .pi)
        if result < 0 {
            result += 2.0 * .pi
        }
        return result
    }

    /// Linearly interpolates an optional value.
    private static func interpolate(_ start: Double?, _ end: Double?, _ fraction: Double) -> Double? {
        if let start, let end {
            return start + ((end - start) * fraction)
        }
        return start ?? end
    }

}
