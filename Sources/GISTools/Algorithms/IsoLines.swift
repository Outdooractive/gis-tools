import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-isolines

extension FeatureCollection {

    /// Generates contour lines (isolines) from a grid of points with z-values.
    ///
    /// The input must be a ``FeatureCollection`` of ``Point`` features arranged in a
    /// regular rectangular grid, each point having an altitude (z) value. The result
    /// is a ``FeatureCollection`` of ``MultiLineString`` features, one per break value.
    ///
    /// - Parameter breaks: The contour values to generate (e.g. `[0, 100, 200]`).
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: A ``FeatureCollection`` of ``MultiLineString`` features, or an empty
    ///   collection if the input is invalid.
    public func isolines(
        breaks: [Double],
        gridSize: Double? = nil
    ) -> FeatureCollection {
        guard features.count >= 4 else { return FeatureCollection() }

        let snapped = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self

        // Extract grid dimensions and z-values from point altitudes
        let pts: [(coordinate: Coordinate3D, z: Double)] = snapped.features.compactMap { f in
            guard let point = f.geometry as? Point,
                  let z = point.coordinate.z
            else { return nil }
            return (point.coordinate, z)
        }

        guard pts.count >= 4 else { return FeatureCollection() }

        guard let grid = IsoLines.buildGrid(points: pts) else { return FeatureCollection() }

        var result: [Feature] = []
        for breakValue in breaks.sorted() {
            if let multiLine = IsoLines.traceIsoline(grid: grid, breakValue: breakValue) {
                var feature = Feature(multiLine)
                feature.properties["break"] = breakValue
                result.append(feature)
            }
        }

        return FeatureCollection(result)
    }

}

// MARK: - Implementation

private enum IsoLines {

    struct Grid {
        let nrows: Int
        let ncols: Int
        let data: [[Double]]
        let lons: [[Double]]
        let lats: [[Double]]
    }

    static func buildGrid(points: [(coordinate: Coordinate3D, z: Double)]) -> Grid? {
        // Detect grid dimensions from unique latitudes/longitudes
        let lons = Array(Set(points.map { $0.coordinate.longitude })).sorted()
        let lats = Array(Set(points.map { $0.coordinate.latitude })).sorted()

        guard lons.count >= 2, lats.count >= 2 else { return nil }
        guard points.count == lons.count * lats.count else { return nil }

        // Build a lookup dictionary
        var lookup: [String: Double] = [:]
        for p in points {
            let key = "\(p.coordinate.longitude),\(p.coordinate.latitude)"
            lookup[key] = p.z
        }

        var data: [[Double]] = Array(repeating: Array(repeating: 0.0, count: lons.count), count: lats.count)
        var gridLons: [[Double]] = Array(repeating: Array(repeating: 0.0, count: lons.count), count: lats.count)
        var gridLats: [[Double]] = Array(repeating: Array(repeating: 0.0, count: lons.count), count: lats.count)

        for j in 0..<lats.count {
            for i in 0..<lons.count {
                let key = "\(lons[i]),\(lats[j])"
                guard let z = lookup[key] else { return nil }
                data[j][i] = z
                gridLons[j][i] = lons[i]
                gridLats[j][i] = lats[j]
            }
        }

        return Grid(
            nrows: lats.count,
            ncols: lons.count,
            data: data,
            lons: gridLons,
            lats: gridLats)
    }

    static func traceIsoline(grid: Grid, breakValue: Double) -> MultiLineString? {
        let nrows = grid.nrows - 1
        let ncols = grid.ncols - 1
        guard nrows >= 1, ncols >= 1 else { return nil }

        // Topological case table for marching squares
        // Each entry: array of edge pairs (e1, e2) or empty for no line
        // Edge numbering: 0=bottom, 1=right, 2=top, 3=left
        let cases: [[(Int, Int)]] = [
            [],          // 0000: no line
            [(3, 0)],    // 0001
            [(0, 1)],    // 0010
            [(3, 1)],    // 0011
            [(1, 2)],    // 0100
            [(3, 0), (1, 2)],  // 0101: saddle
            [(0, 2)],    // 0110
            [(3, 2)],    // 0111
            [(2, 3)],    // 1000
            [(2, 0)],    // 1001
            [(0, 3), (2, 1)],  // 1010: saddle
            [(2, 1)],    // 1011
            [(1, 3)],    // 1100
            [(1, 0)],    // 1101
            [(0, 3)],    // 1110
            [],          // 1111: no line
        ]

        // Collect all line segments
        var segments: [(start: Coordinate3D, end: Coordinate3D)] = []

        for j in 0..<nrows {
            for i in 0..<ncols {
                let bl = grid.data[j][i] >= breakValue ? 1 : 0       // bottom-left
                let br = grid.data[j][i + 1] >= breakValue ? 1 : 0    // bottom-right
                let tr = grid.data[j + 1][i + 1] >= breakValue ? 1 : 0 // top-right
                let tl = grid.data[j + 1][i] >= breakValue ? 1 : 0    // top-left

                let code = bl | (br << 1) | (tr << 2) | (tl << 3)

                for edgePair in cases[code] {
                    let p1 = edgeIntersection(
                        grid: grid,
                        row: j,
                        col: i,
                        edge: edgePair.0,
                        breakValue: breakValue)
                    let p2 = edgeIntersection(
                        grid: grid,
                        row: j,
                        col: i,
                        edge: edgePair.1,
                        breakValue: breakValue)
                    if let p1, let p2 {
                        segments.append((p1, p2))
                    }
                }
            }
        }

        guard segments.isNotEmpty else { return nil }

        // Connect segments into continuous linestrings
        let lines = connectSegments(segments)
        guard lines.isNotEmpty else { return nil }
        return MultiLineString(unchecked: lines)
    }

    // MARK: - Edge intersection

    /// Compute the intersection point on a cell edge for the given break value.
    /// Edge numbering: 0=bottom, 1=right, 2=top, 3=left
    private static func edgeIntersection(
        grid: Grid,
        row: Int,
        col: Int,
        edge: Int,
        breakValue: Double
    ) -> Coordinate3D? {
        let i = col
        let j = row

        switch edge {
        case 0: // bottom (left to right)
            let z1 = grid.data[j][i]
            let z2 = grid.data[j][i + 1]
            guard z1 != z2 else {
                return Coordinate3D(
                    latitude: grid.lats[j][i],
                    longitude: (grid.lons[j][i] + grid.lons[j][i + 1]) / 2.0)
            }
            let t = (breakValue - z1) / (z2 - z1)
            let lon = grid.lons[j][i] + t * (grid.lons[j][i + 1] - grid.lons[j][i])
            return Coordinate3D(
                latitude: grid.lats[j][i],
                longitude: lon)

        case 1: // right (bottom to top)
            let z1 = grid.data[j][i + 1]
            let z2 = grid.data[j + 1][i + 1]
            guard z1 != z2 else {
                return Coordinate3D(
                    latitude: (grid.lats[j][i + 1] + grid.lats[j + 1][i + 1]) / 2.0,
                    longitude: grid.lons[j][i + 1])
            }
            let t = (breakValue - z1) / (z2 - z1)
            let lat = grid.lats[j][i + 1] + t * (grid.lats[j + 1][i + 1] - grid.lats[j][i + 1])
            return Coordinate3D(
                latitude: lat,
                longitude: grid.lons[j][i + 1])

        case 2: // top (right to left)
            let z1 = grid.data[j + 1][i + 1]
            let z2 = grid.data[j + 1][i]
            guard z1 != z2 else {
                return Coordinate3D(
                    latitude: grid.lats[j + 1][i],
                    longitude: (grid.lons[j + 1][i] + grid.lons[j + 1][i + 1]) / 2.0)
            }
            let t = (breakValue - z1) / (z2 - z1)
            let lon = grid.lons[j + 1][i + 1] + t * (grid.lons[j + 1][i] - grid.lons[j + 1][i + 1])
            return Coordinate3D(
                latitude: grid.lats[j + 1][i],
                longitude: lon)

        case 3: // left (top to bottom)
            let z1 = grid.data[j + 1][i]
            let z2 = grid.data[j][i]
            guard z1 != z2 else {
                return Coordinate3D(
                    latitude: (grid.lats[j][i] + grid.lats[j + 1][i]) / 2.0,
                    longitude: grid.lons[j][i])
            }
            let t = (breakValue - z1) / (z2 - z1)
            let lat = grid.lats[j + 1][i] + t * (grid.lats[j][i] - grid.lats[j + 1][i])
            return Coordinate3D(
                latitude: lat,
                longitude: grid.lons[j][i])

        default:
            return nil
        }
    }

    // MARK: - Segment connection

    private static func connectSegments(
        _ segments: [(start: Coordinate3D, end: Coordinate3D)]
    ) -> [LineString] {
        var remaining = segments
        var lines: [LineString] = []

        while remaining.isNotEmpty {
            var coords: [Coordinate3D] = [remaining[0].start, remaining[0].end]
            remaining.removeFirst()

            var connected = true
            while connected {
                connected = false
                for i in 0..<remaining.count {
                    let seg = remaining[i]
                    if coords.last!.isCoincident(to: seg.start) {
                        coords.append(seg.end)
                        remaining.remove(at: i)
                        connected = true
                        break
                    }
                    else if coords.last!.isCoincident(to: seg.end) {
                        coords.append(seg.start)
                        remaining.remove(at: i)
                        connected = true
                        break
                    }
                    else if coords.first!.isCoincident(to: seg.start) {
                        coords.insert(seg.end, at: 0)
                        remaining.remove(at: i)
                        connected = true
                        break
                    }
                    else if coords.first!.isCoincident(to: seg.end) {
                        coords.insert(seg.start, at: 0)
                        remaining.remove(at: i)
                        connected = true
                        break
                    }
                }
            }

            if let line = LineString(unchecked: coords) as LineString? {
                lines.append(line)
            }
        }

        return lines
    }

}
