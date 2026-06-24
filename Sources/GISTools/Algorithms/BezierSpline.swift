import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-bezier-spline

extension LineString {

    /// Creates a smoothed cubic Bezier spline through the control points
    /// of the receiver.
    ///
    /// When all coordinates have an ``altitude`` value, the spline is computed
    /// as a 3-D curve interpolating longitude, latitude and altitude. Otherwise
    /// the spline is 2-D (longitude, latitude).
    ///
    /// - Parameter steps: Number of interpolated points between each pair of
    ///   control points (default `25`).
    /// - Parameter gridSize: Snap coordinates to a grid of the given size
    ///   before computing (default `nil`).
    /// - Returns: A smoothed ``LineString``, or `nil` if there are fewer
    ///   than 2 coordinates.
    public func bezierSpline(
        steps: Int = 25,
        gridSize: Double? = nil
    ) -> LineString? {
        guard coordinates.count >= 2 else { return nil }

        let pts: [Coordinate3D]
        if let gridSize {
            pts = coordinates.map { $0.snappedToGrid(tolerance: gridSize) }
        }
        else {
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
    /// When all coordinates have an ``altitude`` value, the spline is computed
    /// as a 3-D curve interpolating longitude, latitude and altitude. Otherwise
    /// the spline is 2-D (longitude, latitude).
    ///
    /// - Parameter steps: Number of interpolated points between each pair of
    ///   control points (default `25`).
    /// - Parameter gridSize: Snap coordinates to a grid of the given size
    ///   before computing (default `nil`).
    /// - Returns: A smoothed ``LineString``, or `nil` if the total number of
    ///   coordinates is fewer than 2.
    public func bezierSpline(
        steps: Int = 25,
        gridSize: Double? = nil
    ) -> LineString? {
        let allCoords = lineStrings.flatMap(\.coordinates)
        guard allCoords.count >= 2 else { return nil }

        let line = LineString(unchecked: allCoords)
        return line.bezierSpline(steps: steps, gridSize: gridSize)
    }

}

// MARK: - Implementation

private enum BezierSpline {

    static func compute(
        points: [Coordinate3D],
        steps: Int
    ) -> LineString {
        let n = points.count
        guard n > 1 else {
            return LineString(unchecked: points)
        }

        let projection = points.first?.projection ?? .epsg4326
        let hasAltitude = points.allSatisfy({ $0.altitude != nil })

        // Chord lengths
        var chordLengths: [Double] = [0.0]
        for i in 1..<n {
            chordLengths.append(
                chordLengths[i - 1]
                + (hasAltitude
                   ? distance3D(points[i - 1], points[i])
                   : distance2D(points[i - 1], points[i])))
        }

        let totalLength = chordLengths[n - 1]
        guard totalLength > 0 else { return LineString(unchecked: points) }

        // Tangents at each control point
        var tangents: [(dx: Double, dy: Double, dz: Double)] = []
        tangents.reserveCapacity(n)

        for i in 0..<n {
            let tangent: (dx: Double, dy: Double, dz: Double)
            if i == 0 {
                // Forward difference
                let dx = points[1].longitude - points[0].longitude
                let dy = points[1].latitude - points[0].latitude
                let dz = hasAltitude ? (points[1].altitude! - points[0].altitude!) : 0.0
                let len = sqrt(dx * dx + dy * dy + dz * dz)
                tangent = len > 0 ? (dx / len, dy / len, dz / len) : (1.0, 0.0, 0.0)
            }
            else if i == n - 1 {
                // Backward difference
                let dx = points[i].longitude - points[i - 1].longitude
                let dy = points[i].latitude - points[i - 1].latitude
                let dz = hasAltitude ? (points[i].altitude! - points[i - 1].altitude!) : 0.0
                let len = sqrt(dx * dx + dy * dy + dz * dz)
                tangent = len > 0 ? (dx / len, dy / len, dz / len) : (1.0, 0.0, 0.0)
            }
            else {
                // Centered difference
                let dx = points[i + 1].longitude - points[i - 1].longitude
                let dy = points[i + 1].latitude - points[i - 1].latitude
                let dz = hasAltitude ? (points[i + 1].altitude! - points[i - 1].altitude!) : 0.0
                let len = sqrt(dx * dx + dy * dy + dz * dz)
                tangent = len > 0 ? (dx / len, dy / len, dz / len) : (1.0, 0.0, 0.0)
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
                x: p0.longitude + tangents[i].dx * tension,
                y: p0.latitude + tangents[i].dy * tension,
                z: hasAltitude ? p0.altitude! + tangents[i].dz * tension : nil,
                projection: projection)
            let p2 = Coordinate3D(
                x: p3.longitude - tangents[i + 1].dx * tension,
                y: p3.latitude - tangents[i + 1].dy * tension,
                z: hasAltitude ? p3.altitude! - tangents[i + 1].dz * tension : nil,
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
                let z = hasAltitude
                    ? b0 * p0.altitude! + b1 * p1.altitude! + b2 * p2.altitude! + b3 * p3.altitude!
                    : nil
                splineCoords.append(Coordinate3D(x: x, y: y, z: z, projection: projection))
            }
        }

        // Add the last control point
        splineCoords.append(points[n - 1])

        if !hasAltitude {
            splineCoords = splineCoords.map {
                Coordinate3D(x: $0.longitude, y: $0.latitude, projection: $0.projection)
            }
        }

        return LineString(unchecked: splineCoords)
    }

    private static func distance2D(
        _ a: Coordinate3D,
        _ b: Coordinate3D
    ) -> Double {
        let dx = a.longitude - b.longitude
        let dy = a.latitude - b.latitude
        return sqrt(dx * dx + dy * dy)
    }

    private static func distance3D(
        _ a: Coordinate3D,
        _ b: Coordinate3D
    ) -> Double {
        let dx = a.longitude - b.longitude
        let dy = a.latitude - b.latitude
        let dz = a.altitude! - b.altitude!
        return sqrt(dx * dx + dy * dy + dz * dz)
    }

}
