import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-bezier-spline

extension LineString {

    /// Creates a smoothed cubic Bezier spline through the control points
    /// of the receiver.
    ///
    /// - Parameter steps: Number of interpolated points between each pair of
    ///   control points (default `25`).
    /// - Parameter gridSize: Snap coordinates to a grid of the given size
    ///   before computing (default `nil`).
    /// - Returns: A smoothed ``LineString``, or `nil` if there are fewer
    ///   than 2 coordinates.
    public func bezierSpline(steps: Int = 25, gridSize: Double? = nil) -> LineString? {
        guard coordinates.count >= 2 else { return nil }

        let pts: [Coordinate3D]
        if let gridSize {
            pts = coordinates.map { $0.snappedToGrid(tolerance: gridSize) }
        } else {
            pts = Array(coordinates)
        }
        guard pts.count >= 2 else { return nil }

        return BezierSpline.compute(points: pts, steps: steps)
    }

}

// MARK: - MultiLineString

extension MultiLineString {

    /// Creates a smoothed cubic Bezier spline through all control points
    /// of all constituent line strings, concatenated.
    ///
    /// - Parameter steps: Number of interpolated points between each pair of
    ///   control points (default `25`).
    /// - Parameter gridSize: Snap coordinates to a grid of the given size
    ///   before computing (default `nil`).
    /// - Returns: A smoothed ``LineString``, or `nil` if the total number of
    ///   coordinates is fewer than 2.
    public func bezierSpline(steps: Int = 25, gridSize: Double? = nil) -> LineString? {
        let allCoords = lineStrings.flatMap(\.coordinates)
        guard allCoords.count >= 2 else { return nil }

        let line = LineString(unchecked: allCoords)
        return line.bezierSpline(steps: steps, gridSize: gridSize)
    }

}

// MARK: - Implementation

private enum BezierSpline {

    static func compute(points: [Coordinate3D], steps: Int) -> LineString {
        let n = points.count
        guard n > 1 else {
            return LineString(unchecked: points)
        }

        let projection = points.first?.projection ?? .epsg4326

        // Chord lengths
        var chordLengths: [Double] = [0.0]
        for i in 1..<n {
            chordLengths.append(chordLengths[i - 1] + distance(points[i - 1], points[i]))
        }

        let totalLength = chordLengths[n - 1]
        guard totalLength > 0 else { return LineString(unchecked: points) }

        // Tangents at each control point
        var tangents: [(Double, Double)] = []
        tangents.reserveCapacity(n)

        for i in 0..<n {
            let tangent: (Double, Double)
            if i == 0 {
                // Forward difference
                let dx = points[1].longitude - points[0].longitude
                let dy = points[1].latitude - points[0].latitude
                let len = sqrt(dx * dx + dy * dy)
                tangent = len > 0 ? (dx / len, dy / len) : (1.0, 0.0)
            }
            else if i == n - 1 {
                // Backward difference
                let dx = points[i].longitude - points[i - 1].longitude
                let dy = points[i].latitude - points[i - 1].latitude
                let len = sqrt(dx * dx + dy * dy)
                tangent = len > 0 ? (dx / len, dy / len) : (1.0, 0.0)
            }
            else {
                // Centered difference
                let dx = points[i + 1].longitude - points[i - 1].longitude
                let dy = points[i + 1].latitude - points[i - 1].latitude
                let len = sqrt(dx * dx + dy * dy)
                tangent = len > 0 ? (dx / len, dy / len) : (1.0, 0.0)
            }
            tangents.append(tangent)
        }

        // Build spline by interpolating each segment
        var splineCoords: [Coordinate3D] = [points[0]]

        for i in 0..<(n - 1) {
            let p0 = points[i]
            let p3 = points[i + 1]

            let segLen = chordLengths[i + 1] - chordLengths[i]
            let tension = segLen / 3.0

            let p1 = Coordinate3D(
                x: p0.longitude + tangents[i].0 * tension,
                y: p0.latitude + tangents[i].1 * tension,
                projection: projection)
            let p2 = Coordinate3D(
                x: p3.longitude - tangents[i + 1].0 * tension,
                y: p3.latitude - tangents[i + 1].1 * tension,
                projection: projection)

            for s in 1..<steps {
                let u = Double(s) / Double(steps)
                let u2 = u * u
                let u3 = u2 * u
                let b0 = 1.0 - 3.0 * u + 3.0 * u2 - u3
                let b1 = 3.0 * u - 6.0 * u2 + 3.0 * u3
                let b2 = 3.0 * u2 - 3.0 * u3
                let b3 = u3

                let x = b0 * p0.longitude + b1 * p1.longitude + b2 * p2.longitude + b3 * p3.longitude
                let y = b0 * p0.latitude + b1 * p1.latitude + b2 * p2.latitude + b3 * p3.latitude
                splineCoords.append(Coordinate3D(x: x, y: y, projection: projection))
            }
        }

        // Add the last control point
        splineCoords.append(points[n - 1])

        return LineString(unchecked: splineCoords)
    }

    private static func distance(_ a: Coordinate3D, _ b: Coordinate3D) -> Double {
        let dx = a.longitude - b.longitude
        let dy = a.latitude - b.latitude
        return sqrt(dx * dx + dy * dy)
    }

}
